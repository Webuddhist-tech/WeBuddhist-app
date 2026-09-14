import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_api_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionType.fromJson', () {
    test('parses PLAN as a first-class plan session', () {
      expect(SessionType.fromJson('PLAN'), SessionType.plan);
      expect(SessionType.fromJson('plan'), SessionType.plan);
    });

    test('parses SERIES independently of PLAN', () {
      expect(SessionType.fromJson('SERIES'), SessionType.series);
    });

    test('parses GROUP_ACCUMULATOR as its own session type', () {
      expect(
        SessionType.fromJson('GROUP_ACCUMULATOR'),
        SessionType.groupAccumulator,
      );
      expect(SessionType.groupAccumulator.toJson(), 'GROUP_ACCUMULATOR');
    });
  });

  group('GROUP_ACCUMULATOR sessions', () {
    test('reads group_accumulator_id as the source id and keeps the image', () {
      final session = SessionDTO.fromJson({
        'id': 'session-ga',
        'session_type': 'GROUP_ACCUMULATOR',
        'group_accumulator_id': 'ga-1',
        'title': 'Group Mani',
        'image': {
          'thumbnail': 'https://img/thumb.jpg',
          'medium': 'https://img/medium.jpg',
          'original': 'https://img/original.jpg',
        },
        'display_order': 0,
      });

      final item = routineItemFromSessionDto(session);

      expect(session.sessionType, SessionType.groupAccumulator);
      expect(session.sourceId, 'ga-1');
      expect(item.id, 'ga-1');
      expect(item.title, 'Group Mani');
      expect(item.type, RoutineItemType.groupAccumulator);
      expect(item.coverImage?.thumbnail, 'https://img/thumb.jpg');
    });

    test('writes group_accumulator_id instead of source_id', () {
      final block = RoutineBlock(
        time: const TimeOfDay(hour: 8, minute: 0),
        items: const [
          RoutineItem(
            id: 'ga-1',
            title: 'Group Mani',
            type: RoutineItemType.groupAccumulator,
          ),
        ],
      );

      final sessions = routineBlockToRequest(block).toJson()['sessions'] as List;

      expect(sessions.single, {
        'session_type': 'GROUP_ACCUMULATOR',
        'group_accumulator_id': 'ga-1',
        'display_order': 0,
      });
    });

    test('survives a local persistence round trip', () {
      const item = RoutineItem(
        id: 'ga-1',
        title: 'Group Mani',
        type: RoutineItemType.groupAccumulator,
      );

      final restored = RoutineItem.fromJson(item.toJson());

      expect(restored.type, RoutineItemType.groupAccumulator);
      expect(restored.id, 'ga-1');
    });
  });

  group('routineItemFromSessionDto', () {
    test('maps a PLAN session onto RoutineItemType.plan', () {
      const inputSession = SessionDTO(
        id: 'session-1',
        sessionType: SessionType.plan,
        sourceId: 'plan-1',
        title: 'Lojong',
        language: 'en',
        displayOrder: 0,
      );

      final actualItem = routineItemFromSessionDto(inputSession);

      expect(actualItem.id, 'plan-1');
      expect(actualItem.type, RoutineItemType.plan);
      expect(actualItem.currentPlanId, 'plan-1');
    });

    test('uses sourceId when PLAN currentPlanId is empty', () {
      const inputSession = SessionDTO(
        id: 'session-1',
        sessionType: SessionType.plan,
        sourceId: 'plan-1',
        title: 'Lojong',
        language: '',
        displayOrder: 0,
        currentPlanId: '',
      );

      final actualItem = routineItemFromSessionDto(inputSession);

      expect(actualItem.language, isNull);
      expect(actualItem.currentPlanId, 'plan-1');
    });
  });

  group('routineBlockToRequest', () {
    test('writes PLAN for standalone plan items', () {
      final inputBlock = RoutineBlock(
        time: const TimeOfDay(hour: 7, minute: 30),
        items: const [
          RoutineItem(
            id: 'plan-1',
            title: 'Lojong',
            type: RoutineItemType.plan,
          ),
        ],
      );

      final actualRequest = routineBlockToRequest(inputBlock);

      expect(actualRequest.sessions, hasLength(1));
      expect(actualRequest.sessions.first.sessionType, SessionType.plan);
      expect(actualRequest.sessions.first.sourceId, 'plan-1');
      expect(actualRequest.toJson()['sessions'], [
        {
          'session_type': 'PLAN',
          'source_id': 'plan-1',
          'display_order': 0,
        },
      ]);
    });

    test('keeps series, recitation, timer, and mala payloads unchanged', () {
      final inputBlock = RoutineBlock(
        time: const TimeOfDay(hour: 8, minute: 0),
        items: const [
          RoutineItem(
            id: 'series-1',
            title: 'Ngondro',
            type: RoutineItemType.series,
          ),
          RoutineItem(
            id: 'text-1',
            title: 'Heart Sutra',
            type: RoutineItemType.recitation,
          ),
          RoutineItem(
            id: 'timer-1',
            title: '',
            type: RoutineItemType.timer,
            durationMs: 600000,
          ),
          RoutineItem(
            id: 'preset-1',
            title: 'Om Mani',
            type: RoutineItemType.accumulator,
          ),
          RoutineItem(
            id: 'collection-1',
            title: 'Daily Chants',
            type: RoutineItemType.myRecitationCollection,
            itemCount: 3,
          ),
        ],
      );

      final actualSessions = routineBlockToRequest(inputBlock).toJson()['sessions'];

      expect(actualSessions, [
        {
          'session_type': 'SERIES',
          'source_id': 'series-1',
          'display_order': 0,
        },
        {
          'session_type': 'RECITATION',
          'source_id': 'text-1',
          'display_order': 1,
        },
        {
          'session_type': 'TIMER',
          'display_order': 2,
          'duration_ms': 600000,
        },
        {
          'session_type': 'ACCUMULATOR',
          'accumulator_id': 'preset-1',
          'display_order': 3,
        },
        {
          'session_type': 'RECITATION_COLLECTION',
          'source_id': 'collection-1',
          'display_order': 4,
        },
      ]);
    });
  });

  group('unknown session types', () {
    test('parses instead of throwing, so one bad row cannot blank a routine', () {
      final session = SessionDTO.fromJson({
        'id': 'session-future',
        'session_type': 'SOMETHING_THE_FUTURE_ADDED',
        'source_id': 'source-1',
        'title': 'From a newer app version',
        'language': 'en',
        'display_order': 0,
      });

      expect(session.sessionType, SessionType.unknown);
      expect(session.rawSessionType, 'SOMETHING_THE_FUTURE_ADDED');
      expect(
        routineItemFromSessionDto(session).type,
        RoutineItemType.unknown,
      );
    });

    test('round-trips its wire value, so re-syncing never deletes it', () {
      // A time-block PUT replaces every session in the block, so an unknown
      // session has to be echoed back exactly as it arrived.
      final session = SessionDTO.fromJson({
        'id': 'session-future',
        'session_type': 'SOMETHING_THE_FUTURE_ADDED',
        'source_id': 'source-1',
        'title': 'From a newer app version',
        'language': 'en',
        'display_order': 0,
      });

      final block = RoutineBlock(
        time: const TimeOfDay(hour: 6, minute: 0),
        items: [routineItemFromSessionDto(session)],
      );

      final sessions = routineBlockToRequest(block).toJson()['sessions'] as List;

      expect(sessions.single, {
        'session_type': 'SOMETHING_THE_FUTURE_ADDED',
        'source_id': 'source-1',
        'display_order': 0,
      });
    });

    test('survives a local persistence round trip', () {
      final item = routineItemFromSessionDto(
        SessionDTO.fromJson({
          'id': 'session-future',
          'session_type': 'SOMETHING_THE_FUTURE_ADDED',
          'source_id': 'source-1',
          'title': 'From a newer app version',
          'language': 'en',
          'display_order': 0,
        }),
      );

      final restored = RoutineItem.fromJson(item.toJson());

      expect(restored.type, RoutineItemType.unknown);
      expect(restored.rawSessionType, 'SOMETHING_THE_FUTURE_ADDED');
    });
  });

  group('routineItemFromSessionDto existing types', () {
    test('maps SERIES, RECITATION, TIMER, and ACCUMULATOR independently of PLAN', () {
        expect(
          routineItemFromSessionDto(
            const SessionDTO(
              id: 's1',
              sessionType: SessionType.series,
              sourceId: 'series-1',
              title: 'Ngondro',
              language: 'en',
              displayOrder: 0,
            ),
          ).type,
          RoutineItemType.series,
        );
        expect(
          routineItemFromSessionDto(
            const SessionDTO(
              id: 's2',
              sessionType: SessionType.recitation,
              sourceId: 'text-1',
              title: 'Heart Sutra',
              language: 'en',
              displayOrder: 1,
            ),
          ).type,
          RoutineItemType.recitation,
        );
        expect(
          routineItemFromSessionDto(
            const SessionDTO(
              id: 's3',
              sessionType: SessionType.timer,
              sourceId: 'timer-1',
              title: '',
              language: 'en',
              displayOrder: 2,
              durationMs: 600000,
            ),
          ).type,
          RoutineItemType.timer,
        );
        expect(
          routineItemFromSessionDto(
            const SessionDTO(
              id: 's4',
              sessionType: SessionType.accumulator,
              sourceId: 'preset-1',
              title: 'Om Mani',
              language: 'en',
              displayOrder: 3,
            ),
          ).type,
          RoutineItemType.accumulator,
        );
        expect(
          routineItemFromSessionDto(
            const SessionDTO(
              id: 's5',
              sessionType: SessionType.recitationCollection,
              sourceId: 'collection-1',
              title: 'Daily Chants',
              language: 'en',
              displayOrder: 4,
            ),
          ).type,
          RoutineItemType.myRecitationCollection,
        );
      },
    );

    test('parses RECITATION_COLLECTION as a personal collection session', () {
      final session = SessionDTO.fromJson({
        'id': 'session-collection',
        'session_type': 'RECITATION_COLLECTION',
        'source_id': 'collection-1',
        'title': 'Daily Chants',
        'language': 'en',
        'display_order': 0,
        'item_count': 3,
      });

      final item = routineItemFromSessionDto(session);

      expect(session.sessionType, SessionType.recitationCollection);
      expect(item.id, 'collection-1');
      expect(item.title, 'Daily Chants');
      expect(item.type, RoutineItemType.myRecitationCollection);
      expect(item.itemCount, 3);
    });
  });

  group('time block title', () {
    TimeBlockDTO dto(String? title) => TimeBlockDTO.fromJson({
      'id': 'tb-1',
      'time': '20:00',
      'time_int': 2000,
      if (title != null) 'title': title,
      'notification_enabled': true,
      'sessions': const [],
    });

    test('carries the API title onto the block', () {
      expect(routineBlockFromDto(dto('Vesak Day Practice')).title,
          'Vesak Day Practice');
    });

    test('treats a missing or blank API title as unset', () {
      expect(routineBlockFromDto(dto(null)).title, isNull);
      expect(routineBlockFromDto(dto('   ')).title, isNull);
    });

    test('sends the title on create/update and omits it when unset', () {
      final titled = RoutineBlock(
        time: const TimeOfDay(hour: 20, minute: 0),
        title: 'Vesak Day Practice',
      );
      final untitled = RoutineBlock(time: const TimeOfDay(hour: 20, minute: 0));

      expect(routineBlockToRequest(titled).toJson()['title'],
          'Vesak Day Practice');
      expect(routineBlockToRequest(untitled).toJson(), isNot(contains('title')));
    });

    test('survives a local persistence round trip', () {
      final block = RoutineBlock(
        time: const TimeOfDay(hour: 20, minute: 0),
        title: 'Vesak Day Practice',
      );

      expect(RoutineBlock.fromJson(block.toJson()).title, 'Vesak Day Practice');
    });

    test('normalizeTitle trims and collapses blanks to null', () {
      expect(RoutineBlock.normalizeTitle('  Evening  '), 'Evening');
      expect(RoutineBlock.normalizeTitle('   '), isNull);
      expect(RoutineBlock.normalizeTitle(''), isNull);
      expect(RoutineBlock.normalizeTitle(null), isNull);
    });
  });
}
