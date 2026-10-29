import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';

/// `v1:p:<lang>:<screen>[:v<n>][:<params>]` or `v1:u:<user>:<lang>:<screen>...`.
class ScreenCacheKey {
  ScreenCacheKey._();

  static const String anonymous = 'anon';

  static String public(
    String screen, {
    required String language,
    int version = 1,
    List<String> params = const [],
  }) {
    return _join(['p', language, screen], version, params);
  }

  static String user(
    String screen, {
    required String? userId,
    required String language,
    int version = 1,
    List<String> params = const [],
  }) {
    final owner = (userId == null || userId.isEmpty) ? anonymous : userId;
    return _join(['u', owner, language, screen], version, params);
  }

  static String _join(List<String> parts, int version, List<String> params) {
    return [
      ScreenCacheStore.versionPrefix + parts.join(':'),
      if (version > 1) 'v$version',
      ...params,
    ].join(':');
  }
}
