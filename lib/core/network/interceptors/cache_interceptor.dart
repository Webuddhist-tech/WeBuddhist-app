import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/iana_timezone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple in-memory cache for GET requests.
///
/// This interceptor caches GET requests in memory for a short duration
/// to avoid redundant network calls. At most [maxEntries] responses are kept,
/// least recently used first out, since text content passes through it too.
/// For more advanced caching, consider using dio_cache_interceptor.
class CacheInterceptor extends Interceptor {
  CacheInterceptor(this._logger, {this.maxEntries = 200});

  final AppLogger _logger;
  final int maxEntries;

  /// Insertion-ordered: the first key is the least recently used.
  final Map<String, _CacheEntry> _cache = {};

  /// Default TTL for cache entries (5 minutes)
  static const defaultTTL = Duration(minutes: 5);

  /// User-specific responses must not be cached — keys are not scoped by token.
  static bool isUserSpecificPath(String path) {
    return path == '/users/info' || path.startsWith('/users/me');
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Only cache GET requests (unless explicitly opted out)
    if (options.method.toUpperCase() == 'GET' &&
        options.extra['no_cache'] != true &&
        _shouldCache(options.path)) {
      final cacheKey = _generateCacheKey(options);
      final cached = _cache[cacheKey];

      if (cached != null && !cached.isExpired) {
        _logger.info('📦 Cache HIT: $cacheKey');
        _cache
          ..remove(cacheKey)
          ..[cacheKey] = cached;
        // Return cached data as a successful response
        handler.resolve(
          Response(
            requestOptions: options,
            data: cached.data,
            statusCode: 200,
            extra: {'cached': true},
          ),
        );
        return;
      } else if (cached != null && cached.isExpired) {
        // Remove expired entry
        _cache.remove(cacheKey);
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final request = response.requestOptions;
    final method = request.method.toUpperCase();
    final statusCode = response.statusCode ?? 0;

    // Auto-invalidate related GET cache when mutations succeed
    if (_isMutationMethod(method) && _isSuccessStatus(statusCode)) {
      final relatedPaths = _extractRelatedPaths(request.path);
      for (final path in relatedPaths) {
        invalidate(path);
      }
      _logger.info('🗑️ Auto-invalidated cache for mutation on: $relatedPaths');
    }

    // Cache successful GET responses (unless the request opted out)
    if (method == 'GET' &&
        statusCode == 200 &&
        request.extra['no_cache'] != true &&
        _shouldCache(request.path) &&
        !response.extra.containsKey('cached')) {
      final cacheKey = _generateCacheKey(request);
      final ttl = request.extra['cache_ttl'] as Duration? ?? defaultTTL;

      _cache
        ..remove(cacheKey)
        ..[cacheKey] = _CacheEntry(
          data: response.data,
          expiry: DateTime.now().add(ttl),
        );
      _evict();

      _logger.debug('Cached response for: $cacheKey (TTL: $ttl)');
    }

    handler.next(response);
  }

  /// Check if HTTP method is a mutation (modifies data)
  bool _isMutationMethod(String method) {
    return method == 'POST' ||
        method == 'PUT' ||
        method == 'PATCH' ||
        method == 'DELETE';
  }

  /// Check if status code indicates success
  bool _isSuccessStatus(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  /// Extract base paths for cache invalidation.
  /// Returns list of paths to invalidate for comprehensive cache clearing.
  List<String> _extractRelatedPaths(String path) {
    final paths = <String>[];
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    
    // Remove trailing action segments like "complete"
    if (segments.isNotEmpty && _isActionSegment(segments.last)) {
      segments.removeLast();
    }
    
    // If last segment looks like an ID, remove it for the base path
    if (segments.isNotEmpty && _looksLikeId(segments.last)) {
      segments.removeLast();
    }
    
    paths.add('/${segments.join('/')}');
    
    // For task/subtask mutations, also invalidate plan-related caches
    // This handles: /users/me/tasks/..., /users/me/task/..., /users/me/sub-tasks/...
    if (path.contains('/task') || path.contains('/sub-task')) {
      paths.add('/users/me/plan');
      paths.add('/users/me/plans');
    }

    // Routine mutations (/routines/...) should invalidate user routine and enrolled plans
    // (backend auto-enrolls users in plans when added to routine)
    if (path.startsWith('/routines')) {
      paths.add('/users/me/routine');
      paths.add('/users/me/plans');
    }

    // Join/leave or follow/unfollow group mutations should refresh group lists.
    final groupJoinMatch = RegExp(
      r'/author/groups/([^/]+)/(join|follow)',
    ).firstMatch(path);
    if (groupJoinMatch != null) {
      paths.add('/author/groups/${groupJoinMatch.group(1)}');
      paths.add('/author/groups');
      paths.add('/users/me/joined/author/groups');
      paths.add('/users/me/following/author/groups');
    }

    // Series enrollment may auto-join the group and updates group-scoped flags.
    if (path.startsWith('/users/me/series')) {
      paths.add('/author/groups');
      paths.add('/users/me/joined/author/groups');
      paths.add('/users/me/following/author/groups');
    }

    // Accumulator and timer sessions update aggregated user stats.
    if (path.contains('/accumulators') || path.contains('/timers')) {
      paths.add('/users/me/stats');
    }

    return paths;
  }

  /// Check if a segment is an action (not data to be cached)
  bool _isActionSegment(String value) {
    const actions = [
      'complete',
      'incomplete',
      'toggle',
      'delete',
      'archive',
      'join',
      'follow',
    ];
    return actions.contains(value.toLowerCase());
  }

  /// Check if a string looks like an ID (UUID or numeric)
  bool _looksLikeId(String value) {
    // Check for UUID format
    if (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(value)) return true;
    // Check for numeric ID
    if (RegExp(r'^\d+$').hasMatch(value)) return true;
    return false;
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // Don't cache errors
    handler.next(err);
  }

  /// Generate a unique cache key for the request.
  ///
  /// Keys are scoped by whether the request carried a bearer: optional-auth
  /// endpoints (e.g. /series, /plans/{id}/days) return user-enriched fields
  /// like `progress`/`is_enrolled` when authenticated, so an anonymous
  /// response must never be served to a signed-in user (or vice versa).
  /// [AuthInterceptor] runs before this interceptor, so the header is final.
  String _generateCacheKey(RequestOptions options) {
    final scope =
        options.headers.containsKey('Authorization') ? 'auth' : 'anon';
    final path = options.path;
    final params = Map<String, dynamic>.from(options.queryParameters);
    final timezone = options.headers[IanaTimezone.headerName]?.toString();
    if (timezone != null && timezone.isNotEmpty) {
      params[IanaTimezone.headerName] = timezone;
    }
    if (params.isEmpty) return '$scope|$path';

    final sortedParams = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final queryString =
        sortedParams.map((e) => '${e.key}=${e.value}').join('&');
    return '$scope|$path?$queryString';
  }

  /// Drops expired entries, then the least recently used beyond [maxEntries].
  void _evict() {
    if (_cache.length <= maxEntries) return;
    _cache.removeWhere((_, entry) => entry.isExpired);
    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Clear all cached entries
  void clear() {
    _cache.clear();
    _logger.info('Cache cleared');
  }

  /// Drop every cached response fetched with a bearer. Called on auth
  /// transitions (login/logout/account switch) so the next account never
  /// inherits the prior user's auth-enriched responses within the TTL.
  /// Anonymous (public) entries are safe to keep.
  void clearUserScoped() {
    _cache.removeWhere((key, _) => key.startsWith('auth|'));
    _logger.info('Auth-scoped HTTP cache cleared');
  }

  /// Remove cached entries for [path] (both auth scopes)
  void invalidate(String path) {
    _cache.removeWhere((key, _) => _keyWithoutScope(key).startsWith(path));
    _logger.info('Cache invalidated for: $path');
  }

  bool _shouldCache(String path) => !isUserSpecificPath(path);

  String _keyWithoutScope(String cacheKey) {
    final sep = cacheKey.indexOf('|');
    return sep == -1 ? cacheKey : cacheKey.substring(sep + 1);
  }
}

/// Shared [CacheInterceptor] instance wired into the main and library Dio
/// clients. Keys hold the path, not the host: library paths are all `/v2/`.
final cacheInterceptorProvider = Provider<CacheInterceptor>((ref) {
  return CacheInterceptor(AppLogger('CacheInterceptor'));
});

class _CacheEntry {
  _CacheEntry({
    required this.data,
    required this.expiry,
  });

  final dynamic data;
  final DateTime expiry;

  bool get isExpired => DateTime.now().isAfter(expiry);
}
