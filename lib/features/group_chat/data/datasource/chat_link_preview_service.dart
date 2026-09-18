import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:html/parser.dart' as html_parser;

/// An Open Graph card for a URL posted in chat.
class ChatLinkPreview extends Equatable {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;

  const ChatLinkPreview({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
  });

  String get host => Uri.tryParse(url)?.host ?? '';

  /// A card with neither a title nor an image is not worth a row of screen.
  bool get isRenderable =>
      (title != null && title!.trim().isNotEmpty) || imageUrl != null;

  @override
  List<Object?> get props => [url, title, description, imageUrl];
}

/// Fetches and parses link previews client-side — the chat API has no
/// server-side unfurl.
///
/// Deliberately built on a **bare** [Dio], never `dioProvider`: the app client
/// attaches the API base URL and a Bearer token, and neither may be sent to a
/// third-party host.
class ChatLinkPreviewService {
  ChatLinkPreviewService({Dio? dio}) : _dio = dio ?? _bareClient();

  final Dio _dio;

  /// Enough for a `<head>`; anything past this is body copy we never read.
  static const int _maxBytes = 65536;

  static Dio _bareClient() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        followRedirects: true,
        maxRedirects: 3,
        responseType: ResponseType.plain,
        headers: {
          'Range': 'bytes=0-$_maxBytes',
          'Accept': 'text/html,application/xhtml+xml',
        },
        validateStatus: (status) => status != null && status < 400,
      ),
    );
  }

  /// Returns null for anything unfetchable or unparseable. Callers cache the
  /// null so a dead link is not retried for the rest of the session.
  Future<ChatLinkPreview?> fetch(String url) async {
    if (!isPreviewableUrl(url)) return null;
    try {
      // YouTube serves a generic "YouTube" title to non-browser clients, so
      // its keyless oEmbed endpoint is the only way to get the video title.
      if (isYoutubeUrl(url)) {
        final response = await _dio.get<String>(
          youtubeOembedUrl(url),
          options: Options(headers: {'Accept': 'application/json'}),
        );
        final body = response.data;
        if (body == null || body.isEmpty) return null;
        return parseYoutubeOembed(body, url: url);
      }

      final response = await _dio.get<String>(url);
      final body = response.data;
      if (body == null || body.isEmpty) return null;
      final capped =
          body.length > _maxBytes ? body.substring(0, _maxBytes) : body;
      final preview = parsePreview(capped, url: url);
      return preview != null && preview.isRenderable ? preview : null;
    } catch (_) {
      return null;
    }
  }

  static String youtubeOembedUrl(String url) =>
      Uri.https('www.youtube.com', '/oembed', {
        'url': url.trim(),
        'format': 'json',
      }).toString();

  /// Parses the oEmbed JSON; the channel name lands in [description].
  static ChatLinkPreview? parseYoutubeOembed(
    String body, {
    required String url,
  }) {
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return null;
      final preview = ChatLinkPreview(
        url: url,
        title: _nullIfEmpty(json['title'] as String?),
        description: _nullIfEmpty(json['author_name'] as String?),
        imageUrl: _absoluteImageUrl(
          json['thumbnail_url'] as String?,
          pageUrl: url,
        ),
      );
      return preview.isRenderable ? preview : null;
    } catch (_) {
      return null;
    }
  }

  static bool isYoutubeUrl(String url) {
    final host = Uri.tryParse(url.trim())?.host.toLowerCase();
    if (host == null) return false;
    return host == 'youtu.be' ||
        host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtube-nocookie.com';
  }

  /// Parses `og:` tags with a `<title>` fallback. Pure, so the parser is
  /// testable without a socket.
  static ChatLinkPreview? parsePreview(String body, {required String url}) {
    try {
      final document = html_parser.parse(body);

      String? meta(String property) {
        for (final selector in [
          'meta[property="$property"]',
          'meta[name="$property"]',
        ]) {
          final content =
              document.querySelector(selector)?.attributes['content']?.trim();
          if (content != null && content.isNotEmpty) return content;
        }
        return null;
      }

      final title =
          meta('og:title') ??
          meta('twitter:title') ??
          document.querySelector('title')?.text.trim();
      final description = meta('og:description') ?? meta('description');
      final image = meta('og:image') ?? meta('twitter:image');

      final preview = ChatLinkPreview(
        url: url,
        title: _nullIfEmpty(title),
        description: _nullIfEmpty(description),
        imageUrl: _absoluteImageUrl(image, pageUrl: url),
      );
      return preview.isRenderable ? preview : null;
    } catch (_) {
      return null;
    }
  }

  /// Blocks non-web schemes and hosts that should never be dialled from a
  /// message body — loopback, bare IPs, and anything without a dotted host.
  static bool isPreviewableUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;

    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;
    if (host == 'localhost' || host.endsWith('.localhost')) return false;
    if (!host.contains('.')) return false;
    if (_isIpLiteral(host)) return false;
    return true;
  }

  static bool _isIpLiteral(String host) {
    if (host.contains(':')) return true; // IPv6 literal
    return RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
  }

  static String? _absoluteImageUrl(String? image, {required String pageUrl}) {
    final value = image?.trim();
    if (value == null || value.isEmpty) return null;
    final resolved = Uri.tryParse(pageUrl)?.resolve(value);
    if (resolved == null) return null;
    if (resolved.scheme != 'http' && resolved.scheme != 'https') return null;
    return resolved.toString();
  }

  static String? _nullIfEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
