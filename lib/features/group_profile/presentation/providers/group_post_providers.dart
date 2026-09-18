import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_post_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_post_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_post_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupPostRemoteDatasourceProvider = Provider<GroupPostRemoteDatasource>((
  ref,
) {
  return GroupPostRemoteDatasource(dio: ref.watch(dioProvider));
});

final groupPostRepositoryProvider = Provider<GroupPostRepositoryInterface>((
  ref,
) {
  return GroupPostRepositoryImpl(
    remote: ref.watch(groupPostRemoteDatasourceProvider),
  );
});

/// Whether the signed-in user may publish posts in the group. Guests never
/// can, so no request is made for them. autoDispose means every visit to the
/// profile screen fetches this fresh.
final groupPostPermissionProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, groupId) async {
      final authState = ref.watch(authProvider);
      if (authState.isGuest || !authState.isLoggedIn) return false;

      final result = await ref
          .watch(groupPostRepositoryProvider)
          .getPostPermission(groupId);
      return result.fold(
        (_) => false,
        (permission) => permission.canCreateContent,
      );
    });

class GroupPostsState {
  final List<ConnectPost> posts;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  /// False until the first load settles, so the tab bar can wait for it.
  final bool hasLoaded;

  const GroupPostsState({
    this.posts = const [],
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.hasLoaded = false,
  });

  GroupPostsState copyWith({
    List<ConnectPost>? posts,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    bool? hasLoaded,
    bool clearError = false,
  }) {
    return GroupPostsState(
      posts: posts ?? this.posts,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class GroupPostsNotifier extends StateNotifier<GroupPostsState> {
  GroupPostsNotifier({
    required GroupPostRepositoryInterface repository,
    required String groupId,
  }) : _repository = repository,
       _groupId = groupId,
       super(const GroupPostsState());

  final GroupPostRepositoryInterface _repository;
  final String _groupId;
  static const int _limit = 20;
  int _requestGeneration = 0;

  Future<void> loadInitial() async {
    if (state.isLoading) return;

    final generation = ++_requestGeneration;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getGroupPosts(
      _groupId,
      skip: 0,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
          hasLoaded: true,
        );
      },
      (page) {
        state = state.copyWith(
          posts: page.posts,
          total: page.total,
          isLoading: false,
          hasMore: page.hasMore,
          skip: page.posts.length,
          hasLoaded: true,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    final generation = _requestGeneration;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await _repository.getGroupPosts(
      _groupId,
      skip: state.skip,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          posts: [...state.posts, ...page.posts],
          total: page.total,
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.posts.length,
          clearError: true,
        );
      },
    );
  }

  void retry() {
    if (state.posts.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }

  /// Shows a freshly published post at the top before the next fetch.
  void prependPost(ConnectPost post) {
    final withoutDuplicate =
        state.posts.where((item) => item.id != post.id).toList();
    state = state.copyWith(
      posts: [post, ...withoutDuplicate],
      total: state.total + 1,
      skip: state.skip + 1,
      hasLoaded: true,
      clearError: true,
    );
  }

  void updatePost(ConnectPost updatedPost) {
    final index = state.posts.indexWhere((post) => post.id == updatedPost.id);
    if (index == -1) return;

    final updatedPosts = [...state.posts];
    updatedPosts[index] = updatedPost;
    state = state.copyWith(posts: updatedPosts);
  }

  /// Resolves false when the API refuses, so the caller can show feedback.
  Future<bool> deletePost(String postId) async {
    final result = await _repository.deletePost(_groupId, postId);
    if (!mounted) return false;

    return result.fold((_) => false, (_) {
      final remaining =
          state.posts.where((post) => post.id != postId).toList();
      if (remaining.length == state.posts.length) return true;
      state = state.copyWith(
        posts: remaining,
        total: state.total > 0 ? state.total - 1 : 0,
        skip: state.skip > 0 ? state.skip - 1 : 0,
      );
      return true;
    });
  }
}

final groupPostsProvider = StateNotifierProvider.autoDispose
    .family<GroupPostsNotifier, GroupPostsState, String>((ref, groupId) {
      // Refetch on auth changes so `liked_by_me` reflects the current user.
      ref.watch(authProvider);
      final notifier = GroupPostsNotifier(
        repository: ref.watch(groupPostRepositoryProvider),
        groupId: groupId,
      );
      notifier.loadInitial();
      return notifier;
    });

void refreshGroupPosts(WidgetRef ref, String groupId) {
  ref.invalidate(groupPostPermissionProvider(groupId));
  if (!ref.exists(groupPostsProvider(groupId))) return;
  ref.read(groupPostsProvider(groupId).notifier).loadInitial();
}
