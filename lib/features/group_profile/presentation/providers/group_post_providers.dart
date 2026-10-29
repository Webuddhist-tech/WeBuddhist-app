import 'dart:math' as math;

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_post_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_post_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_post_permission.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_post_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:fpdart/fpdart.dart';

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
    store: ref.watch(screenCacheStoreProvider),
  );
});

/// `GET /users/me/permission/{groupId}` for the signed-in user. Guests skip
/// the request. The stored permission shows first and is refreshed each visit.
typedef GroupMyPermissionNotifier =
    AutoDisposeScreenCacheFamilyNotifier<
      GroupPostPermission,
      GroupPostPermission?,
      String
    >;

final groupMyPermissionProvider = AsyncNotifierProvider.autoDispose
    .family<GroupMyPermissionNotifier, GroupPostPermission?, String>(() {
      return GroupMyPermissionNotifier((ref, groupId, bind) {
        final authState = ref.watch(authProvider);
        if (authState.isGuest || !authState.isLoggedIn) return null;

        return bind.source(
          ref.watch(groupPostRepositoryProvider).postPermissionSource(groupId),
          select:
              (result) => result.fold((_) => null, (permission) => permission),
        );
      });
    });

/// Whether the signed-in user may publish posts in the group.
final groupPostPermissionProvider = Provider.autoDispose
    .family<AsyncValue<bool>, String>((ref, groupId) {
      // Derived synchronously, so a stored permission never shows a loader.
      return ref
          .watch(groupMyPermissionProvider(groupId))
          .whenData((permission) => permission?.canCreateContent ?? false);
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

/// What changed here while a refresh was out; its read predates these.
class _PostChanges {
  final Map<String, ConnectPost> added = {};
  final Set<String> deleted = {};
  final Map<String, ConnectPost> updated = {};
}

class GroupPostsNotifier extends StateNotifier<GroupPostsState> {
  GroupPostsNotifier({
    required GroupPostRepositoryInterface repository,
    required String groupId,
    ConnectPostsPage? stored,
  }) : _repository = repository,
       _groupId = groupId,
       super(const GroupPostsState()) {
    // The stored page is the first state, so the first frame never spins.
    if (stored != null) _applyFirstPage(stored, fresh: false);
  }

  final GroupPostRepositoryInterface _repository;
  final String _groupId;
  static const int _limit = 20;

  /// The API's largest page, for re-reading loaded posts in few calls.
  static const int _windowLimit = 100;
  int _requestGeneration = 0;
  // A page-two request must not run from the stored offset while page one is
  // still being refreshed, nor land on a list that page one has replaced.
  bool _firstPageInFlight = false;
  int _pageEpoch = 0;

  /// Numbers refreshes so an older one landing late is dropped.
  int _refreshSeq = 0;

  /// Set while a refresh is out; see [_PostChanges].
  _PostChanges? _changes;

  /// Stored first page shows at once; the server copy replaces it.
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    final generation = ++_requestGeneration;
    state = state.copyWith(isLoading: state.posts.isEmpty, clearError: true);

    _firstPageInFlight = true;
    final Either<Failure, ConnectPostsPage> result;
    try {
      result = await _repository.getGroupPosts(
        _groupId,
        skip: 0,
        limit: _limit,
      );
    } finally {
      _firstPageInFlight = false;
    }

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: state.posts.isEmpty ? failure.message : null,
          hasLoaded: true,
        );
      },
      _applyFirstPage,
    );
  }

  void _applyFirstPage(ConnectPostsPage page, {bool fresh = true}) {
    if (fresh) _pageEpoch++;
    state = state.copyWith(
      posts: page.posts,
      total: page.total,
      isLoading: false,
      hasMore: page.hasMore,
      skip: page.posts.length,
      hasLoaded: true,
      clearError: true,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    if (_firstPageInFlight) return;

    final generation = _requestGeneration;
    final epoch = _pageEpoch;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await _repository.getGroupPosts(
      _groupId,
      skip: state.skip,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;
    if (epoch != _pageEpoch) {
      // Page one was replaced meanwhile; this page was computed against it.
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        // A merged refresh or an own post can already hold some of these.
        final known = {for (final post in state.posts) post.id};
        final fresh = page.posts.where((post) => !known.contains(post.id));
        state = state.copyWith(
          posts: [...state.posts, ...fresh],
          total: page.total,
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.posts.length,
          clearError: true,
        );
      },
    );
  }

  /// Re-reads every loaded position after someone posts, so new posts land
  /// on top with no gap behind them and deleted ones leave. A post pushed
  /// past the window by new ones comes back with the next page.
  Future<void> refreshLatest() async {
    if (state.isLoading || !state.hasLoaded) return;
    final generation = _requestGeneration;
    final seq = ++_refreshSeq;
    final changes = _changes = _PostChanges();
    final window = math.max(_limit, state.skip);
    final rows = <ConnectPost>[];
    final seen = <String>{};
    var total = 0;
    try {
      for (var skip = 0; skip < window; skip += _windowLimit) {
        final result = await _repository.getGroupPosts(
          _groupId,
          skip: skip,
          limit: math.min(_windowLimit, window - skip),
        );
        if (!mounted ||
            generation != _requestGeneration ||
            seq != _refreshSeq) {
          return;
        }
        final page = result.getRight().toNullable();
        if (page == null) return;
        total = page.total;
        rows.addAll(page.posts.where((post) => seen.add(post.id)));
        if (page.posts.length < _windowLimit) break;
      }
    } finally {
      if (identical(_changes, changes)) _changes = null;
    }

    // Laid back over the read: what was posted, deleted or edited here
    // after it went out.
    final added = [
      for (final post in changes.added.values)
        if (!seen.contains(post.id)) post,
    ];
    final deleted = rows.where((post) => changes.deleted.contains(post.id));
    final shift = added.length - deleted.length;
    final skip = rows.length + shift;
    final count = math.max(0, total + shift);
    _pageEpoch++;
    state = state.copyWith(
      posts: [
        ...added,
        for (final post in rows)
          if (!changes.deleted.contains(post.id))
            changes.updated[post.id] ?? post,
      ],
      total: count,
      hasMore: skip < count,
      skip: skip,
      hasLoaded: true,
      clearError: true,
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
    _changes?.added[post.id] = post;
    _changes?.deleted.remove(post.id);
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
    _changes?.updated[updatedPost.id] = updatedPost;
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
      _changes?.deleted.add(postId);
      _changes?.added.remove(postId);
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
      final repository = ref.watch(groupPostRepositoryProvider);
      final notifier = GroupPostsNotifier(
        repository: repository,
        groupId: groupId,
        stored: repository.readStoredGroupPosts(groupId),
      );
      notifier.loadInitial();
      return notifier;
    });

void refreshGroupPosts(WidgetRef ref, String groupId) {
  ref.invalidate(groupMyPermissionProvider(groupId));
  ref.invalidate(groupPostPermissionProvider(groupId));
  if (!ref.exists(groupPostsProvider(groupId))) return;
  ref.read(groupPostsProvider(groupId).notifier).loadInitial();
}
