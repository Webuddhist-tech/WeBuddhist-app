import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';

class BookmarkRepository {
  final BookmarkRemoteDatasource remoteDatasource;
  final ScreenCacheStore store;

  BookmarkRepository({required this.remoteDatasource, required this.store});

  /// Stored bookmarks first, then revalidated in the background.
  Stream<Either<Failure, List<BookmarkDTO>>> watchBookmarks({
    String? language,
  }) async* {
    final userId = await store.currentUserId();
    if (userId == null || userId.isEmpty) {
      yield const Left(AuthenticationFailure('Not authenticated'));
      return;
    }
    yield* _listSource(userId, language).watch();
  }

  Future<Either<Failure, List<BookmarkDTO>>> refreshBookmarks({
    String? language,
  }) async {
    final userId = await store.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }
    return _listSource(userId, language).refresh();
  }

  ScreenCacheSource<List<BookmarkDTO>> _listSource(
    String userId,
    String? language,
  ) {
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.user(
        'bookmarks',
        userId: userId,
        language: language ?? 'all',
      ),
      fetchJson: () => remoteDatasource.fetchBookmarksJson(language: language),
      fromJson:
          (json) =>
              (json as List)
                  .whereType<Map<String, dynamic>>()
                  .map(BookmarkDTO.tryFromJson)
                  .whereType<BookmarkDTO>()
                  .toList(),
      failureMessage: 'Failed to load bookmarks',
    );
  }

  Future<Either<Failure, bool>> createBookmark({
    required BookmarkType type,
    required String sourceId,
    String? name,
  }) async {
    try {
      final result = await remoteDatasource.createBookmark(
        type: type,
        sourceId: sourceId,
        name: name,
      );
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to create bookmark'));
    }
  }

  Future<Either<Failure, List<BookmarkDTO>>> fetchBookmarks({
    String? language,
  }) async {
    try {
      final result = await remoteDatasource.fetchBookmarks(language: language);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to load bookmarks'));
    }
  }

  Future<Either<Failure, BookmarkExistsResult>> checkBookmarkExists({
    required String sourceId,
    BookmarkType? type,
  }) async {
    try {
      final result = await remoteDatasource.checkBookmarkExists(
        sourceId: sourceId,
        type: type,
      );
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to check bookmark status'),
      );
    }
  }

  Future<Either<Failure, Unit>> deleteBookmark(String bookmarkId) async {
    try {
      await remoteDatasource.deleteBookmark(bookmarkId);
      return const Right(unit);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to remove bookmark'));
    }
  }
}
