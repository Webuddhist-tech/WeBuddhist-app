import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_pecha/core/utils/loaded_window.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post_comment.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/cached_first_page.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_comment_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_like_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectPostCommentsState {
  final List<ConnectPostComment> comments;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? error;
  final bool hasMore;
  final int skip;
  final int total;

  const ConnectPostCommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.total = 0,
  });

  ConnectPostCommentsState copyWith({
    List<ConnectPostComment>? comments,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSubmitting,
    String? error,
    bool? hasMore,
    int? skip,
    int? total,
    bool clearError = false,
  }) {
    return ConnectPostCommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      total: total ?? this.total,
    );
  }

  List<ConnectPostComment> get orderedComments =>
      orderConnectPostComments(comments);
}

/// What changed here while a refresh was out; its read predates these.
class _CommentChanges {
  final Set<String> added = {};
  final Set<String> deleted = {};
  final Map<String, ConnectPostComment> updated = {};
}

class ConnectPostCommentsNotifier
    extends StateNotifier<ConnectPostCommentsState> {
  ConnectPostCommentsNotifier({
    required this.ref,
    required this.postId,
    required ScreenCacheSource<ConnectPostCommentsPage> source,
  }) : _source = source,
       super(_seed(source)) {
    loadInitial();
  }

  // The stored page is the first state, so the first frame never spins.
  static ConnectPostCommentsState _seed(
    ScreenCacheSource<ConnectPostCommentsPage> source,
  ) {
    final page = source.read();
    if (page == null) return const ConnectPostCommentsState();
    return ConnectPostCommentsState(
      comments: page.comments,
      hasMore: page.hasMore,
      skip: page.comments.length,
      total: page.total,
    );
  }

  final Ref ref;
  final String postId;
  final ScreenCacheSource<ConnectPostCommentsPage> _source;
  static const int _limit = 20;

  // Blocks paging while page one is being read again; stale pages are dropped.
  bool _firstPageInFlight = false;
  int _pageEpoch = 0;

  /// The API's largest page, for re-reading loaded comments in few calls.
  static const int _windowLimit = 100;

  /// Comments posted here, kept until a refresh's window reaches them.
  final Map<String, ConnectPostComment> _submitted = {};

  /// Set while a refresh is out; see [_CommentChanges].
  _CommentChanges? _changes;
  bool _refreshing = false;

  /// A signal came while a read was out, so one more runs once it lands.
  bool _refreshAgain = false;

  /// Bumped by every full load, so a background read from before it is
  /// dropped rather than undoing it.
  int _loadGeneration = 0;

  /// Stored first page shows at once; the server's replaces it if changed.
  Future<void> loadInitial() async {
    if (state.isLoading) return;
    _loadGeneration++;

    // Only an empty list shows the loader; a seeded one refreshes silently.
    state = state.copyWith(isLoading: state.comments.isEmpty, clearError: true);

    _firstPageInFlight = true;
    try {
      await loadCachedFirstPage(
        _source,
        isCurrent: () => mounted,
        seed: state.comments.isEmpty,
        apply: (page) {
          _pageEpoch++;
          state = state.copyWith(
            comments: page.comments,
            isLoading: false,
            hasMore: page.hasMore,
            skip: page.comments.length,
            total: page.total,
            clearError: true,
          );
        },
        fail:
            (failure) =>
                state = state.copyWith(isLoading: false, error: failure.message),
      );
    } finally {
      _firstPageInFlight = false;
    }
    _runPendingRefresh();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.isLoading ||
        _firstPageInFlight) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final epoch = _pageEpoch;

    final result = await ref.read(connectRepositoryProvider).getPostComments(
      postId: postId,
      skip: state.skip,
      limit: _limit,
    );

    if (!mounted) return;
    // Page one was replaced meanwhile; this page belongs to the old list.
    if (epoch != _pageEpoch) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        // A merged refresh or an own comment can already hold some of these.
        final known = {for (final comment in state.comments) comment.id};
        final fresh = page.comments.where((c) => !known.contains(c.id));
        state = state.copyWith(
          comments: [...state.comments, ...fresh],
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.comments.length,
          total: page.total,
          clearError: true,
        );
      },
    );
  }

  /// Re-reads every loaded comment after someone comments: new ones join,
  /// deleted ones leave, and the pages already loaded stay.
  Future<void> refreshLatest() async {
    if (state.isLoading || _firstPageInFlight || _refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    final generation = _loadGeneration;
    final changes = _changes = _CommentChanges();
    final LoadedWindow<ConnectPostComment>? read;
    try {
      read = await readLoadedWindow(
        window: () => math.max(_limit, state.skip),
        fetch:
            (skip, limit) async => (await ref
                    .read(connectRepositoryProvider)
                    .getPostComments(postId: postId, skip: skip, limit: limit))
                .map((page) => (page.comments, page.total)),
        idOf: (comment) => comment.id,
        isCurrent: () => mounted && generation == _loadGeneration,
        pageLimit: _windowLimit,
      );
    } finally {
      _refreshing = false;
      _changes = null;
    }
    if (read != null) _applyWindow(read, changes);
    _runPendingRefresh();
  }

  /// The read, with what changed here after it went out laid back over it.
  void _applyWindow(
    LoadedWindow<ConnectPostComment> read,
    _CommentChanges changes,
  ) {
    bool gone(ConnectPostComment comment) =>
        changes.deleted.contains(comment.id) ||
        changes.deleted.contains(comment.parentCommentId);

    final readIds = {for (final comment in read.rows) comment.id};
    _submitted.removeWhere((id, _) => readIds.contains(id));
    final kept = [
      for (final comment in read.rows)
        if (!gone(comment)) changes.updated[comment.id] ?? comment,
    ];
    final removed = read.rows.length - kept.length;
    final addedSince =
        changes.added.where((id) => !readIds.contains(id)).length;
    final skip = kept.length;
    final total = math.max(0, read.total - removed + addedSince);
    _pageEpoch++;
    state = state.copyWith(
      comments: [
        ...kept,
        for (final comment in _submitted.values)
          if (!gone(comment)) comment,
      ],
      hasMore: skip < total,
      skip: skip,
      total: total,
      clearError: true,
    );
  }

  void _runPendingRefresh() {
    if (!_refreshAgain || !mounted) return;
    _refreshAgain = false;
    unawaited(refreshLatest());
  }

  Future<bool> submitComment({
    required String text,
    String? parentCommentId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, clearError: true);

    final result = await ref
        .read(connectRepositoryProvider)
        .createPostComment(
          postId: postId,
          text: trimmed,
          parentCommentId: parentCommentId,
        );

    if (!mounted) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(isSubmitting: false, error: failure.message);
        return false;
      },
      (comment) {
        _submitted[comment.id] = comment;
        _changes?.added.add(comment.id);
        state = state.copyWith(
          comments: [...state.comments, comment],
          isSubmitting: false,
          total: state.total + 1,
          clearError: true,
        );
        return true;
      },
    );
  }

  Future<bool> deleteComment(String commentId) async {
    final result = await ref
        .read(connectRepositoryProvider)
        .deletePostComment(commentId);

    if (!mounted) return false;

    return result.fold((_) => false, (_) {
      _submitted.remove(commentId);
      _changes?.deleted.add(commentId);
      final remaining =
          state.comments.where((comment) {
            return comment.id != commentId &&
                comment.parentCommentId != commentId;
          }).toList();
      final removedCount = state.comments.length - remaining.length;
      state = state.copyWith(
        comments: remaining,
        total: clampConnectLikeCount(state.total - removedCount),
      );
      return true;
    });
  }

  Future<bool> toggleCommentLike(
    ConnectPostComment comment, {
    required bool wasLiked,
  }) async {
    final repository = ref.read(connectRepositoryProvider);
    final result =
        wasLiked
            ? await repository.unlikeComment(comment.id)
            : await repository.likeComment(comment.id);

    if (!mounted) return false;

    return result.fold((_) => false, (_) {
      final updatedComments =
          state.comments.map((item) {
            if (item.id != comment.id) return item;
            final liked = item.copyWith(
              likedByMe: !wasLiked,
              likeCount: nextLikeCountAfterToggle(
                currentCount: item.likeCount,
                wasLiked: wasLiked,
              ),
            );
            _changes?.updated[liked.id] = liked;
            return liked;
          }).toList();
      state = state.copyWith(comments: updatedComments);
      return true;
    });
  }

  Future<void> refresh() async {
    _submitted.clear();
    state = const ConnectPostCommentsState();
    await loadInitial();
  }

  void retry() {
    if (state.comments.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }
}

final connectPostCommentsProvider = StateNotifierProvider.autoDispose
    .family<ConnectPostCommentsNotifier, ConnectPostCommentsState, String>((
      ref,
      postId,
    ) {
      return ConnectPostCommentsNotifier(
        ref: ref,
        postId: postId,
        source: ref
            .watch(connectRepositoryProvider)
            .postCommentsFirstPage(
              postId,
              limit: ConnectPostCommentsNotifier._limit,
            ),
      );
    });
