import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
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

  /// Whether a session currently wants to be kept alive. Guards the async gaps
  /// below: [stop] can land while [start] is still setting the session up.
  bool _wanted = false;
  bool _disposed = false;

  static bool get _isSupported => Platform.isIOS;

  @override
  Future<void> start() async {
    if (!_isSupported || _disposed || _wanted) return;
    _wanted = true;

    try {
      final session = await AudioSession.instance;
      await session.configure(_sessionConfiguration);
      await session.setActive(true);
      _interruptions ??= session.interruptionEventStream.listen(
        _onInterruption,
      );

      final player = _player ??= AudioPlayer();
      await player.setAsset(AppAssets.silence);
      await player.setLoopMode(LoopMode.one);
      if (!_wanted) return;
      // Never awaited: with a loop, `play()` only completes when playback
      // stops, which for the keep-alive means at the end of the session.
      unawaited(player.play());
      _logger.info('Holding audio session for the timer session');
    } catch (e) {
      _logger.warning('Could not hold the audio session: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (!_wanted) return;
    _wanted = false;

    try {
      await _player?.stop();
      final session = await AudioSession.instance;
      // Leave the app's usual configuration behind rather than the timer's, so
      // audio played elsewhere (plans, chants) is unaffected. Not re-activated:
      // configuring alone does not interrupt anyone else's playback.
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      _logger.warning('Failed to release the audio session: $e');
    }
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
    if (!_wanted) return;
    unawaited(_resumeAfterInterruption());
  }

  Future<void> _resumeAfterInterruption() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
      if (!_wanted) return;
      unawaited(_player?.play());
      _logger.info('Audio session resumed after interruption');
    } catch (e) {
      _logger.warning('Failed to resume after interruption: $e');
    }
  }

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
    await stop();
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
