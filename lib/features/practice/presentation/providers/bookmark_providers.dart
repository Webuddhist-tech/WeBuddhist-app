import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';
import 'package:flutter_pecha/features/practice/data/repositories/bookmark_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(
    remoteDatasource: BookmarkRemoteDatasource(
      dio: ref.watch(dioProvider),
    ),
  );
});

/// Identifies a bookmarkable entity for exists checks and cache invalidation.
@immutable
class BookmarkTarget {
  final BookmarkType type;
  final String sourceId;

  const BookmarkTarget({required this.type, required this.sourceId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkTarget && type == other.type && sourceId == other.sourceId;

  @override
  int get hashCode => Object.hash(type, sourceId);
}

/// Maps list-item types to create/check types. [BookmarkItemType.plan] has no
/// in-app toggle entry point.
BookmarkType? bookmarkTypeFromItem(BookmarkItemType type) => switch (type) {
  BookmarkItemType.text => BookmarkType.text,
  BookmarkItemType.verse => BookmarkType.verse,
  BookmarkItemType.series => BookmarkType.series,
  BookmarkItemType.accumulator => BookmarkType.accumulator,
  BookmarkItemType.timer => BookmarkType.timer,
  BookmarkItemType.groupRecitationCollection =>
    BookmarkType.groupRecitationCollection,
  BookmarkItemType.recitationCollection => BookmarkType.recitationCollection,
  BookmarkItemType.groupAccumulator => BookmarkType.groupAccumulator,
  BookmarkItemType.plan => null,
};

/// Finds a bookmark row matching [target] in an already-loaded list.
BookmarkDTO? findBookmarkInList(
  List<BookmarkDTO> bookmarks,
  BookmarkTarget target,
) {
  for (final bookmark in bookmarks) {
    if (bookmarkTypeFromItem(bookmark.type) == target.type &&
        bookmark.sourceId == target.sourceId) {
      return bookmark;
    }
  }
  return null;
}

/// In-memory exists cache so UI can render instantly after the first lookup.
class BookmarkExistsCacheNotifier
    extends StateNotifier<Map<BookmarkTarget, BookmarkExistsResult>> {
  BookmarkExistsCacheNotifier() : super(const {});

  void set(BookmarkTarget target, BookmarkExistsResult result) {
    state = {...state, target: result};
  }

  void clear(BookmarkTarget target) {
    if (!state.containsKey(target)) return;
    final next = Map<BookmarkTarget, BookmarkExistsResult>.from(state);
    next.remove(target);
    state = next;
  }
}

final bookmarkExistsCacheProvider = StateNotifierProvider<
    BookmarkExistsCacheNotifier,
    Map<BookmarkTarget, BookmarkExistsResult>>((ref) {
  return BookmarkExistsCacheNotifier();
});

/// Seeds the exists cache from a loaded bookmarks list (positive hits only).
void applyBookmarkListCache(
  BookmarkExistsCacheNotifier notifier,
  List<BookmarkDTO> bookmarks,
  BookmarkTarget target, {
  required bool alreadyCached,
}) {
  if (alreadyCached) return;

  final hit = findBookmarkInList(bookmarks, target);
  if (hit != null) {
    notifier.set(target, BookmarkExistsResult(exists: true, id: hit.id));
  }
}

void warmBookmarkExistsCacheFromList(Ref ref, BookmarkTarget target) {
  if (ref.read(bookmarkExistsCacheProvider).containsKey(target)) return;

  // Only reuse the list when it is already loaded — never read [bookmarksProvider]
  // to spawn a full paginated fetch just for a exists warm-up.
  if (!ref.exists(bookmarksProvider)) return;

  final listState = ref.read(bookmarksProvider);
  if (listState.isLoading) return;

  applyBookmarkListCache(
    ref.read(bookmarkExistsCacheProvider.notifier),
    listState.bookmarks,
    target,
    alreadyCached: false,
  );
}

/// Whether [target] is bookmarked for the signed-in user.
///
/// Checks the in-memory cache first, then the loaded bookmarks list, then
/// `GET /users/me/bookmarks/exists`. Guests resolve to `exists: false`.
final bookmarkExistsProvider = FutureProvider.autoDispose
    .family<BookmarkExistsResult, BookmarkTarget>((ref, target) async {
      final auth = ref.watch(authProvider);
      if (auth.isGuest || !auth.isLoggedIn) {
        return const BookmarkExistsResult(exists: false);
      }

      final cached = ref.read(bookmarkExistsCacheProvider)[target];
      if (cached != null) return cached;

      warmBookmarkExistsCacheFromList(ref, target);
      final fromList = ref.read(bookmarkExistsCacheProvider)[target];
      if (fromList != null) return fromList;

      final result = await ref
          .read(bookmarkRepositoryProvider)
          .checkBookmarkExists(
            sourceId: target.sourceId,
            type: target.type,
          );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (exists) {
          ref.read(bookmarkExistsCacheProvider.notifier).set(target, exists);
          ref.keepAlive();
          return exists;
        },
      );
    });

/// Starts loading bookmark exists state early so sheets open with the right icon.
///
/// Uses [ref.watch] (not listen) so [bookmarkExistsProvider] actually runs while
/// the host screen is mounted.
final prefetchBookmarkExistsProvider =
    Provider.autoDispose.family<void, BookmarkTarget>((ref, target) {
      final auth = ref.watch(authProvider);
      if (auth.isGuest || !auth.isLoggedIn) return;

      warmBookmarkExistsCacheFromList(ref, target);

      // If the bookmarks list is already in memory, re-warm when it finishes loading.
      if (ref.exists(bookmarksProvider)) {
        ref.listen(bookmarksProvider, (_, next) {
          if (next.isLoading) return;
          applyBookmarkListCache(
            ref.read(bookmarkExistsCacheProvider.notifier),
            next.bookmarks,
            target,
            alreadyCached: ref.read(bookmarkExistsCacheProvider).containsKey(target),
          );
        }, fireImmediately: true);
      }

      ref.watch(bookmarkExistsProvider(target));
    });

/// Synchronous bookmark-filled state for UI — prefers cache over async loading.
final isBookmarkedProvider = Provider.autoDispose.family<bool, BookmarkTarget>(
  (ref, target) {
    ref.watch(prefetchBookmarkExistsProvider(target));

    final cached = ref.watch(bookmarkExistsCacheProvider)[target];
    if (cached != null) return cached.exists;

    return ref.watch(bookmarkExistsProvider(target)).maybeWhen(
          data: (result) => result.exists,
          orElse: () => false,
        );
  },
);

/// Reads the best-known bookmark status synchronously (cache → list → async data).
BookmarkExistsResult readBookmarkStatus(WidgetRef ref, BookmarkTarget target) {
  final auth = ref.read(authProvider);
  if (auth.isGuest || !auth.isLoggedIn) {
    return const BookmarkExistsResult(exists: false);
  }

  if (!ref.read(bookmarkExistsCacheProvider).containsKey(target)) {
    if (ref.exists(bookmarksProvider)) {
      final listState = ref.read(bookmarksProvider);
      if (!listState.isLoading) {
        applyBookmarkListCache(
          ref.read(bookmarkExistsCacheProvider.notifier),
          listState.bookmarks,
          target,
          alreadyCached: false,
        );
      }
    }
  }

  final cached = ref.read(bookmarkExistsCacheProvider)[target];
  if (cached != null) return cached;

  return ref.read(bookmarkExistsProvider(target)).maybeWhen(
        data: (result) => result,
        orElse: () => const BookmarkExistsResult(exists: false),
      );
}

/// Refreshes the bookmarks list after a mutation. Pass [exists] to commit cache.
void invalidateBookmarkCaches(
  WidgetRef ref, {
  BookmarkTarget? target,
  BookmarkExistsResult? exists,
}) {
  if (target != null && exists != null) {
    ref.read(bookmarkExistsCacheProvider.notifier).set(target, exists);
  } else if (target != null) {
    ref.read(bookmarkExistsCacheProvider.notifier).clear(target);
    ref.invalidate(bookmarkExistsProvider(target));
  }
  ref.invalidate(bookmarksProvider);
}

/// The tabs shown on the bookmarks screen, in display order.
enum BookmarkTab { all, plans, chants, mala, groupAccumulation, timers, texts }

extension BookmarkTabFilter on BookmarkTab {
  /// Whether [bookmark] belongs under this tab.
  ///
  /// `plans` merges PLAN + SERIES (in-app both are "series" routine items);
  /// `texts` merges TEXT + VERSE client-side (VERSE isn't a server filter
  /// value); `mala` maps to ACCUMULATOR and `groupAccumulation` to
  /// GROUP_ACCUMULATOR; `chants` holds chant collections, which are containers
  /// of texts rather than texts themselves.
  bool matches(BookmarkDTO bookmark) => switch (this) {
    BookmarkTab.all => true,
    BookmarkTab.plans =>
      bookmark.type == BookmarkItemType.plan ||
          bookmark.type == BookmarkItemType.series,
    BookmarkTab.chants =>
      bookmark.type == BookmarkItemType.groupRecitationCollection ||
          bookmark.type == BookmarkItemType.recitationCollection,
    BookmarkTab.mala => bookmark.type == BookmarkItemType.accumulator,
    BookmarkTab.groupAccumulation =>
      bookmark.type == BookmarkItemType.groupAccumulator,
    BookmarkTab.timers => bookmark.type == BookmarkItemType.timer,
    BookmarkTab.texts =>
      bookmark.type == BookmarkItemType.text ||
          bookmark.type == BookmarkItemType.verse,
  };
}

/// Immutable view-state for the bookmarks screen. A single fetch backs every
/// tab; [forTab] derives each tab's slice.
class BookmarksState {
  final List<BookmarkDTO> bookmarks;
  final bool isLoading;
  final String? error;

  const BookmarksState({
    this.bookmarks = const [],
    this.isLoading = false,
    this.error,
  });

  BookmarksState copyWith({
    List<BookmarkDTO>? bookmarks,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BookmarksState(
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  List<BookmarkDTO> forTab(BookmarkTab tab) =>
      bookmarks.where(tab.matches).toList();
}

class BookmarksNotifier extends StateNotifier<BookmarksState> {
  BookmarksNotifier(
    this._repository,
    this._language, {
    required bool isAuthenticated,
  }) : _isAuthenticated = isAuthenticated,
       super(BookmarksState(isLoading: isAuthenticated)) {
    if (isAuthenticated) load();
  }

  final BookmarkRepository _repository;
  final String _language;

  /// Guests and signed-out users have no bookmarks to fetch. `/users/me/*` is
  /// bearer-only, so calling it anyway just yields an error screen where the
  /// empty state belongs.
  final bool _isAuthenticated;
  final _logger = AppLogger('BookmarksNotifier');

  Future<void> load() async {
    if (!_isAuthenticated) {
      state = const BookmarksState();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.fetchBookmarks(language: _language);
    if (!mounted) return;
    result.fold(
      (failure) {
        _logger.error('Failed to load bookmarks: ${failure.message}');
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (list) {
        final sorted = [...list]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = BookmarksState(bookmarks: sorted, isLoading: false);
      },
    );
  }

  Future<void> refresh() => load();

  /// Optimistically removes [bookmark], restoring it if the API call fails.
  /// Returns `true` on success.
  Future<bool> remove(BookmarkDTO bookmark) async {
    final previous = state.bookmarks;
    state = state.copyWith(
      bookmarks: previous.where((b) => b.id != bookmark.id).toList(),
      clearError: true,
    );

    final result = await _repository.deleteBookmark(bookmark.id);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        _logger.error('Failed to remove bookmark: ${failure.message}');
        state = state.copyWith(bookmarks: previous);
        return false;
      },
      (_) => true,
    );
  }
}

final bookmarksProvider =
    StateNotifierProvider.autoDispose<BookmarksNotifier, BookmarksState>((ref) {
      // `select` narrows to a single bool: AuthState has no `==`, so watching it
      // whole would rebuild the notifier — and refetch — on every auth emission.
      final isAuthenticated = ref.watch(
        authProvider.select((auth) => auth.isLoggedIn && !auth.isGuest),
      );

      // Watch the content language so changing locale refetches localized
      // bookmark titles/metadata.
      return BookmarksNotifier(
        ref.watch(bookmarkRepositoryProvider),
        ref.watch(contentLanguageProvider),
        isAuthenticated: isAuthenticated,
      );
    });
