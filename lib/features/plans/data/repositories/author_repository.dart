import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import '../datasource/author_remote_datasource.dart';
import '../models/author/author_model.dart';
import '../models/plans_model.dart';

class AuthorRepository {
  final AuthorRemoteDatasource authorRemoteDatasource;
  final ScreenCacheStore store;

  AuthorRepository({required this.authorRemoteDatasource, required this.store});

  Future<Either<Failure, AuthorModel>> getAuthorById(String id) async {
    try {
      final result = await authorRemoteDatasource.getAuthorById(id);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Repository error'));
    }
  }

  /// Stored author first, then revalidated in the background.
  Stream<Either<Failure, AuthorModel>> watchAuthorById(String id) =>
      _authorSource(id).watch();

  Future<Either<Failure, AuthorModel>> refreshAuthorById(String id) =>
      _authorSource(id).refresh();

  ScreenCacheSource<AuthorModel> _authorSource(String id) {
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.public('author', language: 'all', params: [id]),
      fetchJson: () => authorRemoteDatasource.fetchAuthorJson(id),
      fromJson: (json) => AuthorModel.fromJson(json as Map<String, dynamic>),
      failureMessage: 'Failed to load author',
    );
  }

  Future<Either<Failure, List<PlansModel>>> getPlansByAuthorId(String authorId) async {
    try {
      final result = await authorRemoteDatasource.getPlansByAuthorId(authorId);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Repository error'));
    }
  }
}
