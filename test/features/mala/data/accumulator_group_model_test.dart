import 'package:flutter_pecha/features/mala/data/models/accumulator_group_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses an event-linked accumulation with both totals', () {
    final group =
        AccumulatorGroupModel.fromJson({
          'group_accumulator_id': 'ga-1',
          'group_id': 'g-1',
          'title': 'Tara praises',
          'group_name': 'Light Of Buddhadharma Foundation International',
          'event_title': 'The praise to the twenty-one Tara',
          'image': {
            'thumbnail': 'https://example.com/t.webp',
            'medium': 'https://example.com/m.webp',
            'original': 'https://example.com/o.webp',
          },
          'target_count': 100000,
          'user_total_count': 23,
          'group_total_count': 423,
          'is_joined': true,
          'start_date': '2026-09-01T00:00:00Z',
          'end_date': '2026-09-21T00:00:00Z',
          'created_at': '2026-08-20T00:00:00Z',
        }).toEntity();

    expect(group.groupAccumulatorId, 'ga-1');
    expect(group.groupId, 'g-1');
    expect(group.title, 'Tara praises');
    expect(group.groupName, 'Light Of Buddhadharma Foundation International');
    expect(group.eventTitle, 'The praise to the twenty-one Tara');
    expect(group.image?.thumbnail, 'https://example.com/t.webp');
    expect(group.userTotalCount, 23);
    expect(group.groupTotalCount, 423);
    expect(group.isJoined, isTrue);
  });

  test('a plain group accumulation has no event title', () {
    final group =
        AccumulatorGroupModel.fromJson({
          'group_accumulator_id': 'ga-2',
          'group_id': 'g-2',
          'title': 'Green Tara mantra',
          'group_name': 'WeBuddhist',
          'event_title': null,
          'image': null,
          'user_total_count': 6,
          'group_total_count': 189,
          'is_joined': true,
        }).toEntity();

    expect(group.eventTitle, isNull);
    expect(group.groupName, 'WeBuddhist');
    expect(group.image, isNull);
  });

  test('a payload from before the totals shipped still parses', () {
    final group =
        AccumulatorGroupModel.fromJson({
          'group_accumulator_id': 'ga-3',
          'group_id': 'g-3',
          'user_total_count': 12,
          'is_joined': true,
        }).toEntity();

    expect(group.title, isNull);
    expect(group.groupName, isNull);
    expect(group.eventTitle, isNull);
    expect(group.userTotalCount, 12);
    expect(group.groupTotalCount, 0);
  });

  test('missing counts and membership fall back to zero and not joined', () {
    final group =
        AccumulatorGroupModel.fromJson({
          'group_accumulator_id': 'ga-4',
          'group_id': 'g-4',
        }).toEntity();

    expect(group.userTotalCount, 0);
    expect(group.groupTotalCount, 0);
    expect(group.isJoined, isFalse);
  });

  test('the response keeps the order the API returned', () {
    final response = AccumulatorGroupsResponseModel.fromJson({
      'groups': [
        {'group_accumulator_id': 'ga-1', 'group_id': 'g-1'},
        {'group_accumulator_id': 'ga-2', 'group_id': 'g-2'},
      ],
      'total': 2,
      'skip': 0,
      'limit': 20,
    });

    expect(response.groups.map((g) => g.groupAccumulatorId), ['ga-1', 'ga-2']);
    expect(response.total, 2);
  });
}
