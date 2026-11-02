import 'package:flutter_pecha/features/reader/presentation/utils/reader_top_verse.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

ItemPosition _at(int index, double leading, double trailing) => ItemPosition(
  index: index,
  itemLeadingEdge: leading,
  itemTrailingEdge: trailing,
);

void main() {
  bool every(int _) => true;

  group('readerTopVerseEntry', () {
    test('a verse at the top edge is the current one', () {
      expect(
        readerTopVerseEntry([
          _at(5, 0.2, 0.5),
          _at(4, 0.0, 0.2),
          _at(6, 0.5, 1.1),
        ], every),
        4,
      );
    });

    test('a verse cut off above stays current while half of it shows', () {
      expect(
        readerTopVerseEntry([_at(4, -0.1, 0.2), _at(5, 0.2, 0.6)], every),
        4,
      );
      expect(
        readerTopVerseEntry([_at(4, -0.15, 0.05), _at(5, 0.05, 0.6)], every),
        5,
      );
    });

    test('a verse taller than the screen is current while it fills it', () {
      expect(readerTopVerseEntry([_at(7, -0.8, 1.4)], every), 7);
    });

    test('headings and other sources are passed over', () {
      expect(
        readerTopVerseEntry(
          [_at(2, 0.0, 0.1), _at(3, 0.1, 0.4), _at(4, 0.4, 0.8)],
          (index) => index != 2,
        ),
        3,
      );
    });

    test('entries off screen are not counted; none on screen is null', () {
      expect(
        readerTopVerseEntry([_at(1, -0.4, 0.0), _at(2, 0.0, 0.5)], every),
        2,
      );
      expect(readerTopVerseEntry([_at(9, 1.0, 1.3)], every), isNull);
      expect(readerTopVerseEntry(const [], every), isNull);
    });
  });
}
