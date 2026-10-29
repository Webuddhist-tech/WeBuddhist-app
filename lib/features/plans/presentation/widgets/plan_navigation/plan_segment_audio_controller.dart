import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/utils/audio_url.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_audio_progress.dart';
import 'package:just_audio/just_audio.dart';

/// Visual state of the play/pause button driven by [PlanSegmentAudioController].
enum PlanAudioButtonState { play, loading, pause }

/// Reusable audio engine for plan subtask playback, shared by `PlanTextScreen`
/// (inline TEXT/IMAGE) and `ReaderScreen` (SOURCE_REFERENCE).
///
/// Plays a single segment of a resolved audio file:
/// - [url] is already resolved with precedence (subtask audio over day audio).
/// - [startMs] seeks the entry point (defaults to 0).
/// - [endMs] is the optional segment boundary. When null, playback runs to the
///   file's natural end — the common case for per-subtask audio files.
///
/// When the segment finishes (either the [endMs] boundary is crossed or the
/// player reports [ProcessingState.completed]), [onSegmentComplete] fires
/// exactly once. Owners typically use it to mark the subtask complete and
/// auto-advance to the next task.
///
/// Repeat keeps this slice playing instead. The pass seeks back to [startMs]
/// (a whole file loops natively) and [onSegmentComplete] waits until repeat
/// is turned off. The choice is remembered for the session, like speed.
///
/// Lifecycle: owned by a widget `State` — create in `initState`, call
/// [cancel] on any manual navigation / back press, and [dispose] in the
/// state's `dispose`. It is intentionally **not** a Riverpod provider because
/// the cancel-on-navigation behaviour is bound to the screen lifecycle.
class PlanSegmentAudioController extends ChangeNotifier {
  PlanSegmentAudioController({
    required this.url,
    required this.startMs,
    required this.endMs,
    required this.onSegmentComplete,
  }) : progress = ValueNotifier(
         describePlanAudioProgress(
           position: Duration.zero,
           startMs: startMs,
           endMs: endMs,
         ),
       );

  /// Speed chosen from the picker. Kept for the rest of the app session so
  /// the next plan task or recording starts at the same speed.
  static double preferredSpeed = 1.0;

  /// Repeat chosen from the player bar. Kept for the session, same as speed.
  /// Off plays the slice once. On loops it until the listener turns it off.
  static bool preferredRepeat = false;

  /// Resolved audio URL (subtask audio takes precedence over day audio).
  /// Null when this item has no playable audio.
  final String? url;
  final int? startMs;
  final int? endMs;

  /// Fired once when the segment finishes playing.
  final VoidCallback onSegmentComplete;

  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  Duration? _fileDuration;

  /// Elapsed time within this task's slice. Updated on its own so the play
  /// button does not rebuild on every tick.
  final ValueNotifier<PlanAudioProgress> progress;

  PlanAudioButtonState _buttonState = PlanAudioButtonState.play;
  PlanAudioButtonState get buttonState => _buttonState;

  double get speed => preferredSpeed;

  bool get repeat => preferredRepeat;

  bool get hasAudio => hasPlayableAudio(url);

  /// True when the slice is the whole file, so the player can loop it itself.
  bool get _loopsEntireFile => (startMs ?? 0) == 0 && endMs == null;

  /// Incremented by [cancel] so any in-flight [_startAudio] can detect it has
  /// been superseded and abort before calling play().
  int _audioSessionId = 0;

  /// Guards against the position / completion handlers triggering
  /// [onSegmentComplete] more than once.
  bool _hasCompleted = false;

  /// True while a repeat seek is in flight, so a stale end-of-slice position
  /// cannot start a second restart or look like an unexpected stop.
  bool _loopRestarting = false;

  /// End-of-slice positions still queued from before a repeat seek. Cleared
  /// as soon as playback is heard back inside the slice.
  int _staleEndSkips = 0;

  bool _isDisposed = false;

  /// True after [dispose]. Listeners use it to skip detaching from a player
  /// that has already gone away.
  bool get isDisposed => _isDisposed;

  void _setButtonState(PlanAudioButtonState state) {
    if (_isDisposed || _buttonState == state) return;
    _buttonState = state;
    notifyListeners();
  }

  /// Applies [speed] to the current player, and to the next one in this session.
  Future<void> setSpeed(double speed) async {
    preferredSpeed = speed;
    await _player?.setSpeed(speed);
    if (!_isDisposed) notifyListeners();
  }

  /// Loops the current slice, and the next task or recording in this session.
  ///
  /// A whole file uses the player's own loop. A window from [startMs] to
  /// [endMs] seeks back to the start when the boundary is crossed, so the
  /// audio after [endMs] never plays.
  Future<void> setRepeat(bool repeat) async {
    if (preferredRepeat == repeat) return;
    preferredRepeat = repeat;
    if (_isDisposed) return;
    notifyListeners();
    await _applyLoopMode();
  }

  Future<void> _applyLoopMode() async {
    final player = _player;
    if (player == null || !_loopsEntireFile) return;
    try {
      await player.setLoopMode(preferredRepeat ? LoopMode.one : LoopMode.off);
    } catch (_) {}
  }

  void _publishProgress(Duration rawPosition) {
    if (_isDisposed) return;
    final next = describePlanAudioProgress(
      position: rawPosition,
      fileDuration: _fileDuration,
      startMs: startMs,
      endMs: endMs,
    );
    final current = progress.value;
    final sameSecond =
        current.position.inMilliseconds ~/ 200 ==
        next.position.inMilliseconds ~/ 200;
    if (sameSecond && current.duration == next.duration) return;
    progress.value = next;
  }

  /// Begin playback if this item has audio. Safe to call once after build.
  Future<void> maybeAutoPlay() async {
    if (!hasAudio) return;
    await _startAudio();
  }

  /// Toggle play/pause from a user tap.
  Future<void> toggle() async {
    if (!hasAudio) return;
    switch (_buttonState) {
      case PlanAudioButtonState.loading:
        return; // ignore taps while loading

      case PlanAudioButtonState.pause:
        await _player?.pause();
        _setButtonState(PlanAudioButtonState.play);

      case PlanAudioButtonState.play:
        if (_player == null) {
          await _startAudio();
          return;
        }
        final ps = _player!.processingState;
        if (ps == ProcessingState.idle || ps == ProcessingState.completed) {
          // Full restart — URL/seek needed again.
          await _startAudio();
          return;
        }
        // Resume within the current segment.
        _hasCompleted = false;
        _positionSub?.cancel();
        _positionSub = _player!.positionStream.listen(_onPosition);
        _player!.play(); // fire-and-forget
        _setButtonState(PlanAudioButtonState.pause);
    }
  }

  /// Load [url], seek to [startMs], and begin playback.
  ///
  /// **Never awaits [play()]** — in just_audio, [play()] only completes when
  /// playback *stops*; awaiting it would block for the full duration.
  ///
  /// **Session guard**: captures [_audioSessionId] at entry. If [cancel] is
  /// called while this method is suspended on an `await`, it increments the
  /// session id and the guard aborts before subscribing or calling play —
  /// preventing phantom audio during the page-exit animation.
  Future<void> _startAudio() async {
    if (!hasAudio || _buttonState == PlanAudioButtonState.loading) return;

    final sessionId = ++_audioSessionId;
    _setButtonState(PlanAudioButtonState.loading);

    try {
      _player ??= AudioPlayer();

      // Tear down stale subscriptions before rebinding.
      _playerStateSub?.cancel();
      _positionSub?.cancel();
      _durationSub?.cancel();
      _playerStateSub = null;
      _positionSub = null;
      _durationSub = null;

      await _player!.setUrl(url!);
      if (_isDisposed || sessionId != _audioSessionId) return;

      await _player!.setSpeed(preferredSpeed);
      if (_isDisposed || sessionId != _audioSessionId) return;

      await _applyLoopMode();
      if (_isDisposed || sessionId != _audioSessionId) return;

      await _player!.seek(Duration(milliseconds: startMs ?? 0));
      if (_isDisposed || sessionId != _audioSessionId) return;

      _hasCompleted = false;
      _loopRestarting = false;
      _staleEndSkips = 0;

      // Subscribe *before* play so no events are missed.
      // skip(1) discards the BehaviorSubject's stale initial emit
      // (playing: false, ready) which would otherwise race with
      // the pause state set below and incorrectly reset the button.
      _playerStateSub = _player!.playerStateStream
          .skip(1)
          .listen(_onPlayerState);
      _positionSub = _player!.positionStream.listen(_onPosition);
      _durationSub = _player!.durationStream.listen((duration) {
        _fileDuration = duration;
        _publishProgress(_player?.position ?? Duration.zero);
      });

      // Fire-and-forget: play() completes only when playback stops.
      _player!.play();

      _setButtonState(PlanAudioButtonState.pause);
    } catch (_) {
      // Presigned URL expired, network failure, etc. — reset to idle.
      _setButtonState(PlanAudioButtonState.play);
    }
  }

  /// Handles player stops. A natural completion advances the segment; any
  /// other unexpected stop (network drop) resets the button to idle.
  ///
  /// The skip(1) on the subscription means the first BehaviorSubject emit
  /// (which is stale) never reaches this handler.
  void _onPlayerState(PlayerState state) {
    if (_isDisposed || _buttonState != PlanAudioButtonState.pause) return;
    final ps = state.processingState;
    if (ps == ProcessingState.loading || ps == ProcessingState.buffering) {
      return;
    }

    // The file reached its natural end. A whole-file repeat uses LoopMode.one,
    // which never emits this. A windowed slice, or a repeat that the player
    // could not loop itself, seeks back to the start instead of finishing.
    // Checked *before* the `playing` guard: just_audio keeps `playing == true`
    // at end-of-track (the flag tracks play/pause intent, not active output),
    // so this branch would be unreachable if gated behind `!state.playing`.
    if (ps == ProcessingState.completed) {
      if (preferredRepeat) {
        _restartForRepeat();
        return;
      }
      _fireSegmentComplete();
      return;
    }

    if (_loopRestarting) return;

    if (state.playing) return;

    // Unexpected stop (e.g. network drop) — reset to idle so the user can
    // replay.
    _setButtonState(PlanAudioButtonState.play);
  }

  /// Position stream callback. Triggers segment completion once when the
  /// [endMs] boundary is reached. Only relevant when a window is defined.
  /// Repeat seeks back to [startMs] and keeps the same task on screen.
  void _onPosition(Duration position) {
    _publishProgress(position);
    if (_hasCompleted || _loopRestarting) return;
    final end = endMs;
    if (end == null) return;

    if (position.inMilliseconds < end) {
      _staleEndSkips = 0;
    } else if (_staleEndSkips > 0) {
      _staleEndSkips--;
      return;
    }

    if (position.inMilliseconds >= end) {
      if (preferredRepeat) {
        _restartForRepeat();
        return;
      }
      _fireSegmentComplete();
    }
  }

  /// Seek to [startMs] and keep playing. The button stays on pause, and the
  /// segment does not complete, so a plan task does not auto-advance.
  void _restartForRepeat() {
    if (_loopRestarting || _isDisposed || _hasCompleted || !preferredRepeat) {
      return;
    }
    final player = _player;
    if (player == null) return;
    final sessionId = _audioSessionId;
    _loopRestarting = true;
    final start = startMs ?? 0;
    unawaited(() async {
      try {
        await player.seek(Duration(milliseconds: start));
        if (_isDisposed || _hasCompleted || sessionId != _audioSessionId) {
          return;
        }
        if (!preferredRepeat) {
          try {
            await player.pause();
          } catch (_) {}
          _fireSegmentComplete();
          return;
        }
        final landed = player.position.inMilliseconds;
        final end = endMs;
        final stillPastSlice =
            end != null ? landed >= end : landed > start + 1000;
        if (stillPastSlice) {
          _fireSegmentComplete();
          return;
        }
        // Completed players stay stopped until play() is requested again.
        // play() only finishes when playback stops, so it must not be awaited.
        if (player.processingState == ProcessingState.completed ||
            !player.playing) {
          player.play();
        }
        _staleEndSkips = 2;
        _setButtonState(PlanAudioButtonState.pause);
        _publishProgress(player.position);
      } catch (_) {
        if (!_isDisposed && !_hasCompleted && sessionId == _audioSessionId) {
          _fireSegmentComplete();
        }
      } finally {
        if (sessionId == _audioSessionId) _loopRestarting = false;
      }
    }());
  }

  void _fireSegmentComplete() {
    if (_hasCompleted) return;
    _hasCompleted = true;
    onSegmentComplete();
    // Idle again so a caller that does not navigate away can replay or resume.
    _setButtonState(PlanAudioButtonState.play);
  }

  /// Tears down all audio resources synchronously. Safe to call from
  /// [dispose] or navigation handlers. Idempotent.
  ///
  /// Increments [_audioSessionId] so any in-flight [_startAudio] aborts before
  /// it can call play() on a session that has been cancelled.
  void cancel() {
    _audioSessionId++; // invalidate any in-flight _startAudio
    _hasCompleted = true; // prevent late-firing position callbacks
    _loopRestarting = false;
    _staleEndSkips = 0;
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub = null;
    _positionSub = null;
    _durationSub = null;
    final player = _player;
    if (player != null) {
      // Fire-and-forget; dispose() waits for it before freeing the player.
      _pendingStop = player.stop().catchError((Object _) {});
    }
  }

  /// The last [cancel]'s stop, still switching the player's platform.
  Future<void>? _pendingStop;

  @override
  void dispose() {
    _isDisposed = true;
    cancel();
    progress.dispose();
    final player = _player;
    _player = null;
    if (player != null) {
      // just_audio 0.9.x throws "Cannot complete a future with itself" when
      // dispose() lands while stop() is still swapping platforms, so let the
      // stop finish first. The timeout keeps a stuck stop from leaking it.
      final stopped = (_pendingStop ?? Future<void>.value())
          .timeout(const Duration(seconds: 2), onTimeout: () {})
          .catchError((Object _) {});
      unawaited(stopped.whenComplete(() => player.dispose()));
    }
    super.dispose();
  }
}
