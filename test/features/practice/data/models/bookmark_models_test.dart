import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookmarkDTO', () {
    test('parses RECITATION_COLLECTION bookmark rows', () {
      final bookmark = BookmarkDTO.tryFromJson({
        'id': 'bookmark-1',
        'type': 'RECITATION_COLLECTION',
        'source_id': 'collection-1',
        'name': 'Daily chants',
        'created_at': '2026-09-09T10:00:00.000Z',
        'updated_at': '2026-09-09T10:05:00.000Z',
        'recitation_collection': {
          'id': 'collection-1',
          'name': 'Morning chants',
          'img_url': 'https://example.com/cover.jpg',
          'item_count': 3,
        },
      });

      expect(bookmark, isNotNull);
      expect(bookmark!.type, BookmarkItemType.recitationCollection);
      expect(bookmark.displayTitle, 'Morning chants');
      expect(bookmark.imageUrl, 'https://example.com/cover.jpg');
      expect(bookmark.itemCount, 3);
      expect(bookmark.isOpenable, isTrue);
    });

    test('marks RECITATION_COLLECTION rows without enrichment as orphaned', () {
      final bookmark = BookmarkDTO.tryFromJson({
        'id': 'bookmark-1',
        'type': 'RECITATION_COLLECTION',
        'source_id': 'collection-1',
        'name': 'Daily chants',
        'created_at': '2026-09-09T10:00:00.000Z',
      });

      expect(bookmark, isNotNull);
      expect(bookmark!.displayTitle, 'Daily chants');
      expect(bookmark.isOrphaned, isTrue);
      expect(bookmark.isOpenable, isFalse);
    });
  });

  group('bookmark mapping', () {
    test('maps RECITATION_COLLECTION rows to the create/check type', () {
      expect(
        bookmarkTypeFromItem(BookmarkItemType.recitationCollection),
        BookmarkType.recitationCollection,
      );
      expect(BookmarkType.recitationCollection.value, 'RECITATION_COLLECTION');
    });

    test('shows personal and group recitation collections in chants tab', () {
      BookmarkDTO bookmark(BookmarkItemType type) => BookmarkDTO(
        id: 'bookmark-$type',
        type: type,
        sourceId: 'source-$type',
        createdAt: DateTime(2026, 9, 9),
        updatedAt: DateTime(2026, 9, 9),
      );

      expect(
        BookmarkTab.chants.matches(
          bookmark(BookmarkItemType.recitationCollection),
        ),
        isTrue,
      );
      expect(
        BookmarkTab.chants.matches(
          bookmark(BookmarkItemType.groupRecitationCollection),
        ),
        isTrue,
      );
      expect(
        BookmarkTab.chants.matches(bookmark(BookmarkItemType.text)),
        isFalse,
      );
    });
  });

  Map<String, dynamic> groupAccumulatorRow({bool withPayload = true}) => {
    'id': 'b-1',
    'type': 'GROUP_ACCUMULATOR',
    'source_id': 'ga-1',
    'created_at': '2026-09-01T08:00:00Z',
    if (withPayload)
      'group_accumulator': {
        'id': 'ga-1',
        'group_id': 'g-1',
        'title': 'Group Mani',
        'image': 'https://img/cover.jpg',
      },
  };

  group('GROUP_ACCUMULATOR bookmarks', () {
    test('creates with the GROUP_ACCUMULATOR wire value', () {
      expect(BookmarkType.groupAccumulator.value, 'GROUP_ACCUMULATOR');
      expect(
        bookmarkTypeFromItem(BookmarkItemType.groupAccumulator),
        BookmarkType.groupAccumulator,
      );
    });

    test('parses the nested group_accumulator payload', () {
      final bookmark = BookmarkDTO.tryFromJson(groupAccumulatorRow());

      expect(bookmark, isNotNull);
      expect(bookmark!.type, BookmarkItemType.groupAccumulator);
      expect(bookmark.sourceId, 'ga-1');
      expect(bookmark.displayTitle, 'Group Mani');
      expect(bookmark.imageUrl, 'https://img/cover.jpg');
      expect(bookmark.groupId, 'g-1');
      expect(bookmark.isOrphaned, isFalse);
      expect(bookmark.isOpenable, isTrue);
      expect(bookmark.isRoundLeading, isFalse);
    });

    test('marks a row without its payload as orphaned and unopenable', () {
      final bookmark = BookmarkDTO.tryFromJson(
        groupAccumulatorRow(withPayload: false),
      );

      expect(bookmark, isNotNull);
      expect(bookmark!.isOrphaned, isTrue);
      expect(bookmark.isOpenable, isFalse);
      expect(bookmark.displayTitle, 'Group accumulation');
    });

    test('lists under its own tab, not the mala tab', () {
      final bookmark = BookmarkDTO.tryFromJson(groupAccumulatorRow())!;

      expect(BookmarkTab.groupAccumulation.matches(bookmark), isTrue);
      expect(BookmarkTab.all.matches(bookmark), isTrue);
      expect(BookmarkTab.mala.matches(bookmark), isFalse);
      expect(BookmarkTab.chants.matches(bookmark), isFalse);
      expect(BookmarkTab.texts.matches(bookmark), isFalse);
    });
  });
}
