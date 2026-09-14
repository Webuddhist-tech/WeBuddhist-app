import 'dart:io';

import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/connect/data/models/connect_post_model.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_post_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_post_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_post_permission.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_post_repository.dart';
import 'package:fpdart/fpdart.dart';

class GroupPostRepositoryImpl implements GroupPostRepositoryInterface {
  final GroupPostRemoteDatasource remote;

  GroupPostRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, GroupPostPermission>> getPostPermission(
    String groupId,
  ) {
    return _guard(
      () async => (await remote.fetchPostPermission(groupId)).toEntity(),
      'Failed to load post permission',
    );
  }

  @override
  Future<Either<Failure, ConnectPostsPage>> getGroupPosts(
    String groupId, {
    required int skip,
    required int limit,
  }) {
    return _guard(
      () async =>
          (await remote.fetchGroupPosts(
            groupId,
            skip: skip,
            limit: limit,
          )).toEntity(),
      'Failed to load group posts',
    );
  }

  @override
  Future<Either<Failure, String>> uploadMedia(File file) {
    return _guard(
      () async => (await remote.uploadMedia(file)).key,
      'Failed to upload media',
    );
  }

  @override
  Future<Either<Failure, ConnectPost>> createPost(
    String groupId,
    CreateGroupPostRequest request,
  ) {
    return _guard(
      () async => (await remote.createPost(groupId, request)).toEntity(),
      'Failed to create post',
    );
  }

  @override
  Future<Either<Failure, void>> deletePost(String groupId, String postId) {
    return _guard(
      () => remote.deletePost(groupId, postId),
      'Failed to delete post',
    );
  }

  @override
  Future<Either<Failure, ConnectPost?>> updatePost(
    String groupId,
    String postId, {
    String? caption,
    String status = 'PUBLISHED',
    List<GroupPostMediaRequest>? media,
    List<GroupPostLinkRequest>? links,
  }) async {
    var captionSaved = false;
    var mediaSaved = false;
    var linksSaved = false;
    final result = await _guard(() async {
      ConnectPostModel? latest;
      if (caption != null) {
        latest =
            await remote.updatePost(
              groupId,
              postId,
              caption: caption,
              status: status,
            ) ??
            latest;
        captionSaved = true;
      }
      if (media != null) {
        latest = await remote.updatePostMedia(groupId, postId, media) ?? latest;
        mediaSaved = true;
      }
      if (links != null) {
        latest = await remote.updatePostLinks(groupId, postId, links) ?? latest;
        linksSaved = true;
      }
      return latest?.toEntity();
    }, 'Failed to update post');
    if (!captionSaved && !mediaSaved && !linksSaved) return result;
    // A later request failed after earlier ones persisted; tell the caller.
    return result.mapLeft(
      (failure) => PartialPostUpdateFailure(
        failure.message,
        captionSaved: captionSaved,
        mediaSaved: mediaSaved,
        linksSaved: linksSaved,
      ),
    );
  }

  Future<Either<Failure, T>> _guard<T>(
    Future<T> Function() run,
    String label,
  ) async {
    try {
      return Right(await run());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('$label: $e'));
    }
  }
}
