import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post_comment.dart';
import 'package:flutter_pecha/features/connect/domain/entities/discover_groups_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:fpdart/fpdart.dart';

abstract class ConnectRepository {
  Future<Either<Failure, DiscoverGroupsPage>> getDiscoverGroups({
    required String language,
    int skip = 0,
    int limit = 20,
    String? search,
  });

  Future<Either<Failure, DiscoverGroupsPage>> getMyGroups({
    required String language,
    int skip = 0,
    int limit = 20,
  });

  /// Stored first page of joined groups, then revalidated in the background.
  Stream<Either<Failure, DiscoverGroupsPage>> watchMyGroups({
    required String language,
  });

  Future<Either<Failure, DiscoverGroupsPage>> refreshMyGroups({
    required String language,
  });

  Future<Either<Failure, ConnectFeedPage>> getConnectFeeds({
    required bool includeUnfollowed,
    required String language,
    int skip = 0,
    int limit = 20,
  });

  /// Stored first pages for the Connect lists; see ScreenCacheSource.
  Future<ScreenCacheSource<DiscoverGroupsPage>> discoverGroupsFirstPage({
    required String language,
    required int limit,
  });

  Future<ScreenCacheSource<ConnectFeedPage>> connectFeedFirstPage({
    required bool includeUnfollowed,
    required String language,
    required int limit,
  });

  Future<ScreenCacheSource<GroupEventsPage>> connectEventsFirstPage({
    required bool includeUnfollowed,
    required String language,
    required int limit,
    String? eventFormat,
  });

  Future<ScreenCacheSource<GroupPracticesPage>> connectPracticesFirstPage({
    required bool includeUnfollowed,
    required String language,
    required int limit,
  });

  Future<ScreenCacheSource<ConnectPostCommentsPage>> postCommentsFirstPage(
    String postId, {
    required int limit,
  });

  Future<Either<Failure, void>> likePost(String postId);

  Future<Either<Failure, void>> unlikePost(String postId);

  Future<Either<Failure, ConnectPostCommentsPage>> getPostComments({
    required String postId,
    int skip = 0,
    int limit = 20,
  });

  Future<Either<Failure, ConnectPostComment>> createPostComment({
    required String postId,
    required String text,
    String? parentCommentId,
  });

  Future<Either<Failure, void>> deletePostComment(String commentId);

  Future<Either<Failure, void>> likeComment(String commentId);

  Future<Either<Failure, void>> unlikeComment(String commentId);
}
