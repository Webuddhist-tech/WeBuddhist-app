import 'dart:async';
import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/cache_config.dart';
import 'package:flutter_pecha/core/cache/cache_service.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/texts/data/datasource/text_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';

class TextsRepository {
  final TextRemoteDatasource remoteDatasource;
  final ScreenCacheStore store;
  final AppLogger _logger = AppLogger('TextsRepository');

  TextsRepository({required this.remoteDatasource, required this.store});

  /// Stored page first with a background revalidation; otherwise the network.
  /// [forceRefresh] waits for the server page (pull-to-refresh).
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
    final source = _pageSource(
      textId: textId,
      contentId: contentId,
      versionId: versionId,
      segmentId: segmentId,
      direction: direction,
      language: language,
      size: size,
    );
    if (!forceRefresh) {
      var cached = source.read();
      if (cached == null) {
        // Pages saved by the previous app version keep opening offline.
        cached = _legacyPage(
          textId: textId,
          contentId: contentId,
          versionId: versionId,
          segmentId: segmentId,
          direction: direction,
          language: language,
          size: size,
        );
        if (cached != null) {
          unawaited(
            store
                .save(source.key, jsonEncode(cached.toJson()))
                .catchError((Object _) => false),
          );
        }
      }
      if (cached != null) {
        unawaited(source.refresh());
        return Right(cached);
      }
    }
    return source.refresh();
  }

  ReaderResponse? _legacyPage({
    required String textId,
    String? contentId,
    String? versionId,
    String? segmentId,
    String? direction,
    String? language,
    int? size,
  }) {
    try {
      final cache = CacheService.instance;
      final keys = [
        CacheKeys.textDetails(
          textId: textId,
          contentId: contentId,
          versionId: versionId,
          segmentId: segmentId,
          direction: direction,
          language: language,
          size: size,
        ),
        CacheKeys.textDetailsPrevious(
          textId: textId,
          contentId: contentId,
          versionId: versionId,
          segmentId: segmentId,
          direction: direction,
          language: language,
          size: size,
        ),
      ];
      for (final key in keys) {
        final page = cache
            .get<ReaderResponse>(
              key: key,
              box: cache.textContentBox,
              fromJson: ReaderResponse.fromJson,
              ignoreExpiry: true,
            )
            .data;
        if (page != null) return page;
      }
    } catch (e) {
      _logger.debug('Legacy text cache unavailable: $e');
    }
    return null;
  }

  ScreenCacheSource<ReaderResponse> _pageSource({
    required String textId,
    String? contentId,
    String? versionId,
    String? segmentId,
    String? direction,
    String? language,
    int? size,
  }) {
    final key = ScreenCacheKey.public(
      'text_details',
      language: language ?? 'default',
      version: 8,
      params: [
        textId,
        contentId ?? '',
        versionId ?? '',
        segmentId ?? '',
        direction ?? '',
        '${size ?? ''}',
      ],
    );
    return ScreenCacheSource(
      store: store,
      key: key,
      fetchJson: () async {
        final result = await remoteDatasource.fetchTextDetails(
          textId: textId,
          contentId: contentId,
          versionId: versionId,
          segmentId: segmentId,
          direction: direction,
          language: language,
          size: size,
        );
        // A page without its marks never replaces a stored one that has them.
        if (result.isPartial) {
          final saved = _savedPage(key);
          if (saved != null && !saved.isPartial) return saved.toJson();
        }
        return result.toJson();
      },
      fromJson: (json) => ReaderResponse.fromJson(json as Map<String, dynamic>),
      failureMessage: 'Failed to load text content',
    );
  }

  ReaderResponse? _savedPage(String key) {
    final raw = store.read(key);
    if (raw == null) return null;
    try {
      return ReaderResponse.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      _logger.warning('Stored page $key is unreadable', e);
      return null;
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

  /// See [TextRemoteDatasource.alignSegment]. A failed lookup counts as no
  /// counterpart, so callers treat it like a missing verse.
  Future<String?> alignSegment({
    required String segmentId,
    required String sourceTextId,
    required String targetTextId,
  }) async {
    try {
      return await remoteDatasource.alignSegment(
        segmentId: segmentId,
        sourceTextId: sourceTextId,
        targetTextId: targetTextId,
      );
    } catch (e) {
      _logger.warning('Aligning segment $segmentId failed', e);
      return null;
    }
  }
}
