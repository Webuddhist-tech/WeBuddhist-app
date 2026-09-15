import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/timer/data/services/timer_live_activity.dart';
import 'package:flutter_pecha/features/timer/data/services/timer_session_notifier.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/domain/usecases/stop_user_timer_usecase.dart';
import 'package:flutter_pecha/features/timer/presentation/providers/timers_providers.dart';
import 'package:flutter_pecha/features/timer/presentation/services/timer_sound_player.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/timer_progress_ring.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _TimerPhase { countdown, running, finished }

class ActiveTimerScreen extends ConsumerStatefulWidget {
  const ActiveTimerScreen({super.key, required this.presetTimer});

  final PresetTimer presetTimer;

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

  Timer? _timer;
  late final TimerSoundPlayer _soundPlayer;
  late final TimerSessionNotifier _notifier;
  late final TimerLiveActivity _liveActivity;
  DateTime? _scheduledCompletionEndsAt;

  int get _totalMs => widget.presetTimer.durationMs;

  int get _elapsedMs => _totalMs - _remainingFromClock();

  /// Remaining time recomputed from the wall clock. Falls back to the stored
  /// value when there is no end time (paused or finished), which is exactly the
  /// value that was frozen there.
  int _remainingFromClock() {
    final endsAt = _endsAt;
    if (endsAt == null) return _remainingMs;
    return endsAt
        .difference(DateTime.now())
        .inMilliseconds
        .clamp(0, _totalMs);
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
    _soundPlayer = TimerSoundPlayer();
    _soundPlayer.init();
    _notifier = TimerSessionNotifier();
    _liveActivity = TimerLiveActivity();
    WidgetsBinding.instance.addObserver(this);
    _startCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _soundPlayer.dispose();
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
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _onBackgrounded();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  /// About to lose reliable frame/timer callbacks: hand the bell over to a
  /// scheduled notification, so it rings on time even if this isolate is
  /// suspended. Screen lock may pass through `inactive` before `paused`, and on
  /// some devices that is the last dependable moment to arm the OS alarm.
  void _onBackgrounded() {
    if (_phase != _TimerPhase.running || _isPaused) return;
    final endsAt = _endsAt;
    if (endsAt == null) return;
    _scheduleCompletionBell(endsAt);
  }

  /// Back in the foreground: take the bell back and resync to the wall clock,
  /// which is where the time that passed while suspended gets accounted for.
  void _onResumed() {
    _cancelCompletionBell();

    if (_phase != _TimerPhase.running || _isPaused) return;
    final endsAt = _endsAt;
    if (endsAt == null) return;

    if (!endsAt.isAfter(DateTime.now())) {
      // Ran out while suspended. The OS notification may have rung, but it can
      // also arrive silently (muted channel, Focus, Doze). Play the in-app bell
      // as a fallback — a rare double-ring beats no bell at all.
      _completeSession(playBell: true);
      return;
    }

    setState(() => _remainingMs = _remainingFromClock());
  }

  void _startCountdown() {
    _countdownEndsAt = DateTime.now().add(
      const Duration(seconds: _countdownStart),
    );
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

    final remainingMs = endsAt.difference(DateTime.now()).inMilliseconds;
    if (remainingMs <= 0) {
      _timer?.cancel();
      _startMainTimer();
      return;
    }

    final value = (remainingMs / 1000).ceil();
    if (value != _countdownValue) {
      setState(() => _countdownValue = value);
    }
  }

  void _startMainTimer() {
    _soundPlayer.play();

    final endsAt = DateTime.now().add(Duration(milliseconds: _totalMs));

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
  }

  void _onMainTimerTick() {
    if (!mounted || _isPaused || _phase != _TimerPhase.running) return;
    if (_endsAt == null) return;

    final remainingMs = _remainingFromClock();
    if (remainingMs <= 0) {
      _completeSession(playBell: true);
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

    if (playBell) _soundPlayer.play();
    _clearBackgroundSurfaces();
    _reportTimerStop();
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
        _endsAt = DateTime.now().add(Duration(milliseconds: _remainingMs));
      }
      _isPaused = enteringPause;
    });

    if (enteringPause) {
      _cancelCompletionBell();
      _showPausedNotification();
      _reportTimerStop();
    } else {
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
    if (_phase == _TimerPhase.running) {
      _reportTimerStop();
    }
    _clearBackgroundSurfaces();
    context.pop();
  }

  void _discardSession() {
    _timer?.cancel();
    _clearBackgroundSurfaces();
    context.pop();
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

  /// Schedules the OS completion bell when the app is not in the foreground.
  /// Skipped while resumed so the in-app bell owns completion and we avoid a
  /// double-ring; also covers the case where the main timer starts while the
  /// app is already backgrounded (no second lifecycle event to arm the alarm).
  void _armCompletionBellIfBackgrounded(DateTime endsAt) {
    if (_isInForeground) return;
    _scheduleCompletionBell(endsAt);
  }

  void _scheduleCompletionBell(DateTime endsAt) {
    if (!mounted) return;
    if (_scheduledCompletionEndsAt == endsAt) return;

    _scheduledCompletionEndsAt = endsAt;
    unawaited(
      _notifier.scheduleCompletion(
            endsAt: endsAt,
            title: _sessionTitle,
            body: context.l10n.timer_notification_complete,
          )
          .then((_) {
            if (_scheduledCompletionEndsAt != endsAt) {
              unawaited(_notifier.cancelCompletion());
            }
          }),
    );
  }

  void _cancelCompletionBell() {
    _scheduledCompletionEndsAt = null;
    unawaited(_notifier.cancelCompletion());
  }

  void _clearBackgroundSurfaces() {
    _scheduledCompletionEndsAt = null;
    unawaited(_notifier.cancelAll());
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
