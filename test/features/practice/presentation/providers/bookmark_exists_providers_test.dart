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

/// The bookmarks list as the Bookmarks page leaves it: already loaded.
class _LoadedBookmarks extends StateNotifier<BookmarksState>
    implements BookmarksNotifier {
  _LoadedBookmarks(List<BookmarkDTO> bookmarks)
    : super(BookmarksState(bookmarks: bookmarks));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements BookmarkRepository {
  int existsCalls = 0;

  @override
  Future<Either<Failure, BookmarkExistsResult>> checkBookmarkExists({
    required String sourceId,
    BookmarkType? type,
  }) async {
    existsCalls++;
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

  ProviderContainer container(List<BookmarkDTO> bookmarks) {
    repository = _Repository();
    final c = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        bookmarksProvider.overrideWith((ref) => _LoadedBookmarks(bookmarks)),
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
}
