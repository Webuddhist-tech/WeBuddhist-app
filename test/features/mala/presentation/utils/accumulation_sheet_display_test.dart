import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/presentation/utils/accumulation_sheet_display.dart';
import 'package:flutter_test/flutter_test.dart';

AccumulatorGroup _group(
  String id, {
  String? title,
  String? groupName,
  String? eventTitle,
  int userTotalCount = 0,
  int groupTotalCount = 0,
}) => AccumulatorGroup(
  groupAccumulatorId: id,
  groupId: 'group-$id',
  title: title,
  groupName: groupName,
  eventTitle: eventTitle,
  userTotalCount: userTotalCount,
  groupTotalCount: groupTotalCount,
  isJoined: true,
);

void main() {
  group('splitAccumulationSections', () {
    test('event-linked rows go to events, the rest to groups', () {
      final sections = splitAccumulationSections([
        _group('a', eventTitle: 'Tara event'),
        _group('b', title: 'Green Tara mantra'),
        _group('c', eventTitle: '100k prayer'),
      ]);

      expect(sections.events.map((g) => g.groupAccumulatorId), ['a', 'c']);
      expect(sections.groups.map((g) => g.groupAccumulatorId), ['b']);
    });

    test('a blank event title does not make an event row', () {
      final sections = splitAccumulationSections([
        _group('a', title: 'Mani', eventTitle: '   '),
      ]);

      expect(sections.events, isEmpty);
      expect(sections.groups, hasLength(1));
    });

    test('no accumulations gives two empty sections', () {
      final sections = splitAccumulationSections(const []);

      expect(sections.events, isEmpty);
      expect(sections.groups, isEmpty);
    });
  });

  group('accumulationRowTitle', () {
    test('an event row is titled by its event', () {
      final row = _group('a', title: 'Tara praises', eventTitle: ' Tara event ');

      expect(accumulationRowTitle(row), 'Tara event');
    });

    test('a plain row is titled by the accumulation', () {
      expect(
        accumulationRowTitle(_group('a', title: 'Green Tara mantra')),
        'Green Tara mantra',
      );
    });

    test('no title at all is null so the caller shows its placeholder', () {
      expect(accumulationRowTitle(_group('a', title: ' ')), isNull);
    });
  });

  group('accumulationRowSubtitle', () {
    test('is the trimmed group name', () {
      expect(
        accumulationRowSubtitle(_group('a', groupName: ' WeBuddhist ')),
        'WeBuddhist',
      );
    });

    test('is null when the group has no name', () {
      expect(accumulationRowSubtitle(_group('a')), isNull);
      expect(accumulationRowSubtitle(_group('a', groupName: '')), isNull);
    });
  });

  group('allTimeAccumulation', () {
    test('adds personal practice and every accumulation', () {
      expect(
        allTimeAccumulation(personalLifetime: 143, myGroupLifetimes: [23, 50]),
        216,
      );
    });

    test('is the personal total when nothing is joined', () {
      expect(
        allTimeAccumulation(personalLifetime: 227, myGroupLifetimes: const []),
        227,
      );
    });
  });

  group('groupTotalWithUnsynced', () {
    test('is the API total when everything is synced', () {
      expect(
        groupTotalWithUnsynced(
          apiGroupTotal: 423,
          apiMyTotal: 23,
          displayMyTotal: 23,
        ),
        423,
      );
    });

    test('adds taps that have not reached the server yet', () {
      expect(
        groupTotalWithUnsynced(
          apiGroupTotal: 423,
          apiMyTotal: 23,
          displayMyTotal: 28,
        ),
        428,
      );
    });

    test('never drops below the API total', () {
      expect(
        groupTotalWithUnsynced(
          apiGroupTotal: 423,
          apiMyTotal: 23,
          displayMyTotal: 20,
        ),
        423,
      );
    });

    test('is never less than my own total', () {
      expect(
        groupTotalWithUnsynced(
          apiGroupTotal: 0,
          apiMyTotal: 6,
          displayMyTotal: 6,
        ),
        6,
      );
    });
  });
}
