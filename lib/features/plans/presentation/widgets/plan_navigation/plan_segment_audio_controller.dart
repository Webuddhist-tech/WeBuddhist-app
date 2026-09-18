import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/utils/audio_url.dart';
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
  });

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

  PlanAudioButtonState _buttonState = PlanAudioButtonState.play;
  PlanAudioButtonState get buttonState => _buttonState;

  bool get hasAudio => hasPlayableAudio(url);

  /// Incremented by [cancel] so any in-flight [_startAudio] can detect it has
  /// been superseded and abort before calling play().
  int _audioSessionId = 0;

  /// Guards against the position / completion handlers triggering
  /// [onSegmentComplete] more than once.
  bool _hasCompleted = false;

  bool _isDisposed = false;

  void _setButtonState(PlanAudioButtonState state) {
    if (_isDisposed || _buttonState == state) return;
    _buttonState = state;
    notifyListeners();
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
      _playerStateSub = null;
      _positionSub = null;

      await _player!.setUrl(url!);
      if (_isDisposed || sessionId != _audioSessionId) return;

      await _player!.seek(Duration(milliseconds: startMs ?? 0));
      if (_isDisposed || sessionId != _audioSessionId) return;

      _hasCompleted = false;

      // Subscribe *before* play so no events are missed.
      // skip(1) discards the BehaviorSubject's stale initial emit
      // (playing: false, ready) which would otherwise race with
      // the pause state set below and incorrectly reset the button.
      _playerStateSub = _player!.playerStateStream
          .skip(1)
          .listen(_onPlayerState);
      _positionSub = _player!.positionStream.listen(_onPosition);

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

    // The file reached its natural end — treat as segment completion. This is
    // the path for per-subtask audio where [endMs] is null. Checked *before*
    // the `playing` guard: just_audio keeps `playing == true` at end-of-track
    // (the flag tracks play/pause intent, not active output), so this branch
    // would be unreachable if gated behind `!state.playing`.
    if (ps == ProcessingState.completed) {
      _fireSegmentComplete();
      return;
    }

    if (state.playing) return;

    // Unexpected stop (e.g. network drop) — reset to idle so the user can
    // replay.
    _setButtonState(PlanAudioButtonState.play);
  }

  /// Position stream callback. Triggers segment completion once when the
  /// [endMs] boundary is reached. Only relevant when a window is defined.
  void _onPosition(Duration position) {
    if (_hasCompleted) return;
    final end = endMs;
    if (end == null) return;
    if (position.inMilliseconds >= end) {
      _fireSegmentComplete();
    }
  }

  void _fireSegmentComplete() {
    if (_hasCompleted) return;
    _hasCompleted = true;
    onSegmentComplete();
  }

  /// Tears down all audio resources synchronously. Safe to call from
  /// [dispose] or navigation handlers. Idempotent.
  ///
  /// Increments [_audioSessionId] so any in-flight [_startAudio] aborts before
  /// it can call play() on a session that has been cancelled.
  void cancel() {
    _audioSessionId++; // invalidate any in-flight _startAudio
    _hasCompleted = true; // prevent late-firing position callbacks
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub = null;
    _positionSub = null;
    _player?.stop(); // fire-and-forget; dispose() cleans up the player
  }

  @override
  void dispose() {
    _isDisposed = true;
    cancel();
    _player?.dispose();
    super.dispose();
  }
}
