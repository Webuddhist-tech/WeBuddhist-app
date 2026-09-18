import 'dart:convert';

import 'package:http/http.dart' as http;

/// Reads a Content Delivery payload directly, without the Tolgee SDK.
///
/// The SDK cannot serve a multi-part language tag: it stores translations under
/// `Locale.toString()` (`bo-IN`, `zh-Hant-TW`) but looks them up under a
/// normalised code that drops the region for a two-part tag and lower-cases a
/// three-part one — so `bo` and `zh` never matched and silently fell back to
/// the bundled ARB for **every** key. Fetching the payload ourselves keys it by
/// exactly the tag we asked for, which works whatever shape the tag has.
class TolgeeCdn {
  TolgeeCdn._();

  /// Fetches `$cdnUrl/$tag.json`.
  ///
  /// Returns an empty map for anything that is not a usable payload — a 404, a
  /// body that is not a JSON object, a transport failure. The caller treats
  /// empty as "no over-the-air translations" and keeps the bundled ARB, so a
  /// bad response degrades rather than breaking the app.
  static Future<Map<String, String>> fetch({
    required String cdnUrl,
    required String tag,
    required Duration timeout,
    http.Client? client,
  }) async {
    final owned = client == null;
    final httpClient = client ?? http.Client();
    try {
      final uri = Uri.parse('${_trimTrailingSlash(cdnUrl)}/$tag.json');
      final response = await httpClient.get(uri).timeout(timeout);
      if (response.statusCode != 200) return const <String, String>{};

      // Decoded from bytes: the payload is UTF-8 and Tibetan or Chinese would
      // be mangled by the default latin1 reading of `response.body`.
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) return const <String, String>{};

      return <String, String>{
        for (final entry in decoded.entries)
          // Only flat string values are translations. Tolgee can nest
          // structured keys, and those are not something a lookup can return.
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      };
    } catch (_) {
      return const <String, String>{};
    } finally {
      if (owned) httpClient.close();
    }
  }

  static String _trimTrailingSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
