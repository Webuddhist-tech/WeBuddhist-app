import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:just_audio/just_audio.dart';

/// Keeps the app executing for the length of a meditation session, so the
/// timer can ring the real bell from [TimerSoundPlayer] at the start and at the
/// end even with the screen locked.
abstract class TimerKeepAlive {
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}

/// iOS implementation: holds a playing audio session.
///
/// iOS suspends an app a moment after its screen locks, which stops the Dart
/// isolate — the timer's periodic callback never reaches the bell, which is the
/// "silent when the screen is off" report. An app that declares the `audio`
/// background mode (see `ios/Runner/Info.plist`) is allowed to keep running as
/// long as it is *actually playing* audio, so the session holds a looping
/// silent track for its whole duration. Nothing is audible until the bell
/// itself plays, through the same active session.
///
/// The category is `playback` so the bell is heard with the ringer switch on
/// silent, with `mixWithOthers` so music or a podcast the user already has
/// playing is not interrupted.
///
/// Android is a no-op: its timers keep firing with the screen off, so there is
/// nothing to hold open, and holding a session would need a foreground service.
///
/// Best-effort throughout: a session that cannot be held must never break the
/// timer. The scheduled notification bells in `TimerSessionNotifier` are the
/// backstop for exactly that case.
class TimerAudioKeepAlive implements TimerKeepAlive {
  TimerAudioKeepAlive() : _logger = AppLogger('TimerAudioKeepAlive');

  final AppLogger _logger;

  AudioPlayer? _player;
  StreamSubscription<AudioInterruptionEvent>? _interruptions;

  /// Whether a session currently wants to be kept alive. Written the moment
  /// [start] or [stop] is called and re-read after every await below, so the
  /// last caller wins however the platform calls interleave.
  bool _wanted = false;

  /// Whether the silent track is currently playing, so a repeated [start] does
  /// not restart it.
  bool _holding = false;
  bool _disposed = false;

  /// Serializes hold and release, which the timer screen fires without
  /// awaiting: pausing and immediately resuming must not leave a release
  /// landing on top of the hold that replaced it.
  Future<void> _operations = Future<void>.value();

  @visibleForTesting
  bool get isSupported => Platform.isIOS;

  @override
  Future<void> start() {
    if (!isSupported || _disposed) return Future<void>.value();
    _wanted = true;
    return _enqueue(_hold);
  }

  @override
  Future<void> stop() {
    if (!isSupported) return Future<void>.value();
    _wanted = false;
    return _enqueue(_release);
  }

  Future<void> _hold() async {
    if (!_wanted || _disposed || _holding) return;

    try {
      await activateSession();
      if (!_wanted || _disposed) return;
      await startSilentLoop();
      _holding = true;
      _logger.info('Holding the audio session for the timer session');
    } catch (e) {
      _logger.warning('Could not hold the audio session: $e');
    }
  }

  Future<void> _release() async {
    // A start queued behind this release already asked for the session back.
    if (_wanted) return;

    try {
      await stopSilentLoop();
      _holding = false;
      // Re-read rather than trusting the check above: a start can land while
      // the platform call is in flight, and restoring the app's configuration
      // on top of the hold that replaced this release is what silences the
      // bell on a locked screen.
      if (_wanted) return;
      await restoreSession();
    } catch (e) {
      _logger.warning('Failed to release the audio session: $e');
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    _operations = _operations.then((_) => operation()).catchError((Object e) {
      _logger.warning('Keep-alive operation failed: $e');
    });
    return _operations;
  }

  /// A phone call, Siri or an alarm deactivates the session and pauses the
  /// keep-alive, after which iOS is free to suspend the app. Resume as soon as
  /// the interruption ends; if the app was suspended in the meantime, the
  /// scheduled notification has the bell covered.
  void _onInterruption(AudioInterruptionEvent event) {
    if (event.begin) {
      _logger.info('Audio session interrupted (${event.type})');
      return;
    }
    if (!_wanted || _disposed) return;
    // Through the same queue, so it cannot overtake a stop the user just made.
    _holding = false;
    unawaited(
      _enqueue(() async {
        await _hold();
        if (_holding) _logger.info('Audio session resumed after interruption');
      }),
    );
  }

  @protected
  @visibleForTesting
  Future<void> activateSession() async {
    final session = await AudioSession.instance;
    await session.configure(_sessionConfiguration);
    await session.setActive(true);
    _interruptions ??= session.interruptionEventStream.listen(_onInterruption);
  }

  /// Leaves the app's usual configuration behind rather than the timer's, so
  /// audio played elsewhere (plans, chants) is unaffected. Not re-activated:
  /// configuring alone does not interrupt anyone else's playback.
  @protected
  @visibleForTesting
  Future<void> restoreSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  @protected
  @visibleForTesting
  Future<void> startSilentLoop() async {
    final player = _player ??= AudioPlayer();
    await player.setAsset(AppAssets.silence);
    await player.setLoopMode(LoopMode.one);
    // Never awaited: with a loop, `play()` only completes when playback stops,
    // which for the keep-alive means at the end of the session.
    unawaited(player.play());
  }

  @protected
  @visibleForTesting
  Future<void> stopSilentLoop() => _player?.stop() ?? Future<void>.value();

  static AudioSessionConfiguration get _sessionConfiguration =>
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
      );

  @override
  Future<void> dispose() async {
    _disposed = true;
    _wanted = false;
    await _enqueue(_release);
    await _interruptions?.cancel();
    _interruptions = null;
    final player = _player;
    _player = null;
    try {
      await player?.dispose();
    } catch (e) {
      _logger.warning('Failed to dispose the keep-alive player: $e');
    }
  }
}
