import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/cache.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import '../datasource/recitations_remote_datasource.dart';

class RecitationsRepository {
  final RecitationsRemoteDatasource recitationsRemoteDatasource;
  final CacheService _cacheService = CacheService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final AppLogger _logger = AppLogger('RecitationsRepository');

  /// Track in-progress background refreshes to prevent duplicate requests
  final Set<String> _pendingRefreshes = {};

  RecitationsRepository({required this.recitationsRemoteDatasource});

  /// Get recitations with cache-first strategy and offline support.
  ///
  /// 1. Check cache first - return immediately if fresh
  /// 2. If stale, return cached data but refresh in background
  /// 3. If miss/expired, fetch from network
  /// 4. If offline, return cached data even if expired
  ///
  /// Set [forceRefresh] to true to bypass cache (e.g., for pull-to-refresh).
  Future<Either<Failure, List<RecitationModel>>> getRecitations({
    required String language,
    String? searchQuery,
    bool forceRefresh = false,
  }) async {
    final cacheKey = CacheKeys.recitationList(language, searchQuery);
    final isOnline = _connectivityService.isOnline;

    try {
      // Skip cache if force refresh requested AND we're online
      if (!forceRefresh || !isOnline) {
        final cacheResult = _cacheService.getList<RecitationModel>(
          key: cacheKey,
          box: _cacheService.recitationListBox,
          fromJson: RecitationModel.fromJson,
          ignoreExpiry: !isOnline, // Return expired data if offline
        );

        if (cacheResult.isHit && cacheResult.data != null) {
          _logger.debug(
            'Recitation list cache hit for: $cacheKey (offline: ${!isOnline})',
          );

          // If stale and online, refresh in background
          if (cacheResult.needsRefresh && isOnline) {
            _refreshRecitationsInBackground(language, searchQuery, cacheKey);
          }

          return Right(cacheResult.data!);
        }
      }

      // If offline and no cache, return network failure
      if (!isOnline) {
        return const Left(NetworkFailure('No internet connection and no cached recitations available'));
      }

      // Cache miss or force refresh - fetch from network
      _logger.debug(
        forceRefresh
            ? 'Force refreshing recitations from network'
            : 'Recitation list cache miss, fetching from network',
      );
      final result = await _fetchAndCacheRecitations(language, searchQuery, cacheKey);
      return Right(result);
    } catch (e) {
      // If network fails, try to return cached data (even expired)
      if (e is! OfflineException) {
        final fallbackCache = _cacheService.getList<RecitationModel>(
          key: cacheKey,
          box: _cacheService.recitationListBox,
          fromJson: RecitationModel.fromJson,
          ignoreExpiry: true,
        );

        if (fallbackCache.isHit && fallbackCache.data != null) {
          _logger.debug('Returning fallback cache after network error');
          return Right(fallbackCache.data!);
        }
      }

      _logger.error('Error getting recitations', e);
      return Left(ExceptionMapper.map(e, context: 'Unable to load recitations'));
    }
  }

  Future<List<RecitationModel>> _fetchAndCacheRecitations(
    String language,
    String? searchQuery,
    String cacheKey,
  ) async {
    final recitations = await recitationsRemoteDatasource.fetchRecitations(
      queryParams: RecitationsQueryParams(
        language: language,
        search: searchQuery,
      ),
    );

    // Cache the result
    await _cacheService.putList<RecitationModel>(
      key: cacheKey,
      box: _cacheService.recitationListBox,
      data: recitations,
      toJson: (r) => r.toJson(),
      ttl: CacheConfig.recitationListTtl,
      maxItems: CacheConfig.maxRecitationCacheItems,
    );

    return recitations;
  }

  void _refreshRecitationsInBackground(
    String language,
    String? searchQuery,
    String cacheKey,
  ) {
    // Prevent duplicate background refreshes for the same key
    if (_pendingRefreshes.contains(cacheKey)) {
      _logger.debug('Background refresh already in progress for: $cacheKey');
      return;
    }

    _pendingRefreshes.add(cacheKey);

    // Fire and forget - refresh cache in background
    Future(() async {
      try {
        await _fetchAndCacheRecitations(language, searchQuery, cacheKey);
        _logger.debug('Background refresh completed for: $cacheKey');
      } catch (e) {
        _logger.error('Background refresh failed for: $cacheKey', e);
      } finally {
        _pendingRefreshes.remove(cacheKey);
      }
    });
  }
}
