import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/timer/data/services/timer_live_activity.dart';
import 'package:flutter_pecha/features/timer/data/services/timer_session_notifier.dart';
import 'package:flutter_pecha/features/timer/domain/entities/ambient_sound.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/domain/usecases/stop_user_timer_usecase.dart';
import 'package:flutter_pecha/features/timer/presentation/providers/timers_providers.dart';
import 'package:flutter_pecha/features/timer/presentation/services/ambient_sound_player.dart';
import 'package:flutter_pecha/features/timer/presentation/services/timer_keep_alive.dart';
import 'package:flutter_pecha/features/timer/presentation/services/timer_sound_player.dart';
import 'package:flutter_pecha/features/timer/presentation/utils/timer_analytics.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/timer_progress_ring.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _TimerPhase { countdown, running, finished }

typedef TimerClock = DateTime Function();

class ActiveTimerScreen extends ConsumerStatefulWidget {
  const ActiveTimerScreen({
    super.key,
    required this.presetTimer,
    @visibleForTesting TimerBellPlayer? soundPlayer,
    @visibleForTesting TimerSessionNotifications? sessionNotifier,
    @visibleForTesting TimerLockScreenActivity? liveActivity,
    @visibleForTesting TimerKeepAlive? keepAlive,
    @visibleForTesting TimerClock? clock,
  }) : _soundPlayer = soundPlayer,
       _sessionNotifier = sessionNotifier,
       _liveActivity = liveActivity,
       _keepAlive = keepAlive,
       _clock = clock;

  final PresetTimer presetTimer;
  final TimerBellPlayer? _soundPlayer;
  final TimerSessionNotifications? _sessionNotifier;
  final TimerLockScreenActivity? _liveActivity;
  final TimerKeepAlive? _keepAlive;
  final TimerClock? _clock;

  @override
  ConsumerState<ActiveTimerScreen> createState() => _ActiveTimerScreenState();
}

class _ActiveTimerScreenState extends ConsumerState<ActiveTimerScreen>
    with WidgetsBindingObserver {
  static const _countdownStart = 5;
  static const _ringSize = 280.0;
  static const _controlsSpacing = 48.0;
  static const _controlsHeight = 56.0;
  static const _centerTextHeight = 48.0;
  static const _durationFontSize = 40.0;

  final _logger = AppLogger('ActiveTimerScreen');

  _TimerPhase _phase = _TimerPhase.countdown;
  int _countdownValue = _countdownStart;
  int _remainingMs = 0;
  bool _isPaused = false;

  /// Absolute wall-clock instant the running session ends — the single source
  /// of truth for how much time is left. The periodic timer below only decides
  /// *when* to repaint; it never decides how much time has passed, so a session
  /// stays correct across a suspended isolate (screen locked, app backgrounded).
  ///
  /// Null whenever there is no end time to count towards: before the session
  /// starts, while paused (where [_remainingMs] holds the frozen value), and
  /// once finished.
  DateTime? _endsAt;

  /// Same idea for the 5-second pre-roll.
  DateTime? _countdownEndsAt;

  /// Elapsed time of the last reported stop, so pausing and then finishing does
  /// not post the same session twice.
  int? _lastReportedMs;

  /// Carried on `timer_completed`.
  bool _wasBackgrounded = false;
  int _pauseCount = 0;

  Timer? _timer;
  late final TimerBellPlayer _soundPlayer;
  late final AmbientSoundPlayer _ambientPlayer;
  late final TimerSessionNotifications _notifier;
  late final TimerLockScreenActivity _liveActivity;

  /// Holds the app running while the session is in progress, so the bells below
  /// can be rung by the app itself rather than by the OS.
  late final TimerKeepAlive _keepAlive;

  /// The scheduled-notification bells, armed while backgrounded as a backstop
  /// for the app being suspended before it can ring the bell itself.
  final _startBell = _BellAlarm();
  final _completionBell = _BellAlarm();

  /// Serializes every schedule/cancel call so they reach the plugin in the
  /// order they were requested, whatever order their futures complete in.
  Future<void> _bellOperations = Future<void>.value();

  int get _totalMs => widget.presetTimer.durationMs;

  String get _presetId => widget.presetTimer.id;

  String? get _ambientSoundId {
    final id = widget.presetTimer.ambientSoundId;
    return (id == null || id.isEmpty) ? null : id;
  }

  int get _elapsedMs => _totalMs - _remainingFromClock();

  DateTime get _now => (widget._clock ?? DateTime.now)();

  /// Remaining time recomputed from the wall clock. Falls back to the stored
  /// value when there is no end time (paused or finished), which is exactly the
  /// value that was frozen there.
  int _remainingFromClock() {
    final endsAt = _endsAt;
    if (endsAt == null) return _remainingMs;
    return endsAt.difference(_now).inMilliseconds.clamp(0, _totalMs);
  }

  double get _elapsedProgress {
    if (_totalMs <= 0) return 1;
    if (_phase == _TimerPhase.countdown) return 0;
    return ((_totalMs - _remainingMs) / _totalMs).clamp(0.0, 1.0);
  }

  bool get _showFinish =>
      _phase == _TimerPhase.finished ||
      (_phase == _TimerPhase.running && _isPaused);

  bool get _showDiscard =>
      _phase == _TimerPhase.finished ||
      (_phase == _TimerPhase.running && _isPaused);

  @override
  void initState() {
    super.initState();
    _remainingMs = _totalMs;
    _soundPlayer = widget._soundPlayer ?? TimerSoundPlayer();
    _soundPlayer.init();
    _ambientPlayer = AmbientSoundPlayer();
    _notifier = widget._sessionNotifier ?? TimerSessionNotifier();
    _liveActivity = widget._liveActivity ?? TimerLiveActivity();
    _keepAlive = widget._keepAlive ?? TimerAudioKeepAlive();
    unawaited(_keepAlive.start());
    WidgetsBinding.instance.addObserver(this);
    _startCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _soundPlayer.dispose();
    unawaited(_keepAlive.dispose());
    unawaited(_ambientPlayer.dispose());
    _clearBackgroundSurfaces();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _onResumed();
        break;
      case AppLifecycleState.inactive:
        _onBackgrounded();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _wasBackgrounded = true;
        _onBackgrounded();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  /// About to lose the foreground: arm the notification bells as a backstop.
  ///
  /// The app normally rings the bell itself — [_keepAlive] holds iOS awake, and
  /// Android keeps ticking with the screen off — and disarms these a moment
  /// before it does (see [_reclaimBellIfDue]), so they only ring if the app was
  /// suspended before getting that far.
  ///
  /// `inactive` is included because screen lock passes through it before
  /// `paused`, and on some devices that is the last dependable moment to arm an
  /// alarm. During the pre-roll both instants are already known — the session
  /// starts at [_countdownEndsAt] and ends a full duration later — so both
  /// bells are armed up front.
  void _onBackgrounded() {
    switch (_phase) {
      case _TimerPhase.countdown:
        final startsAt = _countdownEndsAt;
        if (startsAt == null) return;
        _scheduleStartBell(startsAt);
        _scheduleCompletionBell(_sessionEndFor(startsAt));
        break;
      case _TimerPhase.running:
        final endsAt = _endsAt;
        if (_isPaused || endsAt == null) return;
        _scheduleCompletionBell(endsAt);
        break;
      case _TimerPhase.finished:
        break;
    }
  }

  /// Back in the foreground: take the bells back and resync to the wall clock,
  /// which is where the time that passed while suspended gets accounted for.
  void _onResumed() {
    switch (_phase) {
      case _TimerPhase.countdown:
        _resumeCountdown();
        break;
      case _TimerPhase.running:
        _resumeRunning();
        break;
      case _TimerPhase.finished:
        _cancelStartBell();
        _cancelCompletionBell();
        break;
    }
  }

  void _resumeCountdown() {
    final startsAt = _countdownEndsAt;
    if (startsAt == null || startsAt.isAfter(_now)) {
      _cancelStartBell();
      _cancelCompletionBell();
      if (startsAt != null) _onCountdownTick();
      return;
    }

    // The pre-roll ran out while suspended. Start the session from the moment
    // it was due, not from now, so the locked time counts. An exact OS alarm
    // has already rung the start bell; otherwise ring it here — unless the
    // whole session is over too, where the completion bell speaks for both.
    final startBellWasExact = _startBell.isExactFor(startsAt);
    _cancelStartBell();
    final sessionAlsoEnded = !_sessionEndFor(startsAt).isAfter(_now);
    _timer?.cancel();
    _startMainTimer(playBell: !startBellWasExact && !sessionAlsoEnded);
    _resumeRunning();
  }

  void _resumeRunning() {
    _cancelStartBell();

    final endsAt = _endsAt;
    if (_isPaused || endsAt == null) {
      _cancelCompletionBell();
      return;
    }

    final completionBellWasExact = _completionBell.isExactFor(endsAt);
    _cancelCompletionBell();

    if (!endsAt.isAfter(_now)) {
      // Exact OS alarms should already have rung at the deadline. Inexact alarms
      // may still be delayed, so keep the in-app fallback when resuming first.
      _completeSession(playBell: !completionBellWasExact);
      return;
    }

    setState(() => _remainingMs = _remainingFromClock());
  }

  DateTime _sessionEndFor(DateTime startsAt) =>
      startsAt.add(Duration(milliseconds: _totalMs));

  void _startCountdown() {
    _countdownEndsAt = _now.add(const Duration(seconds: _countdownStart));
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onCountdownTick(),
    );
  }

  void _onCountdownTick() {
    if (!mounted) return;

    final endsAt = _countdownEndsAt;
    if (endsAt == null) return;

    final remainingMs = endsAt.difference(_now).inMilliseconds;
    // Read before the handoff, which clears the exact-alarm record as it
    // cancels; past the deadline that record is what says the OS already rang.
    final wasExact = _startBell.isExactFor(endsAt);
    _reclaimBellIfDue(_startBell, remainingMs, _cancelStartBell);
    if (remainingMs <= 0) {
      _timer?.cancel();
      // If the alarm was still armed, this tick came too late to disarm it —
      // the OS is about to ring, or already has, so don't ring on top of it.
      _startMainTimer(playBell: !wasExact);
      return;
    }

    final value = (remainingMs / 1000).ceil();
    if (value != _countdownValue) {
      setState(() => _countdownValue = value);
    }
  }

  void _startMainTimer({required bool playBell}) {
    if (playBell) _soundPlayer.play();
    unawaited(_startAmbientSound());

    final endsAt = _sessionEndFor(_countdownEndsAt ?? _now);

    setState(() {
      _phase = _TimerPhase.running;
      _countdownEndsAt = null;
      _endsAt = endsAt;
      _remainingMs = _totalMs;
      _isPaused = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onMainTimerTick(),
    );

    unawaited(
      _liveActivity.start(
        sessionName: _sessionTitle,
        endsAt: endsAt,
        totalSeconds: (_totalMs / 1000).round(),
      ),
    );
    _showRunningNotification(endsAt);
    _armCompletionBellIfBackgrounded(endsAt);
    ref.read(timerAnalyticsProvider).timerStarted(
      presetId: _presetId,
      durationSeconds: _totalMs ~/ 1000,
    );
  }

  /// Fetches the sound catalogue for this session.
  ///
  /// The catalogue is refetched rather than read, because the screens below
  /// this one keep the auto-dispose provider alive to label their cards — its
  /// cached value can be old enough that the signed urls have expired. Falls
  /// back to whatever was already cached when the refetch fails (offline), so
  /// this is never worse than reading the cached value.
  Future<List<AmbientSound>> _loadAmbientSounds() async {
    final cached = ref.read(ambientSoundsFutureProvider).valueOrNull;
    try {
      return await ref.refresh(ambientSoundsFutureProvider.future);
    } catch (e) {
      if (cached == null) rethrow;
      _logger.warning('Using cached ambient sound catalogue: $e');
      return cached;
    }
  }

  /// The ambient sound this session should play.
  ///
  /// A [PresetTimer] does not always arrive whole. Bookmarks and practice
  /// routines rebuild one from their own payload, which carries an id, a name
  /// and a duration but no `ambient_sound_id` — the bookmark API exposes only
  /// `ambient_sound_name`, which cannot be resolved to a playable track.
  /// Without this lookup those entry points run the user's timer in silence.
  ///
  /// The repository read is cache-first, so the usual case costs nothing, and
  /// a miss (unknown id, nothing cached, not the caller's timer) just keeps
  /// the silent behaviour.
  Future<String?> _resolveAmbientSoundId() async {
    final direct = _ambientSoundId;
    if (direct != null) return direct;

    final timerId = widget.presetTimer.id;
    if (timerId.isEmpty) return null;

    final result =
        await ref.read(timersDomainRepositoryProvider).getPresetTimers();
    return result.fold((_) => null, (timers) {
      for (final timer in timers) {
        if (timer.id != timerId) continue;
        final id = timer.ambientSoundId;
        return (id == null || id.isEmpty) ? null : id;
      }
      return null;
    });
  }

  /// Starts the looping ambient track the timer was created with, resolving
  /// its id against the sound catalogue. Best-effort: a missing or unplayable
  /// track leaves the session running in silence.
  ///
  /// Everything here is inside one guard on purpose — resolving the id reads
  /// the timers repository, which can throw outright rather than return a
  /// failure. Nothing about a background track may take the session down with
  /// it.
  Future<void> _startAmbientSound() async {
    try {
      final soundId = await _resolveAmbientSoundId();
      if (soundId == null || !mounted || _phase != _TimerPhase.running) return;

      // The sound catalogue auto-disposes and its urls are short-lived signed
      // links, so hold it open for as long as the session needs the track.
      ref.listenManual(ambientSoundsFutureProvider, (_, __) {});

      final sounds = await _loadAmbientSounds();
      // The catalogue can resolve after the session ended. A paused session
      // still loads the track — resuming only calls resume() on the player, so
      // bailing out here would leave the rest of the session silent.
      if (!mounted || _phase != _TimerPhase.running) return;

      for (final sound in sounds) {
        if (sound.id == soundId) {
          await _ambientPlayer.play(sound.url);
          // The session can end (or pause) while the track is loading, after
          // the stop/pause it issued has already run against nothing.
          if (!mounted || _phase != _TimerPhase.running) {
            await _ambientPlayer.stop();
          } else if (_isPaused) {
            await _ambientPlayer.pause();
          }
          return;
        }
      }
      _logger.warning('Ambient sound $soundId is not in the catalogue');
    } catch (e) {
      _logger.warning('Failed to start ambient sound: $e');
    }
  }

  void _onMainTimerTick() {
    if (!mounted || _isPaused || _phase != _TimerPhase.running) return;
    if (_endsAt == null) return;

    final remainingMs = _remainingFromClock();
    // Same ordering as the countdown tick: the handoff clears the exact-alarm
    // record, so a late tick has to read it first.
    final wasExact = _completionBell.isExactFor(_endsAt!);
    _reclaimBellIfDue(_completionBell, remainingMs, _cancelCompletionBell);
    if (remainingMs <= 0) {
      _completeSession(playBell: !wasExact);
      return;
    }

    setState(() => _remainingMs = remainingMs);
  }

  /// Ends the session at zero. [playBell] should be true whenever the user
  /// should hear the completion bell (foreground tick or resume after a
  /// background finish).
  void _completeSession({required bool playBell}) {
    _timer?.cancel();
    _timer = null;

    setState(() {
      _remainingMs = 0;
      _endsAt = null;
      _isPaused = false;
      _phase = _TimerPhase.finished;
    });

    if (playBell) {
      unawaited(_ringBellThenRelease());
    } else {
      unawaited(_keepAlive.stop());
    }
    unawaited(_ambientPlayer.stop());
    _clearBackgroundSurfaces();
    _reportTimerStop();
    ref.read(timerAnalyticsProvider).timerCompleted(
      presetId: _presetId,
      durationSeconds: _totalMs ~/ 1000,
      wasBackgrounded: _wasBackgrounded,
      pauseCount: _pauseCount,
    );
  }

  /// Rings the completion bell, holding the app awake until it has finished.
  ///
  /// [TimerSoundPlayer.play] only completes when playback does. Releasing the
  /// keep-alive before then tears down the audio session the bell is playing
  /// through, which on a locked iOS screen silences it — the session ends, so
  /// nothing else is holding the app awake. Bounded so a player that never
  /// completes cannot hold the session open for the rest of the day.
  static const _bellHoldLimit = Duration(seconds: 30);

  Future<void> _ringBellThenRelease() async {
    try {
      await _soundPlayer.play().timeout(_bellHoldLimit);
    } catch (e) {
      _logger.warning('Completion bell failed: $e');
    } finally {
      await _keepAlive.stop();
    }
  }

  void _togglePause() {
    if (_phase != _TimerPhase.running) return;

    final enteringPause = !_isPaused;

    setState(() {
      if (enteringPause) {
        // Freeze at the exact instant of the tap, not at the last repaint.
        _remainingMs = _remainingFromClock();
        _endsAt = null;
      } else {
        _endsAt = _now.add(Duration(milliseconds: _remainingMs));
      }
      _isPaused = enteringPause;
    });

    if (enteringPause) {
      _pauseCount++;
      unawaited(_ambientPlayer.pause());
      // Nothing left to ring while paused, so let the app be suspended again.
      unawaited(_keepAlive.stop());
      _cancelCompletionBell();
      _showPausedNotification();
      _reportTimerStop();
    } else {
      unawaited(_ambientPlayer.resume());
      unawaited(_keepAlive.start());
      _showRunningNotification(_endsAt!);
      _armCompletionBellIfBackgrounded(_endsAt!);
    }

    unawaited(
      _liveActivity.update(
        endsAt: _endsAt,
        isPaused: enteringPause,
        remainingSeconds: (_remainingMs / 1000).ceil(),
      ),
    );
  }

  void _finish() {
    _timer?.cancel();
    unawaited(_keepAlive.stop());
    unawaited(_ambientPlayer.stop());
    if (_phase == _TimerPhase.running) {
      _reportTimerStop();
      _trackDiscarded();
    }
    _clearBackgroundSurfaces();
    context.pop();
  }

  void _discardSession() {
    _timer?.cancel();
    unawaited(_keepAlive.stop());
    unawaited(_ambientPlayer.stop());
    if (_phase == _TimerPhase.running) _trackDiscarded();
    _clearBackgroundSurfaces();
    context.pop();
  }

  /// The session ended before the bell, by Finish or Discard.
  void _trackDiscarded() {
    final elapsedMs = _elapsedMs;
    ref.read(timerAnalyticsProvider).timerDiscarded(
      presetId: _presetId,
      elapsedSeconds: elapsedMs ~/ 1000,
      pctComplete:
          _totalMs <= 0 ? 100 : (elapsedMs * 100 ~/ _totalMs).clamp(0, 100),
    );
  }

  void _reportTimerStop() {
    final elapsedMs = _elapsedMs;

    // Pausing already reports the session; a Finish immediately after would
    // post the same elapsed time again and double-count it.
    if (_lastReportedMs == elapsedMs) return;
    _lastReportedMs = elapsedMs;

    final useCase = ref.read(stopUserTimerUseCaseProvider);
    useCase(
      StopUserTimerParams(
        timerId: widget.presetTimer.id,
        durationMs: elapsedMs,
      ),
    ).then((result) {
      result.fold(
        (failure) => _logger.warning('Failed to report timer stop: $failure'),
        (_) {},
      );
    });
  }

  // ── Lock-screen surfaces ───────────────────────────────────────────────────

  String get _sessionTitle => widget.presetTimer.name;

  void _showRunningNotification(DateTime endsAt) {
    if (!mounted) return;
    unawaited(
      _notifier.showRunning(
        endsAt: endsAt,
        title: _sessionTitle,
        body: context.l10n.timer_notification_in_progress,
      ),
    );
  }

  void _showPausedNotification() {
    if (!mounted) return;
    unawaited(
      _notifier.showPaused(
        title: _sessionTitle,
        body: context.l10n.timer_notification_paused(
          _formatDuration(_remainingMs, separator: ':'),
        ),
      ),
    );
  }

  bool get _isInForeground =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  /// How far ahead of a bell the app takes it back from the OS. A tick this
  /// close to the deadline proves the app is still executing (iOS suspends
  /// within a second or two of its audio session stopping), so it can ring the
  /// real bell itself and the scheduled notification is no longer wanted.
  static const _bellHandoffLead = Duration(seconds: 2);

  void _reclaimBellIfDue(
    _BellAlarm alarm,
    int remainingMs,
    void Function() cancel,
  ) {
    if (alarm.desiredAt == null) return;
    if (remainingMs > _bellHandoffLead.inMilliseconds) return;
    cancel();
  }

  /// Arms the OS completion bell when the app is not in the foreground.
  /// Skipped while resumed, where the in-app bell owns completion; also covers
  /// a session that starts while already backgrounded, which gets no further
  /// lifecycle event to arm the alarm.
  void _armCompletionBellIfBackgrounded(DateTime endsAt) {
    if (_isInForeground) return;
    _scheduleCompletionBell(endsAt);
  }

  void _scheduleStartBell(DateTime startsAt) {
    if (!mounted) return;
    final title = _sessionTitle;
    final body = context.l10n.timer_notification_in_progress;
    _scheduleBell(
      _startBell,
      startsAt,
      () =>
          _notifier.scheduleStart(startsAt: startsAt, title: title, body: body),
    );
  }

  void _scheduleCompletionBell(DateTime endsAt) {
    if (!mounted) return;
    final title = _sessionTitle;
    final body = context.l10n.timer_notification_complete;
    _scheduleBell(
      _completionBell,
      endsAt,
      () => _notifier.scheduleCompletion(
        endsAt: endsAt,
        title: title,
        body: body,
      ),
    );
  }

  void _scheduleBell(
    _BellAlarm alarm,
    DateTime at,
    Future<TimerBellScheduleResult> Function() schedule,
  ) {
    if (alarm.desiredAt == at) return;

    final generation = alarm.request(at);
    _enqueueBellOperation(() async {
      if (alarm.generation != generation) return;

      final result = await schedule();

      // A later schedule or cancel is queued behind this one and will settle
      // the alarm; recording this result would describe an alarm that is gone.
      if (alarm.generation != generation) return;

      switch (result) {
        case TimerBellScheduleResult.exact:
          alarm.exactAt = at;
          break;
        case TimerBellScheduleResult.inexact:
          break;
        case TimerBellScheduleResult.none:
          // Forget the request so the next lifecycle event retries it.
          alarm.desiredAt = null;
          break;
      }
    });
  }

  void _cancelStartBell() {
    _startBell.clear();
    _enqueueBellOperation(_notifier.cancelStart);
  }

  void _cancelCompletionBell() {
    _completionBell.clear();
    _enqueueBellOperation(_notifier.cancelCompletion);
  }

  void _enqueueBellOperation(Future<void> Function() operation) {
    _bellOperations = _bellOperations.then((_) => operation()).catchError((
      Object e,
    ) {
      _logger.warning('Timer bell operation failed: $e');
    });
    unawaited(_bellOperations);
  }

  void _clearBackgroundSurfaces() {
    // Queued rather than fired directly, so a schedule still in flight cannot
    // land after this and leave a bell armed for a finished session.
    _startBell.clear();
    _completionBell.clear();
    _enqueueBellOperation(_notifier.cancelAll);
    unawaited(_liveActivity.end());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final finishFontSize = textTheme.labelLarge?.fontSize ?? 16.0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TimerProgressRing(
                        size: _ringSize,
                        progress: _elapsedProgress,
                        child: _buildCenterContent(textColor),
                      ),
                      const SizedBox(height: _controlsSpacing),
                      SizedBox(
                        height: _controlsHeight,
                        child:
                            _phase == _TimerPhase.running
                                ? IconButton(
                                  onPressed: _togglePause,
                                  iconSize: 40,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: _controlsHeight,
                                    minHeight: _controlsHeight,
                                  ),
                                  icon: Icon(
                                    _isPaused
                                        ? AppAssets.play
                                        : AppAssets.pause,
                                    color: textColor,
                                  ),
                                )
                                : null,
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: _phase != _TimerPhase.countdown,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IgnorePointer(
                        ignoring: !_showFinish,
                        child: Opacity(
                          opacity: _showFinish ? 1 : 0,
                          child: Center(
                            child: OutlinedButton(
                              onPressed: _finish,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                side: BorderSide(color: textColor),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 46,
                                  vertical: 16,
                                ),
                                shape: const StadiumBorder(),
                                backgroundColor:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.surfaceDark
                                        : AppColors.surfaceWhite,
                              ),
                              child: Text(
                                l10n.timer_finish,
                                strutStyle: context.tibetanStrutStyle(
                                  finishFontSize,
                                ),
                                style: textTheme.labelLarge?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      IgnorePointer(
                        ignoring: !_showDiscard,
                        child: Opacity(
                          opacity: _showDiscard ? 1 : 0,
                          child: TextButton(
                            onPressed: _discardSession,
                            style: TextButton.styleFrom(
                              foregroundColor: textColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              l10n.timer_discard_session,
                              strutStyle: context.tibetanStrutStyle(
                                finishFontSize,
                              ),
                              style: textTheme.labelLarge?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterContent(Color textColor) {
    final textTheme = Theme.of(context).textTheme;
    final text =
        _phase == _TimerPhase.countdown
            ? '$_countdownValue'
            : _formatDuration(_remainingMs);

    return SizedBox(
      height: _centerTextHeight,
      child: Center(
        child: Text(
          text,
          style: textTheme.displaySmall?.copyWith(
            fontSize: _durationFontSize,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: 1,
            color: textColor,
          ),
        ),
      ),
    );
  }

  String _formatDuration(int ms, {String separator = ' : '}) {
    final totalSeconds = (ms / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutesText = minutes.toString().padLeft(2, '0');
    final secondsText = seconds.toString().padLeft(2, '0');
    return '$minutesText$separator$secondsText';
  }
}

/// Bookkeeping for one OS-scheduled bell.
class _BellAlarm {
  /// The instant most recently requested, or null when none is wanted.
  DateTime? desiredAt;

  /// Set once the OS confirmed an exact alarm for [desiredAt] — the only case
  /// where the screen can trust the bell rang on time without it.
  DateTime? exactAt;

  /// Bumped by every request and clear, so an in-flight schedule can tell it
  /// has been superseded.
  int generation = 0;

  bool isExactFor(DateTime at) => exactAt == at;

  int request(DateTime at) {
    desiredAt = at;
    exactAt = null;
    return ++generation;
  }

  void clear() {
    desiredAt = null;
    exactAt = null;
    generation++;
  }
}
