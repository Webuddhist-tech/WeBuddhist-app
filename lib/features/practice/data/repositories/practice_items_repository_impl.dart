import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/home/data/models/series_model.dart';
import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';
import 'package:flutter_pecha/features/practice/data/datasource/practice_items_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/practice_item_model.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_item.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_items_page.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_items_tab.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/practice_items_repository.dart';
import 'package:fpdart/fpdart.dart';

class PracticeItemsRepositoryImpl implements PracticeItemsRepository {
  final PracticeItemsRemoteDatasource _datasource;
  final ScreenCacheStore _store;
  final _logger = AppLogger('PracticeItemsRepositoryImpl');

  PracticeItemsRepositoryImpl({
    required PracticeItemsRemoteDatasource datasource,
    required ScreenCacheStore store,
  }) : _datasource = datasource,
       _store = store;

  @override
  PracticeItemsPage? readFirstPage({
    required PracticeItemsTab tab,
    required String language,
    required int pageSize,
  }) => _firstPage(tab, language, pageSize).read();

  @override
  Future<Either<Failure, PracticeItemsPage>> refreshFirstPage({
    required PracticeItemsTab tab,
    required String language,
    required int pageSize,
  }) => _firstPage(tab, language, pageSize).refresh();

  ScreenCacheSource<PracticeItemsPage> _firstPage(
    PracticeItemsTab tab,
    String language,
    int pageSize,
  ) {
    return ScreenCacheSource(
      store: _store,
      key: ScreenCacheKey.public(
        'practice_items_page1',
        language: language,
        params: [tab.toQueryValue(), '$pageSize'],
      ),
      fetchJson:
          () => _datasource.fetchPracticeItemsJson(
            tab: tab,
            language: language,
            page: 1,
            pageSize: pageSize,
          ),
      fromJson:
          (json) => _toPage(
            PracticeItemsResponseModel.fromJson(json as Map<String, dynamic>),
            language,
          ),
      failureMessage: 'Failed to load practice items',
    );
  }

  @override
  Future<Either<Failure, PracticeItemsPage>> getPracticeItems({
    required PracticeItemsTab tab,
    required String language,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _datasource.fetchPracticeItems(
        tab: tab,
        language: language,
        page: page,
        pageSize: pageSize,
      );

      return Right(_toPage(response, language));
    } catch (e, st) {
      _logger.error('Failed to fetch /practice/items', e, st);
      return Left(_toFailure(e));
    }
  }

  PracticeItemsPage _toPage(PracticeItemsResponseModel response, String language) {
    final items = <PracticeItem>[];
    for (final raw in response.items) {
      final entity = _toEntity(raw, language);
      if (entity != null) items.add(entity);
    }
    return PracticeItemsPage(
      items: items,
      page: response.pagination.page,
      pageSize: response.pagination.pageSize,
      total: response.pagination.total,
      totalPages: response.pagination.totalPages,
    );
  }

  /// Converts a raw API row to its domain entity. Unknown types are dropped
  /// (returns null) so the UI never has to render a discriminator it cannot
  /// reason about.
  PracticeItem? _toEntity(PracticeItemModel model, String language) {
    switch (model.type) {
      case PracticeItemType.plan:
        try {
          final plan = PlansModel.fromJson(model.raw).toEntity();
          return PracticePlanItem(plan);
        } catch (e) {
          _logger.warning('Skipping malformed plan item ${model.id}: $e');
          return null;
        }
      case PracticeItemType.series:
        try {
          // `/practice/items` exposes the series cover under `image_url`,
          // while [SeriesModel] (shared with `/series`) reads `image`. Bridge
          // here so series items render their cover without modifying the
          // shared model.
          final normalized = Map<String, dynamic>.from(model.raw);
          normalized['image'] ??= normalized['image_url'];
          final series = SeriesModel.fromJson(normalized).toEntity();
          return PracticeSeriesItem(series);
        } catch (e) {
          _logger.warning('Skipping malformed series item ${model.id}: $e');
          return null;
        }
      case PracticeItemType.unknown:
        _logger.warning('Skipping practice item ${model.id} with unknown type');
        return null;
    }
  }

  Failure _toFailure(Object e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthenticationException) return AuthenticationFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    if (e is RateLimitException) return RateLimitFailure(e.message);
    if (e is ServerException) return ServerFailure(e.message);
    return const ServerFailure(
      'An unexpected error occurred. Please try again.',
    );
  }
}
