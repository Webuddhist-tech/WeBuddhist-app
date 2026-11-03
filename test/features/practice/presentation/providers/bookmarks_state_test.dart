import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_test/flutter_test.dart';

BookmarkDTO _bookmark(BookmarkItemType type) => BookmarkDTO(
  id: type.name,
  type: type,
  sourceId: 'source-${type.name}',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

List<BookmarkTab> _visible(List<BookmarkItemType> types) =>
    BookmarksState(bookmarks: [for (final t in types) _bookmark(t)]).visibleTabs;

void main() {
  group('BookmarksState.visibleTabs', () {
    test('shows only All when there are no bookmarks', () {
      expect(const BookmarksState().visibleTabs, [BookmarkTab.all]);
    });

    test('shows every tab when each type has a bookmark', () {
      expect(
        _visible([
          BookmarkItemType.plan,
          BookmarkItemType.recitationCollection,
          BookmarkItemType.accumulator,
          BookmarkItemType.groupAccumulator,
          BookmarkItemType.timer,
          BookmarkItemType.text,
        ]),
        BookmarkTab.values,
      );
    });

    test('hides tabs without bookmarks and keeps display order', () {
      expect(
        _visible([BookmarkItemType.text, BookmarkItemType.accumulator]),
        [BookmarkTab.all, BookmarkTab.mala, BookmarkTab.texts],
      );
    });

    test('merged types each show their shared tab', () {
      expect(_visible([BookmarkItemType.series]), [
        BookmarkTab.all,
        BookmarkTab.plans,
      ]);
      expect(_visible([BookmarkItemType.groupRecitationCollection]), [
        BookmarkTab.all,
        BookmarkTab.chants,
      ]);
      expect(_visible([BookmarkItemType.verse]), [
        BookmarkTab.all,
        BookmarkTab.texts,
      ]);
    });
  });
}
