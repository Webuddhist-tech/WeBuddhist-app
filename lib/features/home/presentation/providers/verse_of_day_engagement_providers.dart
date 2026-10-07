import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day_engagement.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerseOfDayLikesState {
  final int likeCount;
  final bool likedByMe;
  final bool isLoaded;
  final bool isSubmitting;

  const VerseOfDayLikesState({
    this.likeCount = 0,
    this.likedByMe = false,
    this.isLoaded = false,
    this.isSubmitting = false,
  });

  VerseOfDayLikesState copyWith({
    int? likeCount,
    bool? likedByMe,
    bool? isLoaded,
    bool? isSubmitting,
  }) {
    return VerseOfDayLikesState(
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      isLoaded: isLoaded ?? this.isLoaded,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class VerseOfDayLikesNotifier extends StateNotifier<VerseOfDayLikesState> {
  VerseOfDayLikesNotifier({required this.ref, required this.verseId})
    : super(const VerseOfDayLikesState()) {
    load();
  }

  final Ref ref;
  final String verseId;
  bool _isLoading = false;

  /// Bumped on every toggle so a reply that started earlier can't undo it.
  int _toggleCount = 0;

  /// Fetches the count. A failed load leaves [VerseOfDayLikesState.isLoaded]
  /// false so the card hides the count instead of showing a made-up 0.
  Future<bool> load() async {
    if (_isLoading) return false;
    _isLoading = true;
    final toggleCount = _toggleCount;

    final result = await ref
        .read(verseOfDayDomainRepositoryProvider)
        .getLikes(verseId);
    _isLoading = false;
    if (!mounted) return false;

    return result.fold((_) => false, (likes) {
      if (toggleCount == _toggleCount && !state.isSubmitting) {
        state = state.copyWith(
          likeCount: likes.likeCount,
          likedByMe: likes.likedByMe,
          isLoaded: true,
        );
      }
      return true;
    });
  }

  /// Optimistic toggle; returns the failure message when it had to revert.
  Future<String?> toggle() async {
    if (state.isSubmitting) return null;

    if (!state.isLoaded) {
      // The first load is still running; its reply would overwrite the tap.
      if (_isLoading) return null;
      // The first load failed: retry it so the tap acts on the real state.
      if (!await load()) return 'Failed to load likes';
      if (!mounted) return null;
      // The tap meant "like"; the reload shows it is liked already.
      if (state.likedByMe) return null;
    }

    _toggleCount++;
    final previous = state;
    final wasLiked = previous.likedByMe;
    state = previous.copyWith(
      isSubmitting: true,
      likedByMe: !wasLiked,
      likeCount:
          wasLiked
              ? (previous.likeCount - 1).clamp(0, 1 << 31)
              : previous.likeCount + 1,
    );

    final repository = ref.read(verseOfDayDomainRepositoryProvider);
    final result =
        wasLiked
            ? await repository.unlikeVerse(verseId)
            : await repository.likeVerse(verseId);
    if (!mounted) return null;

    return result.fold(
      (failure) {
        state = previous.copyWith(isSubmitting: false);
        return failure.message;
      },
      (_) {
        state = state.copyWith(isSubmitting: false);
        return null;
      },
    );
  }
}

/// Re-created on login/logout so `liked_by_me` reflects the current user.
final verseOfDayLikesProvider = StateNotifierProvider.autoDispose
    .family<VerseOfDayLikesNotifier, VerseOfDayLikesState, String>((
      ref,
      verseId,
    ) {
      ref.watch(
        authProvider.select((state) => state.isLoggedIn && !state.isGuest),
      );
      return VerseOfDayLikesNotifier(ref: ref, verseId: verseId);
    });

class VerseOfDayLikersState {
  final List<VerseOfDayLiker> likers;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const VerseOfDayLikersState({
    this.likers = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });
}

class VerseOfDayLikersNotifier extends StateNotifier<VerseOfDayLikersState> {
  VerseOfDayLikersNotifier({required this.ref, required this.verseId})
    : super(const VerseOfDayLikersState()) {
    loadMore();
  }

  final Ref ref;
  final String verseId;
  static const int _limit = 20;
  int _skip = 0;

  /// Loads the first page, then the next one on each call.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = VerseOfDayLikersState(likers: state.likers, isLoading: true);

    final result = await ref
        .read(verseOfDayDomainRepositoryProvider)
        .getLikers(verseId: verseId, skip: _skip, limit: _limit);
    if (!mounted) return;

    result.fold(
      (failure) {
        state = VerseOfDayLikersState(
          likers: state.likers,
          error: failure.message,
        );
      },
      (page) {
        _skip += page.likers.length;
        final seen = state.likers.map((liker) => liker.userId).toSet();
        final fresh = page.likers.where((liker) => !seen.contains(liker.userId));
        state = VerseOfDayLikersState(
          likers: [...state.likers, ...fresh],
          hasMore: page.hasMore && page.likers.isNotEmpty,
        );
      },
    );
  }
}

final verseOfDayLikersProvider = StateNotifierProvider.autoDispose
    .family<VerseOfDayLikersNotifier, VerseOfDayLikersState, String>((
      ref,
      verseId,
    ) {
      return VerseOfDayLikersNotifier(ref: ref, verseId: verseId);
    });

class VerseOfDayCommentsState {
  final List<VerseOfDayComment> comments;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSubmitting;
  final bool hasLoaded;
  final String? error;
  final bool hasMore;
  final int skip;
  final int total;

  const VerseOfDayCommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.hasLoaded = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.total = 0,
  });

  VerseOfDayCommentsState copyWith({
    List<VerseOfDayComment>? comments,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSubmitting,
    bool? hasLoaded,
    String? error,
    bool? hasMore,
    int? skip,
    int? total,
    bool clearError = false,
  }) {
    return VerseOfDayCommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      total: total ?? this.total,
    );
  }
}

class VerseOfDayCommentsNotifier
    extends StateNotifier<VerseOfDayCommentsState> {
  VerseOfDayCommentsNotifier({required this.ref, required this.verseId})
    : super(const VerseOfDayCommentsState()) {
    loadInitial();
  }

  final Ref ref;
  final String verseId;
  static const int _limit = 20;
  final Set<String> _likingCommentIds = {};

  /// Deleted here; a reply that started before the delete may still list them.
  final Set<String> _deletedCommentIds = {};

  /// Parents fetched on their own, ahead of the page that lists them.
  final Set<String> _extraParentIds = {};

  /// Parents that couldn't be fetched; not retried until the next refresh.
  final Set<String> _unavailableParentIds = {};

  /// A refresh asked for while an older page was loading; runs once it lands.
  bool _refreshPending = false;

  /// Loads the first page. When comments are already shown this is a refresh:
  /// the first page replaces the list and pagination starts over.
  Future<void> loadInitial() async {
    if (state.isLoading) return;
    if (state.isLoadingMore) {
      _refreshPending = true;
      return;
    }

    final shownBefore = state.comments.map((comment) => comment.id).toSet();
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await ref
        .read(verseOfDayDomainRepositoryProvider)
        .getComments(verseId: verseId, skip: 0, limit: _limit);
    if (!mounted) return;

    _unavailableParentIds.clear();
    final parents = await _fetchMissingParents(
      result.fold((_) => const [], (page) => page.comments),
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          hasLoaded: true,
          // A failed refresh keeps the comments already on screen.
          error: state.comments.isEmpty ? failure.message : null,
        );
      },
      (page) {
        final fetched = page.comments.map((comment) => comment.id).toSet();
        // Keep comments posted while this request was in flight.
        final posted =
            state.comments
                .where(
                  (comment) =>
                      !shownBefore.contains(comment.id) &&
                      !fetched.contains(comment.id),
                )
                .toList();
        final current = {
          for (final comment in state.comments) comment.id: comment,
        };
        final comments = [
          for (final comment in page.comments)
            if (!_deletedCommentIds.contains(comment.id))
              // A like still in flight keeps its optimistic state.
              _likingCommentIds.contains(comment.id)
                  ? current[comment.id] ?? comment
                  : comment,
        ];
        // Comments deleted after the server built this reply are gone now.
        final deleted = page.comments.length - comments.length;
        final extras =
            parents
                .where(
                  (parent) =>
                      !fetched.contains(parent.id) &&
                      !_deletedCommentIds.contains(parent.id),
                )
                .toList();
        _extraParentIds
          ..clear()
          ..addAll(extras.map((parent) => parent.id));
        state = state.copyWith(
          comments: [...posted, ...comments, ...extras],
          isLoading: false,
          hasLoaded: true,
          hasMore: page.hasMore,
          skip: comments.length + posted.length,
          total: page.total - deleted + posted.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await ref
        .read(verseOfDayDomainRepositoryProvider)
        .getComments(verseId: verseId, skip: state.skip, limit: _limit);
    if (!mounted) return;

    final parents = await _fetchMissingParents(
      result.fold((_) => const [], (page) => page.comments),
      known: state.comments.map((comment) => comment.id).toSet(),
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        final seen = {
          ...state.comments.map((comment) => comment.id),
          ..._deletedCommentIds,
        };
        final fresh = <VerseOfDayComment>[
          for (final comment in [...page.comments, ...parents])
            if (seen.add(comment.id)) comment,
        ];
        // Parents fetched earlier are now part of the paged list.
        _extraParentIds
          ..removeAll(page.comments.map((comment) => comment.id))
          ..addAll(
            parents
                .where((parent) => fresh.contains(parent))
                .map((parent) => parent.id),
          );
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

    if (_refreshPending) {
      _refreshPending = false;
      loadInitial();
    }
  }

  /// Replies are listed before their older parents; fetches the parents not
  /// paged in yet so the replies can sit under them.
  Future<List<VerseOfDayComment>> _fetchMissingParents(
    List<VerseOfDayComment> comments, {
    Set<String> known = const {},
  }) async {
    final repository = ref.read(verseOfDayDomainRepositoryProvider);
    final have = {...known, for (final comment in comments) comment.id};
    final parents = <VerseOfDayComment>[];
    var pending = comments;

    while (true) {
      final missing =
          pending
              .map((comment) => comment.parentCommentId)
              .whereType<String>()
              .where(
                (id) =>
                    !have.contains(id) &&
                    !_deletedCommentIds.contains(id) &&
                    !_unavailableParentIds.contains(id),
              )
              .toSet()
              .toList();
      if (missing.isEmpty) return parents;

      final results = await Future.wait(
        missing.map(
          (id) => repository.getComment(verseId: verseId, commentId: id),
        ),
      );
      if (!mounted) return parents;

      have.addAll(missing);
      pending = [];
      for (var i = 0; i < missing.length; i++) {
        results[i].fold(
          (_) => _unavailableParentIds.add(missing[i]),
          pending.add,
        );
      }
      parents.addAll(pending);
    }
  }

  /// Returns the failure message, or null when the comment was posted.
  Future<String?> submitComment(String text, {String? parentCommentId}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSubmitting) return null;

    state = state.copyWith(isSubmitting: true, clearError: true);

    final result = await ref
        .read(verseOfDayDomainRepositoryProvider)
        .createComment(
          verseId: verseId,
          text: trimmed,
          parentCommentId: parentCommentId,
        );
    if (!mounted) return null;

    return result.fold(
      (failure) {
        state = state.copyWith(isSubmitting: false);
        return failure.message;
      },
      (comment) {
        state = state.copyWith(
          comments: [comment, ...state.comments],
          isSubmitting: false,
          skip: state.skip + 1,
          total: state.total + 1,
        );
        return null;
      },
    );
  }

  Future<bool> deleteComment(String commentId) async {
    final result = await ref
        .read(verseOfDayDomainRepositoryProvider)
        .deleteComment(commentId);
    if (!mounted) return false;

    return result.fold((_) => false, (_) {
      // Replies go with their parent.
      final removedIds = {commentId};
      var grew = true;
      while (grew) {
        grew = false;
        for (final comment in state.comments) {
          if (removedIds.contains(comment.parentCommentId) &&
              removedIds.add(comment.id)) {
            grew = true;
          }
        }
      }
      _deletedCommentIds.addAll(removedIds);
      final remaining =
          state.comments
              .where((comment) => !removedIds.contains(comment.id))
              .toList();
      final removed = state.comments.length - remaining.length;
      final unpaged = removedIds.where(_extraParentIds.remove).length;
      state = state.copyWith(
        comments: remaining,
        skip: (state.skip - (removed - unpaged)).clamp(0, 1 << 31),
        total: (state.total - removed).clamp(0, 1 << 31),
      );
      return true;
    });
  }

  /// Optimistic toggle; returns the failure message when it had to revert.
  Future<String?> toggleCommentLike(String commentId) async {
    final index = state.comments.indexWhere((c) => c.id == commentId);
    if (index < 0 || !_likingCommentIds.add(commentId)) return null;

    final previous = state.comments[index];
    final wasLiked = previous.likedByMe;
    _replaceComment(
      previous.copyWith(
        likedByMe: !wasLiked,
        likeCount:
            wasLiked
                ? (previous.likeCount - 1).clamp(0, 1 << 31)
                : previous.likeCount + 1,
      ),
    );

    final repository = ref.read(verseOfDayDomainRepositoryProvider);
    final result =
        wasLiked
            ? await repository.unlikeComment(commentId)
            : await repository.likeComment(commentId);
    _likingCommentIds.remove(commentId);
    if (!mounted) return null;

    return result.fold((failure) {
      _replaceComment(previous);
      return failure.message;
    }, (_) => null);
  }

  void _replaceComment(VerseOfDayComment comment) {
    state = state.copyWith(
      comments: [
        for (final c in state.comments) c.id == comment.id ? comment : c,
      ],
    );
  }

  void retry() {
    if (state.comments.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }
}

/// Re-created on login/logout so `liked_by_me` reflects the current user.
final verseOfDayCommentsProvider = StateNotifierProvider.autoDispose
    .family<VerseOfDayCommentsNotifier, VerseOfDayCommentsState, String>((
      ref,
      verseId,
    ) {
      ref.watch(
        authProvider.select((state) => state.isLoggedIn && !state.isGuest),
      );
      return VerseOfDayCommentsNotifier(ref: ref, verseId: verseId);
    });
