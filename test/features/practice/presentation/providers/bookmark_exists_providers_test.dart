import 'dart:async';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';
import 'package:flutter_pecha/features/practice/data/repositories/bookmark_repository.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The bookmarks list, loaded or still loading.
class _FakeBookmarks extends StateNotifier<BookmarksState>
    implements BookmarksNotifier {
  _FakeBookmarks(List<BookmarkDTO> bookmarks, {bool isLoading = false})
    : super(BookmarksState(bookmarks: bookmarks, isLoading: isLoading));

  void finishLoading(List<BookmarkDTO> bookmarks) {
    state = BookmarksState(bookmarks: bookmarks);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements BookmarkRepository {
  int existsCalls = 0;

  /// When set, exists lookups wait on it instead of answering at once.
  Completer<Either<Failure, BookmarkExistsResult>>? pending;

  @override
  Future<Either<Failure, BookmarkExistsResult>> checkBookmarkExists({
    required String sourceId,
    BookmarkType? type,
  }) async {
    existsCalls++;
    if (pending != null) return pending!.future;
    return const Right(BookmarkExistsResult(exists: false));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const target = BookmarkTarget(
    type: BookmarkType.recitationCollection,
    sourceId: 'collection-1',
  );
  final bookmark = BookmarkDTO(
    id: 'bookmark-1',
    type: BookmarkItemType.recitationCollection,
    sourceId: 'collection-1',
    createdAt: DateTime(2026, 9, 24),
    updatedAt: DateTime(2026, 9, 24),
  );

  late _Repository repository;

  ProviderContainer container(
    List<BookmarkDTO> bookmarks, {
    bool isLoading = false,
  }) {
    repository = _Repository();
    final c = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        bookmarksProvider.overrideWith(
          (ref) => _FakeBookmarks(bookmarks, isLoading: isLoading),
        ),
        bookmarkRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(c.dispose);
    // Open the Bookmarks page: the list is in memory and the cache is watched.
    c.listen(bookmarksProvider, (_, __) {});
    c.listen(bookmarkExistsCacheProvider, (_, __) {});
    return c;
  }

  // Opening a bookmarked item from the Bookmarks page used to write the cache
  // while the providers were building, which Riverpod rejects.
  test('a bookmark in the loaded list is filled without a lookup', () async {
    final c = container([bookmark]);

    final isBookmarked = c.listen(isBookmarkedProvider(target), (_, __) {});

    expect(isBookmarked.read(), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(isBookmarked.read(), isTrue);
    expect(repository.existsCalls, 0);
  });

  test('an item missing from the loaded list asks the API', () async {
    final c = container(const []);

    final isBookmarked = c.listen(isBookmarkedProvider(target), (_, __) {});
    await c.read(bookmarkExistsProvider(target).future);

    expect(isBookmarked.read(), isFalse);
    expect(repository.existsCalls, 1);
  });

  // The list is still loading when the item opens; its listener fills the
  // cache once the list arrives, after the providers have built.
  test('a list that finishes loading fills the cache', () async {
    final c = container(const [], isLoading: true);
    repository.pending = Completer();

    final isBookmarked = c.listen(isBookmarkedProvider(target), (_, __) {});
    expect(isBookmarked.read(), isFalse);
    expect(c.read(bookmarkExistsCacheProvider), isNot(contains(target)));

    (c.read(bookmarksProvider.notifier) as _FakeBookmarks).finishLoading([
      bookmark,
    ]);

    expect(c.read(bookmarkExistsCacheProvider)[target]?.exists, isTrue);
    expect(c.read(bookmarkExistsCacheProvider)[target]?.id, 'bookmark-1');
    expect(isBookmarked.read(), isTrue);
  });
}
