import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/cache.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/texts/data/datasource/text_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';

class TextsRepository {
  final TextRemoteDatasource remoteDatasource;
  final CacheService _cacheService = CacheService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final AppLogger _logger = AppLogger('TextsRepository');

  /// Track in-progress background refreshes to prevent duplicate requests
  final Set<String> _pendingRefreshes = {};

  TextsRepository({required this.remoteDatasource});

  /// Fetch text details (reader content) with cache-first strategy and offline support.
  ///
  /// Each paginated request is cached separately using textId + segmentId + direction.
  /// This allows efficient navigation through large texts while maintaining cache.
  ///
  /// 1. Check cache first - return immediately if fresh
  /// 2. If stale, return cached data but refresh in background
  /// 3. If miss/expired, fetch from network
  /// 4. If offline, return cached data even if expired
  ///
  /// Set [forceRefresh] to true to bypass cache (e.g., for pull-to-refresh).
  Future<Either<Failure, ReaderResponse>> fetchTextDetails({
    required String textId,
    String? contentId,
    String? versionId,
    String? segmentId,
    String? direction,
    String? language,
    int? size,
    bool forceRefresh = false,
  }) async {
    // Use consistent cache key from CacheKeys
    final cacheKey = CacheKeys.textDetails(
      textId: textId,
      contentId: contentId,
      versionId: versionId,
      segmentId: segmentId,
      direction: direction,
      language: language,
      size: size,
    );
    final isOnline = _connectivityService.isOnline;

    try {
      // Skip cache if force refresh requested AND we're online
      if (!forceRefresh || !isOnline) {
        final cacheResult = _cacheService.get<ReaderResponse>(
          key: cacheKey,
          box: _cacheService.textContentBox,
          fromJson: ReaderResponse.fromJson,
          ignoreExpiry: !isOnline, // Return expired data if offline
        );

        if (cacheResult.isHit && cacheResult.data != null) {
          _logger.debug(
            'Text details cache hit for: $textId (offline: ${!isOnline})',
          );

          // If stale and online, refresh in background
          if (cacheResult.needsRefresh && isOnline) {
            _refreshTextDetailsInBackground(
              textId,
              contentId,
              versionId,
              segmentId,
              direction,
              language,
              size,
              cacheKey,
            );
          }

          return Right(cacheResult.data!);
        }
      }

      // Connectivity service may produce false-negatives (e.g. DNS to
      // google.com blocked). If we have no cache, attempt the request anyway —
      // a real network error will be caught below and surfaced then.
      if (!isOnline) {
        _logger.debug(
          'isOnline=false but no cache for $textId — attempting network as fallback',
        );
      }

      // Cache miss or force refresh - fetch from network
      _logger.debug(
        forceRefresh
            ? 'Force refreshing text details from network'
            : 'Text details cache miss for: $textId',
      );
      final result = await _fetchAndCacheTextDetails(
        textId,
        contentId,
        versionId,
        segmentId,
        direction,
        language,
        size,
        cacheKey,
      );
      return Right(result);
    } catch (e) {
      // If network fails, try to return cached data (even expired)
      if (e is! OfflineException) {
        final fallbackCache = _cacheService.get<ReaderResponse>(
          key: cacheKey,
          box: _cacheService.textContentBox,
          fromJson: ReaderResponse.fromJson,
          ignoreExpiry: true,
        );

        if (fallbackCache.isHit && fallbackCache.data != null) {
          _logger.debug('Returning fallback cache after network error');
          return Right(fallbackCache.data!);
        }
      }

      _logger.error('Error fetching text details', e);
      return Left(ExceptionMapper.map(e, context: 'Failed to load text content'));
    }
  }

  Future<ReaderResponse> _fetchAndCacheTextDetails(
    String textId,
    String? contentId,
    String? versionId,
    String? segmentId,
    String? direction,
    String? language,
    int? size,
    String cacheKey,
  ) async {
    final result = await remoteDatasource.fetchTextDetails(
      textId: textId,
      contentId: contentId,
      versionId: versionId,
      segmentId: segmentId,
      direction: direction,
      language: language,
      size: size,
    );

    // Cache the result
    await _cacheService.put<ReaderResponse>(
      key: cacheKey,
      box: _cacheService.textContentBox,
      data: result,
      toJson: (r) => r.toJson(),
      ttl: CacheConfig.textContentTtl,
      maxItems: CacheConfig.maxTextCacheItems,
    );

    return result;
  }

  void _refreshTextDetailsInBackground(
    String textId,
    String? contentId,
    String? versionId,
    String? segmentId,
    String? direction,
    String? language,
    int? size,
    String cacheKey,
  ) {
    // Prevent duplicate background refreshes for the same key
    if (_pendingRefreshes.contains(cacheKey)) {
      _logger.debug('Background refresh already in progress for: $textId');
      return;
    }

    _pendingRefreshes.add(cacheKey);

    Future(() async {
      try {
        await _fetchAndCacheTextDetails(
          textId,
          contentId,
          versionId,
          segmentId,
          direction,
          language,
          size,
          cacheKey,
        );
        _logger.debug('Background text refresh completed for: $textId');
      } catch (e) {
        _logger.error('Background text refresh failed for: $textId', e);
      } finally {
        _pendingRefreshes.remove(cacheKey);
      }
    });
  }

  Future<Either<Failure, MultilingualSearchResponse>> multilingualSearchRepository({
    required String query,
    String? language,
    String? textId,
  }) async {
    try {
      final result = await remoteDatasource.multilingualSearch(
        query: query,
        language: language,
        textId: textId,
      );
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to perform multilingual search'));
    }
  }
}
