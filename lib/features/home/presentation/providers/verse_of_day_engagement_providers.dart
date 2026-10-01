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

  Future<void> load() async {
    final result = await ref
        .read(verseOfDayDomainRepositoryProvider)
        .getLikes(verseId);
    if (!mounted) return;

    result.fold(
      (_) => state = state.copyWith(isLoaded: true),
      (likes) =>
          state = state.copyWith(
            likeCount: likes.likeCount,
            likedByMe: likes.likedByMe,
            isLoaded: true,
          ),
    );
  }

  /// Optimistic toggle; returns the failure message when it had to revert.
  Future<String?> toggle() async {
    if (state.isSubmitting) return null;

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

  /// Ids of comments posted from this device; the API omits the author id.
  final Set<String> ownCommentIds;

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
    this.ownCommentIds = const {},
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
    Set<String>? ownCommentIds,
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
      ownCommentIds: ownCommentIds ?? this.ownCommentIds,
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

  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await ref
        .read(verseOfDayDomainRepositoryProvider)
        .getComments(verseId: verseId, skip: 0, limit: _limit);
    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          hasLoaded: true,
          error: failure.message,
        );
      },
      (page) {
        state = state.copyWith(
          comments: page.comments,
          isLoading: false,
          hasLoaded: true,
          hasMore: page.hasMore,
          skip: page.comments.length,
          total: page.total,
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

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        final seen = state.comments.map((comment) => comment.id).toSet();
        final fresh =
            page.comments.where((comment) => !seen.contains(comment.id));
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

  /// Returns the failure message, or null when the comment was posted.
  Future<String?> submitComment(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSubmitting) return null;

    state = state.copyWith(isSubmitting: true, clearError: true);

    final result = await ref
        .read(verseOfDayDomainRepositoryProvider)
        .createComment(verseId: verseId, text: trimmed);
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
          ownCommentIds: {...state.ownCommentIds, comment.id},
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
      final remaining =
          state.comments.where((comment) => comment.id != commentId).toList();
      final removed = state.comments.length - remaining.length;
      state = state.copyWith(
        comments: remaining,
        skip: (state.skip - removed).clamp(0, 1 << 31),
        total: (state.total - removed).clamp(0, 1 << 31),
      );
      return true;
    });
  }

  void retry() {
    if (state.comments.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }
}

final verseOfDayCommentsProvider = StateNotifierProvider.autoDispose
    .family<VerseOfDayCommentsNotifier, VerseOfDayCommentsState, String>((
      ref,
      verseId,
    ) {
      return VerseOfDayCommentsNotifier(ref: ref, verseId: verseId);
    });
