import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_item_display.dart';
import 'package:flutter_test/flutter_test.dart';

RoutineItem _item(String title) =>
    RoutineItem(id: title, title: title, type: RoutineItemType.series);

RoutineBlock _block({String? title, List<RoutineItem> items = const []}) =>
    RoutineBlock(
      time: const TimeOfDay(hour: 7, minute: 0),
      title: title,
      items: items,
    );

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  group('routineBlockDisplayTitle', () {
    test('keeps the user-given title', () {
      final block = _block(
        title: 'Evening practice',
        items: [_item('Morning chants'), _item('Heart Sutra')],
      );
      expect(routineBlockDisplayTitle(block, en), 'Evening practice');
    });

    test('uses the only item name when untitled', () {
      final block = _block(items: [_item('Bodhisattva Challenge')]);
      expect(routineBlockDisplayTitle(block, en), 'Bodhisattva Challenge');
    });

    test('adds "+N more" when untitled with several items', () {
      final block = _block(
        items: [
          _item('Morning chants'),
          _item('Heart Sutra'),
          _item('Tara'),
          _item('Mani'),
        ],
      );
      expect(routineBlockDisplayTitle(block, en), 'Morning chants +3 more');
    });

    test('treats an empty title as untitled', () {
      final block = _block(title: '', items: [_item('Morning chants')]);
      expect(routineBlockDisplayTitle(block, en), 'Morning chants');
    });

    test('is null with neither a title nor items', () {
      expect(routineBlockDisplayTitle(_block(), en), isNull);
    });

    test('skips items with a blank label', () {
      final block = _block(
        items: [_item(''), _item('  '), _item('Heart Sutra')],
      );
      expect(routineBlockDisplayTitle(block, en), 'Heart Sutra +2 more');
    });

    test('is null when every item label is blank', () {
      final block = _block(
        items: [
          _item(''),
          // A timer without a positive duration falls back to its stored title.
          const RoutineItem(id: 't', title: '', type: RoutineItemType.timer),
        ],
      );
      expect(routineBlockDisplayTitle(block, en), isNull);
    });

    test('uses the localized timer label for a timer item', () {
      final block = _block(
        items: [
          const RoutineItem(
            id: 't',
            title: 'stored title',
            type: RoutineItemType.timer,
            durationMs: 10 * 60000,
          ),
          _item('Heart Sutra'),
        ],
      );
      expect(
        routineBlockDisplayTitle(block, en),
        '${en.timer_minute_session(10)} +1 more',
      );
    });
  });
}
