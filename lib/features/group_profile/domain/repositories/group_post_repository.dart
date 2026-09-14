import 'dart:io';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_post_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_post_permission.dart';
import 'package:fpdart/fpdart.dart';

abstract class GroupPostRepositoryInterface {
  Future<Either<Failure, GroupPostPermission>> getPostPermission(
    String groupId,
  );

  Future<Either<Failure, ConnectPostsPage>> getGroupPosts(
    String groupId, {
    required int skip,
    required int limit,
  });

  /// Uploads one file and returns its storage key for [createPost].
  Future<Either<Failure, String>> uploadMedia(File file);

  Future<Either<Failure, ConnectPost>> createPost(
    String groupId,
    CreateGroupPostRequest request,
  );

  Future<Either<Failure, void>> deletePost(String groupId, String postId);

  /// Sends only the parts given: caption via PATCH, media and links via PUT.
  /// Resolves with the post when the API echoes it, otherwise null.
  /// A failure after a persisted step is a [PartialPostUpdateFailure].
  Future<Either<Failure, ConnectPost?>> updatePost(
    String groupId,
    String postId, {
    String? caption,
    String status = 'PUBLISHED',
    List<GroupPostMediaRequest>? media,
    List<GroupPostLinkRequest>? links,
  });
}
