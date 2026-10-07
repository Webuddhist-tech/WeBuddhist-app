import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post_comment.dart';
import 'package:flutter_pecha/features/connect/domain/entities/discover_groups_page.dart';
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

  Future<Either<Failure, ConnectFeedPage>> getConnectFeeds({
    required bool includeUnfollowed,
    required String language,
    int skip = 0,
    int limit = 20,
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
