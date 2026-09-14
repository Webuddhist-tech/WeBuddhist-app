import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_posts_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_unified_feed_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_post_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectPostLikeResult {
  const ConnectPostLikeResult._({this.updatedPost, this.errorMessage});

  final ConnectPost? updatedPost;
  final String? errorMessage;

  bool get isSuccess => errorMessage == null && updatedPost != null;

  factory ConnectPostLikeResult.success(ConnectPost post) =>
      ConnectPostLikeResult._(updatedPost: post);

  factory ConnectPostLikeResult.failure(String message) =>
      ConnectPostLikeResult._(errorMessage: message);
}

/// Toggles a Connect post like and keeps list providers in sync.
class ConnectPostLikeActions {
  ConnectPostLikeActions(this.ref);

  final Ref ref;

  Future<ConnectPostLikeResult> toggleLike({
    required ConnectPost post,
    required bool wasLiked,
    required int optimisticLikeCount,
    required bool includeUnfollowed,
    bool syncFeed = false,
    String? groupId,
  }) async {
    final repository = ref.read(connectRepositoryProvider);
    final result =
        wasLiked
            ? await repository.unlikePost(post.id)
            : await repository.likePost(post.id);

    return result.fold(
      (failure) => ConnectPostLikeResult.failure(failure.message),
      (_) {
        final updatedPost = post.copyWith(
          likedByMe: !wasLiked,
          likeCount: optimisticLikeCount,
        );
        syncPostToListProviders(
          ref,
          post: updatedPost,
          includeUnfollowed: includeUnfollowed,
          syncFeed: syncFeed,
          groupId: groupId,
        );
        return ConnectPostLikeResult.success(updatedPost);
      },
    );
  }

  /// Pushes a locally changed post (e.g. comment count) into the lists.
  void syncPost(
    ConnectPost post, {
    required bool includeUnfollowed,
    String? groupId,
  }) {
    syncPostToListProviders(
      ref,
      post: post,
      includeUnfollowed: includeUnfollowed,
      groupId: groupId,
    );
  }
}

void syncPostToListProviders(
  Ref ref, {
  required ConnectPost post,
  required bool includeUnfollowed,
  bool syncFeed = false,
  String? groupId,
}) {
  final postsProvider =
      includeUnfollowed
          ? discoverConnectPostsProvider
          : myConnectPostsProvider;
  ref.read(postsProvider.notifier).updatePost(post);

  // Skip when the group profile is not on screen; reading would start a fetch.
  if (groupId != null && ref.exists(groupPostsProvider(groupId))) {
    ref.read(groupPostsProvider(groupId).notifier).updatePost(post);
  }

  if (!syncFeed) return;

  final feedProvider =
      includeUnfollowed
          ? discoverUnifiedConnectFeedProvider
          : myUnifiedConnectFeedProvider;
  ref.read(feedProvider.notifier).updatePost(post);
}

final connectPostLikeActionsProvider = Provider<ConnectPostLikeActions>(
  (ref) => ConnectPostLikeActions(ref),
);
