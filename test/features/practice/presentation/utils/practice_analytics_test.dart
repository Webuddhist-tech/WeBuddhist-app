import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/utils/practice_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

RoutineItem _item(String id, RoutineItemType type) =>
    RoutineItem(id: id, title: id, type: type);

void main() {
  late RecordingAnalyticsService service;
  late PracticeAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = PracticeAnalytics(service);
  });

  test('item types map to the tracking plan keys', () {
    expect(PracticeAnalytics.itemTypeKey(RoutineItemType.plan), 'plan');
    expect(PracticeAnalytics.itemTypeKey(RoutineItemType.accumulator), 'mala');
    expect(
      PracticeAnalytics.itemTypeKey(RoutineItemType.groupAccumulator),
      'group_practice',
    );
    expect(
      PracticeAnalytics.itemTypeKey(RoutineItemType.groupRecitationCollection),
      'group_practice',
    );
    expect(
      PracticeAnalytics.itemTypeKey(RoutineItemType.myRecitationCollection),
      'recitation_collection',
    );
  });

  test('minutes from block time are signed', () {
    final now = DateTime(2026, 9, 24, 7, 30);
    expect(
      PracticeAnalytics.minutesFromBlockTime(
        const TimeOfDay(hour: 7, minute: 0),
        now,
      ),
      30,
    );
    expect(
      PracticeAnalytics.minutesFromBlockTime(
        const TimeOfDay(hour: 21, minute: 0),
        now,
      ),
      -810,
    );
  });

  test('routineItemOpened carries the item, its block and the offset', () {
    analytics.routineItemOpened(
      item: _item('m1', RoutineItemType.accumulator),
      blockIndex: 2,
      blockTime: const TimeOfDay(hour: 6, minute: 15),
      now: DateTime(2026, 9, 24, 6, 20),
    );

    expect(service.eventNames, [AnalyticsEvents.routineItemOpened]);
    expect(service.events.single.properties, {
      'item_type': 'mala',
      'item_id': 'm1',
      'block_index': 2,
      'minutes_from_block_time': 5,
    });
  });

  test('routineSaved summarises blocks, distinct types and reminders', () {
    final data = RoutineData(
      blocks: [
        RoutineBlock(
          time: const TimeOfDay(hour: 20, minute: 0),
          notificationEnabled: false,
          items: [
            _item('p1', RoutineItemType.plan),
            _item('r1', RoutineItemType.recitation),
          ],
        ),
        RoutineBlock(
          time: const TimeOfDay(hour: 6, minute: 30),
          items: [
            _item('p2', RoutineItemType.plan),
            _item('g1', RoutineItemType.groupAccumulator),
          ],
        ),
      ],
    );

    analytics.routineSaved(data);

    expect(service.eventNames, [AnalyticsEvents.routineSaved]);
    expect(service.events.single.properties, {
      'block_count': 2,
      'item_count': 4,
      'session_types': ['plan', 'recitation', 'group_practice'],
      'reminder_enabled': true,
      'earliest_block_hour': 6,
    });
  });

  test('routineSaved on an empty routine has no earliest hour', () {
    analytics.routineSaved(const RoutineData());

    expect(service.events.single.properties, {
      'block_count': 0,
      'item_count': 0,
      'session_types': <String>[],
      'reminder_enabled': false,
      'earliest_block_hour': null,
    });
  });

  test('enrolments from a routine save carry source routine', () {
    analytics.planEnrolledFromRoutine(
      planId: 'p1',
      planName: 'Lojong',
      totalDays: 21,
    );
    analytics.seriesEnrolledFromRoutine(seriesId: 's1');

    expect(service.eventNames, [
      AnalyticsEvents.planEnrolled,
      AnalyticsEvents.seriesEnrolled,
    ]);
    expect(service.events.first.properties, {
      'plan_id': 'p1',
      'plan_name': 'Lojong',
      'total_days': 21,
      'source': 'routine',
    });
    expect(service.events.last.properties, {
      'series_id': 's1',
      'source': 'routine',
    });
  });
}
