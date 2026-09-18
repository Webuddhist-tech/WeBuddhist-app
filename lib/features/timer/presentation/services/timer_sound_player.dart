import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:just_audio/just_audio.dart';

abstract class TimerBellPlayer {
  Future<void> init();
  Future<void> play();
  Future<void> dispose();
}

/// Plays the meditation bell for the timer's start and completion.
///
/// Hardened against the "sometimes no sound" reports, especially when the timer
/// is opened from a notification on a cold start:
///  - [play] awaits the asset load first, so the bell is never skipped just
///    because decoding hadn't finished when the countdown ended.
///  - a failed playback (e.g. an ExoPlayer pipeline error on the very first
///    play after process start) recreates the player and retries once.
///  - a failed load is cleared so a later [play] can retry instead of staying
///    permanently silent.
class TimerSoundPlayer implements TimerBellPlayer {
  TimerSoundPlayer() : _logger = AppLogger('TimerSoundPlayer');

  final AppLogger _logger;
  AudioPlayer? _player;
  Future<void>? _loadFuture;
  bool _disposed = false;

  /// Begins loading the bell asset. Idempotent — repeated calls share the same
  /// in-flight load, and a failed load is cleared so the next [play] retries.
  @override
  Future<void> init() => _loadFuture ??= _load();

  Future<void> _load() async {
    try {
      final player = AudioPlayer();
      await player.setAsset(AppAssets.meditationSound);
      if (_disposed) {
        await player.dispose();
        return;
      }
      _player = player;
    } catch (e) {
      _logger.warning('Failed to load timer sound: $e');
      // Clear so a later play() can retry the load rather than staying silent.
      _loadFuture = null;
    }
  }

  /// Plays the bell from the start. Waits for loading to finish, and retries
  /// once with a fresh player if the first playback throws.
  @override
  Future<void> play() async {
    for (var attempt = 1; attempt <= 2; attempt++) {
      if (_disposed) return;
      if (attempt == 2) await _recreate();
      if (await _tryPlay()) return;
    }
  }

  Future<bool> _tryPlay() async {
    try {
      await init();
      final player = _player;
      if (_disposed || player == null) return false;
      await player.seek(Duration.zero);
      await player.play();
      return true;
    } catch (e) {
      _logger.warning('Timer sound play attempt failed: $e');
      return false;
    }
  }

  /// Disposes the current player and reloads the asset — clears a pipeline that
  /// errored on a cold-start play so the retry starts from a clean player.
  Future<void> _recreate() async {
    final old = _player;
    _player = null;
    _loadFuture = null;
    try {
      await old?.dispose();
    } catch (_) {}
    await init();
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    final player = _player;
    _player = null;
    _loadFuture = null;
    await player?.dispose();
  }
}
