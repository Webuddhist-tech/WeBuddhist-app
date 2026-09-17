import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:just_audio/just_audio.dart';

/// Plays short previews of ambient sound tracks from the "Ambient sounds"
/// picker sheet. One track plays at a time — starting a new preview stops
/// whatever was previously playing.
///
/// Volume here is local-only UI state for the preview; it is never sent to
/// the backend (the create-timer API has no volume field).
class AmbientSoundPreviewPlayer {
  AmbientSoundPreviewPlayer() : _logger = AppLogger('AmbientSoundPreviewPlayer');

  final AppLogger _logger;
  AudioPlayer? _player;
  bool _disposed = false;

  Future<void> play(String url, {double volume = 1}) async {
    if (_disposed || url.isEmpty) return;
    await stop();
    if (_disposed) return;

    final player = AudioPlayer();
    _player = player;
    try {
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(volume.clamp(0.0, 1.0));
      await player.setUrl(url);
      if (_disposed || _player != player) {
        await player.dispose();
        return;
      }
      await player.play();
    } catch (e) {
      _logger.warning('Failed to play ambient sound preview: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player?.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  Future<void> stop() async {
    final player = _player;
    _player = null;
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _disposed = true;
    await stop();
  }
}
