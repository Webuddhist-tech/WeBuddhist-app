import 'package:flutter_pecha/features/group_profile/data/models/group_event_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupEventAccumulations', () {
    GroupEventAccumulation row(
      String groupAccumulatorId,
      GroupEventParticipationType? format,
    ) => GroupEventAccumulation(
      id: 'row-$groupAccumulatorId',
      groupAccumulatorId: groupAccumulatorId,
      format: format,
    );

    const online = GroupEventParticipationType.online;
    const offline = GroupEventParticipationType.offline;

    test('primary sits last so it is next to the leaderboard', () {
      final rows = [row('a1', offline), row('a2', online), row('a3', online)];

      expect(rows.primary?.groupAccumulatorId, 'a2');
      expect(rows.displayRows.map((a) => a.groupAccumulatorId), [
        'a3',
        'a1',
        'a2',
      ]);
    });

    test('a first online primary keeps the plain reversed order', () {
      final rows = [row('a1', online), row('a2', offline), row('a3', offline)];

      expect(rows.displayRows.map((a) => a.groupAccumulatorId), [
        'a3',
        'a2',
        'a1',
      ]);
    });

    test('online wins over an accumulation without a format', () {
      final rows = [row('a1', null), row('a2', online)];

      expect(rows.primary?.groupAccumulatorId, 'a2');
    });

    test('rows sharing an accumulator id appear once each', () {
      final rows = [row('a1', online), row('a1', offline)];

      expect(rows.displayRows, hasLength(2));
      expect(identical(rows.displayRows.last, rows.first), isTrue);
    });
  });

  group('GroupEventModel youtube', () {
    test('parses youtube links and picks the first by display order', () {
      final event =
          GroupEventModel.fromJson({
            'id': 'e1',
            'group_id': 'g1',
            'youtube': [
              {
                'id': 'y2',
                'url': 'https://youtu.be/gs18skkubuI',
                'label': 'tibetan live',
                'language': 'BO',
                'display_order': 2,
              },
              {
                'id': 'y1',
                'url': 'https://youtu.be/BNDTusn8TO8',
                'label': 'live',
                'language': 'EN',
                'display_order': 1,
              },
            ],
          }).toEntity();

      expect(event.youtube.map((link) => link.id), ['y2', 'y1']);
      expect(event.youtube.first.language, 'BO');
      expect(event.liveYoutubeLink?.id, 'y1');
      expect(event.liveYoutubeLink?.url, 'https://youtu.be/BNDTusn8TO8');
    });

    test('skips youtube entries without a url', () {
      final event =
          GroupEventModel.fromJson({
            'id': 'e1',
            'group_id': 'g1',
            'youtube': [
              {'id': 'y1', 'url': '', 'display_order': 1},
              {'id': 'y2', 'url': 'https://youtu.be/gs18skkubuI'},
            ],
          }).toEntity();

      expect(event.liveYoutubeLink?.id, 'y2');
    });

    test('defaults to no youtube links', () {
      final event =
          GroupEventModel.fromJson({'id': 'e1', 'group_id': 'g1'}).toEntity();

      expect(event.youtube, isEmpty);
      expect(event.liveYoutubeLink, isNull);
    });

    test('keeps the language on regular links', () {
      final event =
          GroupEventModel.fromJson({
            'id': 'e1',
            'group_id': 'g1',
            'links': [
              {
                'id': 'l1',
                'type': 'zoom',
                'url': 'https://meet.google.com/abc',
                'language': 'EN',
              },
            ],
          }).toEntity();

      expect(event.links.single.language, 'EN');
    });
  });

  group('GroupEventModel participation', () {
    test('reads my_participation_type', () {
      final event =
          GroupEventModel.fromJson({
            'id': 'e1',
            'group_id': 'g1',
            'event_format': 'hybrid',
            'is_joined': true,
            'my_participation_type': 'offline',
          }).toEntity();

      expect(event.myParticipationType, GroupEventParticipationType.offline);
    });

    test('is undecided when the field is absent or unknown', () {
      final absent =
          GroupEventModel.fromJson({'id': 'e1', 'group_id': 'g1'}).toEntity();
      final unknown =
          GroupEventModel.fromJson({
            'id': 'e1',
            'group_id': 'g1',
            'my_participation_type': 'hybrid',
          }).toEntity();

      expect(absent.myParticipationType, isNull);
      expect(unknown.myParticipationType, isNull);
    });

    test('reads each participant participation_type', () {
      final page =
          GroupEventParticipantsPageModel.fromJson({
            'participants': [
              {'user_id': 'u1', 'participation_type': 'online'},
              {'user_id': 'u2'},
            ],
            'skip': 0,
            'limit': 20,
            'total': 2,
          }).toEntity();

      expect(page.participants.map((p) => p.participationType), [
        GroupEventParticipationType.online,
        null,
      ]);
    });
  });

  group('GroupEventModel prayer requests', () {
    test('reads the live prayer request count', () {
      final event =
          GroupEventModel.fromJson({
            'id': 'e1',
            'group_id': 'g1',
            'chat_enabled': true,
            'prayer_request_count': 12,
          }).toEntity();

      expect(event.chatEnabled, isTrue);
      expect(event.prayerRequestCount, 12);
    });

    test('defaults to zero when the field is absent', () {
      final event =
          GroupEventModel.fromJson({'id': 'e1', 'group_id': 'g1'}).toEntity();
      expect(event.prayerRequestCount, 0);
    });
  });

  group('GroupEventModel accumulations', () {
    test('sorts accumulations by display order and keeps their format', () {
      final event =
          GroupEventModel.fromJson({
            'id': 'e1',
            'group_id': 'g1',
            'group_accumulator_id': 'a2',
            'group_accumulator': {'id': 'a2', 'name': 'Good deeds'},
            'accumulations': [
              {
                'id': 'row2',
                'group_accumulator_id': 'a2',
                'event_format': 'offline',
                'display_order': 2,
                'group_accumulator': {'id': 'a2', 'name': 'Good deeds'},
              },
              {
                'id': 'row1',
                'group_accumulator_id': 'a1',
                'event_format': 'online',
                'display_order': 1,
                'group_accumulator': {'id': 'a1', 'name': 'Health'},
              },
            ],
          }).toEntity();

      expect(event.allAccumulations.map((a) => a.groupAccumulatorId), [
        'a1',
        'a2',
      ]);
      expect(event.allAccumulations.first.groupAccumulator?.name, 'Health');
      expect(
        event.allAccumulations.first.format,
        GroupEventParticipationType.online,
      );
      expect(
        event.allAccumulations.last.format,
        GroupEventParticipationType.offline,
      );
    });

    test('the first online accumulation is primary whatever its order', () {
      final event =
          GroupEventModel.fromJson({
            'id': 'e1',
            'group_id': 'g1',
            'accumulations': [
              {
                'id': 'row1',
                'group_accumulator_id': 'a1',
                'event_format': 'offline',
                'display_order': 1,
              },
              {
                'id': 'row2',
                'group_accumulator_id': 'a2',
                'event_format': 'online',
                'display_order': 2,
              },
              {
                'id': 'row3',
                'group_accumulator_id': 'a3',
                'event_format': 'online',
                'display_order': 3,
              },
            ],
          }).toEntity();

      expect(event.allAccumulations.map((a) => a.groupAccumulatorId), [
        'a1',
        'a2',
        'a3',
      ]);
      expect(event.primaryAccumulation?.groupAccumulatorId, 'a2');
    });

    test('all in-person accumulations have no primary', () {
      final event =
          GroupEventModel.fromJson({
            'id': 'e1',
            'group_id': 'g1',
            'accumulations': [
              {
                'id': 'row2',
                'group_accumulator_id': 'a2',
                'event_format': 'offline',
                'display_order': 2,
              },
              {
                'id': 'row1',
                'group_accumulator_id': 'a1',
                'event_format': 'offline',
                'display_order': 1,
              },
            ],
          }).toEntity();

      expect(event.primaryAccumulation, isNull);
      expect(
        event.allAccumulations.displayRows.map((a) => a.groupAccumulatorId),
        ['a2', 'a1'],
      );
    });

    test('falls back to the single group_accumulator', () {
      final event =
          GroupEventModel.fromJson({
            'id': 'e1',
            'group_id': 'g1',
            'group_accumulator_id': 'a1',
            'group_accumulator': {'id': 'a1', 'name': 'Good deeds'},
          }).toEntity();

      expect(event.accumulations, isEmpty);
      expect(event.allAccumulations.single.groupAccumulatorId, 'a1');
      expect(event.allAccumulations.single.format, isNull);
      expect(event.primaryAccumulation?.groupAccumulatorId, 'a1');
    });

    test('has no accumulation when the event carries none', () {
      final event =
          GroupEventModel.fromJson({'id': 'e1', 'group_id': 'g1'}).toEntity();

      expect(event.allAccumulations, isEmpty);
      expect(event.primaryAccumulation, isNull);
    });
  });
}
