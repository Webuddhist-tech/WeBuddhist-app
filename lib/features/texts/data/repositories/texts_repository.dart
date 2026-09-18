import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/cache.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/texts/data/datasource/text_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/search/search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/search/title_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/commentary_text_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/detail_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/toc_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/version_response.dart';

class TextsRepository {
  final TextRemoteDatasource remoteDatasource;
  final CacheService _cacheService = CacheService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final AppLogger _logger = AppLogger('TextsRepository');

  /// Track in-progress background refreshes to prevent duplicate requests
  final Set<String> _pendingRefreshes = {};

  TextsRepository({required this.remoteDatasource});

  /// Get texts (works) within a collection with cache-first strategy.
  ///
  /// Set [forceRefresh] to true to bypass cache (e.g., for pull-to-refresh).
  Future<Either<Failure, TextDetailResponse>> getTexts({
    required String termId,
    String? language,
    int skip = 0,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = CacheKeys.workList(
      termId: termId,
      language: language,
      skip: skip,
      limit: limit,
    );
    final isOnline = _connectivityService.isOnline;

    try {
      if (!forceRefresh || !isOnline) {
        final cacheResult = _cacheService.get<TextDetailResponse>(
          key: cacheKey,
          box: _cacheService.workListBox,
          fromJson: TextDetailResponse.fromJson,
          ignoreExpiry: !isOnline,
        );

        if (cacheResult.isHit && cacheResult.data != null) {
          _logger.debug('Works cache hit for: $termId (offline: ${!isOnline})');

          if (cacheResult.needsRefresh && isOnline) {
            _refreshWorksInBackground(termId, language, skip, limit, cacheKey);
          }

          return Right(cacheResult.data!);
        }
      }

      if (!isOnline) {
        return const Left(NetworkFailure('No internet connection and no cached works available'));
      }

      _logger.debug(
        forceRefresh
            ? 'Force refreshing works from network'
            : 'Works cache miss for: $termId',
      );
      final result = await _fetchAndCacheWorks(termId, language, skip, limit, cacheKey);
      return Right(result);
    } catch (e) {
      // Try fallback cache on network error
      if (e is! OfflineException) {
        final fallbackCache = _cacheService.get<TextDetailResponse>(
          key: cacheKey,
          box: _cacheService.workListBox,
          fromJson: TextDetailResponse.fromJson,
          ignoreExpiry: true,
        );

        if (fallbackCache.isHit && fallbackCache.data != null) {
          _logger.debug('Returning fallback cache after network error');
          return Right(fallbackCache.data!);
        }
      }

      _logger.error('Error fetching works', e);
      return Left(ExceptionMapper.map(e, context: 'Failed to load works'));
    }
  }

  Future<TextDetailResponse> _fetchAndCacheWorks(
    String termId,
    String? language,
    int skip,
    int limit,
    String cacheKey,
  ) async {
    final result = await remoteDatasource.fetchTexts(
      termId: termId,
      language: language,
      skip: skip,
      limit: limit,
    );

    await _cacheService.put<TextDetailResponse>(
      key: cacheKey,
      box: _cacheService.workListBox,
      data: result,
      toJson: (r) => r.toJson(),
      ttl: CacheConfig.workListTtl,
      maxItems: CacheConfig.maxTextCacheItems,
    );

    return result;
  }

  void _refreshWorksInBackground(
    String termId,
    String? language,
    int skip,
    int limit,
    String cacheKey,
  ) {
    if (_pendingRefreshes.contains(cacheKey)) {
      _logger.debug(
        'Background refresh already in progress for works: $termId',
      );
      return;
    }

    _pendingRefreshes.add(cacheKey);

    Future(() async {
      try {
        await _fetchAndCacheWorks(termId, language, skip, limit, cacheKey);
        _logger.debug('Background works refresh completed for: $termId');
      } catch (e) {
        _logger.error('Background works refresh failed for: $termId', e);
      } finally {
        _pendingRefreshes.remove(cacheKey);
      }
    });
  }

  Future<Either<Failure, TocResponse>> fetchTextContent({
    required String textId,
    String? language,
  }) async {
    try {
      final result = await remoteDatasource.fetchTextContent(
        textId: textId,
        language: language,
      );
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to fetch text content'));
    }
  }

  /// Fetch text versions with cache-first strategy.
  ///
  /// Set [forceRefresh] to true to bypass cache (e.g., for pull-to-refresh).
  Future<Either<Failure, VersionResponse>> fetchTextVersion({
    required String textId,
    String? language,
    bool forceRefresh = false,
  }) async {
    final cacheKey = CacheKeys.textVersionList(
      textId: textId,
      language: language,
    );
    final isOnline = _connectivityService.isOnline;

    try {
      if (!forceRefresh || !isOnline) {
        final cacheResult = _cacheService.get<VersionResponse>(
          key: cacheKey,
          box: _cacheService.textVersionListBox,
          fromJson: VersionResponse.fromJson,
          ignoreExpiry: !isOnline,
        );

        if (cacheResult.isHit && cacheResult.data != null) {
          _logger.debug(
            'Text version cache hit for: $textId (offline: ${!isOnline})',
          );

          if (cacheResult.needsRefresh && isOnline) {
            _refreshVersionInBackground(textId, language, cacheKey);
          }

          return Right(cacheResult.data!);
        }
      }

      if (!isOnline) {
        return const Left(NetworkFailure('No internet connection and no cached text versions available'));
      }

      _logger.debug(
        forceRefresh
            ? 'Force refreshing text versions from network'
            : 'Text version cache miss for: $textId',
      );
      final result = await _fetchAndCacheVersion(textId, language, cacheKey);
      return Right(result);
    } catch (e) {
      // Try fallback cache on network error
      if (e is! OfflineException) {
        final fallbackCache = _cacheService.get<VersionResponse>(
          key: cacheKey,
          box: _cacheService.textVersionListBox,
          fromJson: VersionResponse.fromJson,
          ignoreExpiry: true,
        );

        if (fallbackCache.isHit && fallbackCache.data != null) {
          _logger.debug('Returning fallback cache after network error');
          return Right(fallbackCache.data!);
        }
      }

      _logger.error('Error fetching text versions', e);
      return Left(ExceptionMapper.map(e, context: 'Failed to load text versions'));
    }
  }

  Future<VersionResponse> _fetchAndCacheVersion(
    String textId,
    String? language,
    String cacheKey,
  ) async {
    final result = await remoteDatasource.fetchTextVersion(
      textId: textId,
      language: language,
    );

    await _cacheService.put<VersionResponse>(
      key: cacheKey,
      box: _cacheService.textVersionListBox,
      data: result,
      toJson: (r) => r.toJson(),
      ttl: CacheConfig.textVersionListTtl,
      maxItems: CacheConfig.maxTextCacheItems,
    );

    return result;
  }

  void _refreshVersionInBackground(
    String textId,
    String? language,
    String cacheKey,
  ) {
    if (_pendingRefreshes.contains(cacheKey)) {
      _logger.debug(
        'Background refresh already in progress for version: $textId',
      );
      return;
    }

    _pendingRefreshes.add(cacheKey);

    Future(() async {
      try {
        await _fetchAndCacheVersion(textId, language, cacheKey);
        _logger.debug('Background version refresh completed for: $textId');
      } catch (e) {
        _logger.error('Background version refresh failed for: $textId', e);
      } finally {
        _pendingRefreshes.remove(cacheKey);
      }
    });
  }

  /// Fetch commentary text with cache-first strategy.
  ///
  /// Set [forceRefresh] to true to bypass cache (e.g., for pull-to-refresh).
  Future<Either<Failure, CommentaryTextResponse>> fetchCommentaryText({
    required String textId,
    String? language,
    bool forceRefresh = false,
  }) async {
    final cacheKey = CacheKeys.textCommentList(
      textId: textId,
      language: language,
    );
    final isOnline = _connectivityService.isOnline;

    try {
      if (!forceRefresh || !isOnline) {
        final cacheResult = _cacheService.get<CommentaryTextResponse>(
          key: cacheKey,
          box: _cacheService.textCommentListBox,
          fromJson: CommentaryTextResponse.fromCacheJson,
          ignoreExpiry: !isOnline,
        );

        if (cacheResult.isHit && cacheResult.data != null) {
          _logger.debug(
            'Commentary cache hit for: $textId (offline: ${!isOnline})',
          );

          if (cacheResult.needsRefresh && isOnline) {
            _refreshCommentaryInBackground(textId, language, cacheKey);
          }

          return Right(cacheResult.data!);
        }
      }

      if (!isOnline) {
        return const Left(NetworkFailure('No internet connection and no cached commentary available'));
      }

      _logger.debug(
        forceRefresh
            ? 'Force refreshing commentary from network'
            : 'Commentary cache miss for: $textId',
      );
      final result = await _fetchAndCacheCommentary(textId, language, cacheKey);
      return Right(result);
    } catch (e) {
      // Try fallback cache on network error
      if (e is! OfflineException) {
        final fallbackCache = _cacheService.get<CommentaryTextResponse>(
          key: cacheKey,
          box: _cacheService.textCommentListBox,
          fromJson: CommentaryTextResponse.fromCacheJson,
          ignoreExpiry: true,
        );

        if (fallbackCache.isHit && fallbackCache.data != null) {
          _logger.debug('Returning fallback cache after network error');
          return Right(fallbackCache.data!);
        }
      }

      _logger.error('Error fetching commentary', e);
      return Left(ExceptionMapper.map(e, context: 'Failed to load commentary'));
    }
  }

  Future<CommentaryTextResponse> _fetchAndCacheCommentary(
    String textId,
    String? language,
    String cacheKey,
  ) async {
    final result = await remoteDatasource.fetchCommentaryText(
      textId: textId,
      language: language,
    );

    await _cacheService.put<CommentaryTextResponse>(
      key: cacheKey,
      box: _cacheService.textCommentListBox,
      data: result,
      toJson: (r) => r.toJson(),
      ttl: CacheConfig.textCommentListTtl,
      maxItems: CacheConfig.maxTextCacheItems,
    );

    return result;
  }

  void _refreshCommentaryInBackground(
    String textId,
    String? language,
    String cacheKey,
  ) {
    if (_pendingRefreshes.contains(cacheKey)) {
      _logger.debug(
        'Background refresh already in progress for commentary: $textId',
      );
      return;
    }

    _pendingRefreshes.add(cacheKey);

    Future(() async {
      try {
        await _fetchAndCacheCommentary(textId, language, cacheKey);
        _logger.debug('Background commentary refresh completed for: $textId');
      } catch (e) {
        _logger.error('Background commentary refresh failed for: $textId', e);
      } finally {
        _pendingRefreshes.remove(cacheKey);
      }
    });
  }

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

  Future<Either<Failure, SearchResponse>> searchTextRepository({
    required String query,
    String? textId,
  }) async {
    try {
      final result = await remoteDatasource.searchText(
        query: query,
        textId: textId,
      );
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to search text'));
    }
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

  Future<Either<Failure, TitleSearchResponse>> titleSearchRepository({
    String? title,
    String? author,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final result = await remoteDatasource.titleSearch(
        title: title,
        author: author,
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to search by title'));
    }
  }

  Future<Either<Failure, TitleSearchResponse>> authorSearchRepository({
    String? author,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final result = await remoteDatasource.authorSearch(
        author: author,
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to search by author'));
    }
  }
}
