import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/connect/data/datasource/connect_remote_datasource.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post_comment.dart';
import 'package:flutter_pecha/features/connect/domain/entities/discover_groups_page.dart';
import 'package:flutter_pecha/features/connect/domain/repositories/connect_repository.dart';
import 'package:fpdart/fpdart.dart';

class ConnectRepositoryImpl implements ConnectRepository {
  ConnectRepositoryImpl({required this.remote, required this.store});

  final ConnectRemoteDatasource remote;
  final ScreenCacheStore store;

  static const int _myGroupsLimit = 20;

  @override
  Future<Either<Failure, DiscoverGroupsPage>> getDiscoverGroups({
    required String language,
    int skip = 0,
    int limit = 20,
    String? search,
  }) async {
    try {
      final page = await remote.fetchDiscoverGroups(
        language: language,
        skip: skip,
        limit: limit,
        search: search,
      );
      return Right(page);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load discover groups: $e'));
    }
  }

  @override
  Future<Either<Failure, DiscoverGroupsPage>> getMyGroups({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final page = await remote.fetchMyGroups(
        language: language,
        skip: skip,
        limit: limit,
      );
      return Right(page);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load my groups: $e'));
    }
  }

  @override
  Stream<Either<Failure, DiscoverGroupsPage>> watchMyGroups({
    required String language,
  }) async* {
    final userId = await store.currentUserId();
    if (userId == null || userId.isEmpty) {
      yield const Left(AuthenticationFailure('Not authenticated'));
      return;
    }
    yield* _myGroupsSource(userId, language).watch();
  }

  @override
  Future<Either<Failure, DiscoverGroupsPage>> refreshMyGroups({
    required String language,
  }) async {
    final userId = await store.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }
    return _myGroupsSource(userId, language).refresh();
  }

  ScreenCacheSource<DiscoverGroupsPage> _myGroupsSource(
    String userId,
    String language,
  ) {
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.user('my_groups', userId: userId, language: language),
      fetchJson:
          () => remote.fetchMyGroupsJson(
            language: language,
            skip: 0,
            limit: _myGroupsLimit,
          ),
      fromJson:
          (json) => ConnectRemoteDatasource.parseGroupsPage(
            json as Map<String, dynamic>,
            skip: 0,
            limit: _myGroupsLimit,
          ),
      failureMessage: 'Failed to load my groups',
    );
  }

  @override
  Future<Either<Failure, ConnectFeedPage>> getConnectFeeds({
    required bool includeUnfollowed,
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final page = await remote.fetchConnectFeeds(
        includeUnfollowed: includeUnfollowed,
        language: language,
        skip: skip,
        limit: limit,
      );
      return Right(page);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load feed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> likePost(String postId) async {
    try {
      await remote.likePost(postId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to like post: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unlikePost(String postId) async {
    try {
      await remote.unlikePost(postId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to unlike post: $e'));
    }
  }

  @override
  Future<Either<Failure, ConnectPostCommentsPage>> getPostComments({
    required String postId,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final page = await remote.fetchPostComments(
        postId: postId,
        skip: skip,
        limit: limit,
      );
      return Right(page);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load comments: $e'));
    }
  }

  @override
  Future<Either<Failure, ConnectPostComment>> createPostComment({
    required String postId,
    required String text,
    String? parentCommentId,
  }) async {
    try {
      final comment = await remote.createPostComment(
        postId: postId,
        text: text,
        parentCommentId: parentCommentId,
      );
      return Right(comment);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to post comment: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePostComment(String commentId) async {
    try {
      await remote.deletePostComment(commentId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to delete comment: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> likeComment(String commentId) async {
    try {
      await remote.likeComment(commentId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to like comment: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unlikeComment(String commentId) async {
    try {
      await remote.unlikeComment(commentId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to unlike comment: $e'));
    }
  }
}
