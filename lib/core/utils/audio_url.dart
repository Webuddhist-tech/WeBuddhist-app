/// Audio URL helpers: the API sends `""` for "no audio", so a blank or
/// whitespace-only URL must be treated as absent, never as a playable track.
library;

/// True when [url] points at a track that can actually be played.
bool hasPlayableAudio(String? url) => url != null && url.trim().isNotEmpty;

/// Trimmed [url], or null when blank, so it never overrides a fallback track.
String? normalizeAudioUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  return trimmed.isEmpty ? null : trimmed;
}
