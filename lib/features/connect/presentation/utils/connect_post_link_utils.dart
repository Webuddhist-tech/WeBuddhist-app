import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Link types the post API understands.
abstract final class ConnectPostLinkType {
  static const String youtube = 'YOUTUBE';
  static const String website = 'WEBSITE';
  static const String external = 'EXTERNAL';
}

abstract final class ConnectPostLinkUtils {
  static String? youtubeVideoId(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    final host = hostOf(trimmed);
    if (host == null) return null;
    if (host != 'youtu.be' &&
        host != 'youtube.com' &&
        !host.endsWith('.youtube.com') &&
        host != 'youtube-nocookie.com') {
      return null;
    }

    final id = YoutubePlayer.convertUrlToId(trimmed, trimWhitespaces: true);
    if (id != null && id.isNotEmpty) return id;

    // Shorts and live URLs are not covered by the player's matcher.
    final uri = Uri.tryParse(trimmed);
    final segments = uri?.pathSegments ?? const [];
    for (var i = 0; i < segments.length - 1; i++) {
      if (segments[i] == 'shorts' || segments[i] == 'live') {
        final candidate = segments[i + 1];
        if (candidate.length == 11) return candidate;
      }
    }
    return null;
  }

  static bool isYoutube(String url) => youtubeVideoId(url) != null;

  static String youtubeThumbnailUrl(String videoId) =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  /// Type stored on the API for a user-attached link.
  static String typeFor(String url) =>
      isYoutube(url)
          ? ConnectPostLinkType.youtube
          : ConnectPostLinkType.website;

  /// Host without a leading `www.`, e.g. "lionsroar.com".
  static String? hostOf(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) return null;
    final host = uri.host.toLowerCase();
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  /// "lionsroar.com/how-to-meditate" style form for a secondary line.
  static String shortUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) return url.trim();
    final host = hostOf(url) ?? uri.host;
    final path =
        uri.path.endsWith('/')
            ? uri.path.substring(0, uri.path.length - 1)
            : uri.path;
    return '$host$path';
  }

  /// Turns user input into an `https://` URL, or null when it cannot be one.
  static String? normalizeUserUrl(String input) {
    var value = input.trim();
    if (value.isEmpty) return null;
    if (value.contains(' ')) return null;

    final lower = value.toLowerCase();
    if (lower.startsWith('http://')) {
      value = 'https://${value.substring(7)}';
    } else if (!lower.startsWith('https://')) {
      if (value.contains('://')) return null;
      value = 'https://$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
      return null;
    }
    if (uri.host.endsWith('.')) return null;
    return uri.toString();
  }
}
