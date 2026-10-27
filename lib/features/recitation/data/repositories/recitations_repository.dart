import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:fpdart/fpdart.dart';
import '../datasource/recitations_remote_datasource.dart';

class RecitationsRepository {
  RecitationsRepository({
    required this.recitationsRemoteDatasource,
    required this.store,
  });

  final RecitationsRemoteDatasource recitationsRemoteDatasource;
  final ScreenCacheStore store;
  final AppLogger _logger = AppLogger('RecitationsRepository');

  static const String _failureMessage = 'Unable to load recitations';

  /// Stored chant list per language first, then revalidated in the background.
  Stream<Either<Failure, List<RecitationModel>>> watchRecitations({
    required String language,
  }) {
    return _listSource(language).watch();
  }

  Future<Either<Failure, List<RecitationModel>>> refreshRecitations({
    required String language,
  }) {
    return _listSource(language).refresh();
  }

  /// Network only; used by search.
  Future<Either<Failure, List<RecitationModel>>> getRecitations({
    required String language,
    String? searchQuery,
  }) async {
    try {
      final recitations = await recitationsRemoteDatasource.fetchRecitations(
        queryParams: RecitationsQueryParams(
          language: language,
          search: searchQuery,
        ),
      );
      return Right(recitations);
    } catch (e) {
      _logger.error('Error getting recitations', e);
      return Left(ExceptionMapper.map(e, context: _failureMessage));
    }
  }

  ScreenCacheSource<List<RecitationModel>> _listSource(String language) {
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.public('recitations', language: language),
      fetchJson: () async {
        final recitations = await recitationsRemoteDatasource.fetchRecitations(
          queryParams: RecitationsQueryParams(language: language, noCache: true),
        );
        return recitations.map((r) => r.toJson()).toList();
      },
      fromJson:
          (json) =>
              (json as List)
                  .map((e) => RecitationModel.fromJson(e as Map<String, dynamic>))
                  .toList(),
      failureMessage: _failureMessage,
    );
  }
}
