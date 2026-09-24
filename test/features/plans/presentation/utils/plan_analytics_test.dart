import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/plans/presentation/utils/plan_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

UserTasksDto _task(List<String> contentTypes) => UserTasksDto(
  id: 't1',
  title: 'Read',
  estimatedTime: null,
  displayOrder: 1,
  isCompleted: false,
  subTasks: [
    for (final type in contentTypes)
      UserSubtasksDto(
        id: 's-$type',
        isCompleted: false,
        contentType: type,
        content: '',
      ),
  ],
);

void main() {
  late RecordingAnalyticsService service;
  late PlanAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = PlanAnalytics(service);
  });

  test('planPreviewed carries the plan and where it was opened from', () {
    analytics.planPreviewed(
      planId: 'p1',
      planName: 'Bodhisattva Challenge',
      totalDays: 21,
      source: PlanPreviewSource.series,
    );

    expect(service.eventNames, [AnalyticsEvents.planPreviewed]);
    expect(service.events.single.properties, {
      'plan_id': 'p1',
      'plan_name': 'Bodhisattva Challenge',
      'total_days': 21,
      'source': 'series',
    });
  });

  test('planEnrolled names the path; name and length only when known', () {
    analytics.planEnrolled(planId: 'p1', source: PlanSource.browse);
    analytics.planEnrolled(
      planId: 'p1',
      source: PlanSource.onboarding,
      planName: 'Plan',
      totalDays: 7,
    );

    expect(service.eventNames, [
      AnalyticsEvents.planEnrolled,
      AnalyticsEvents.planEnrolled,
    ]);
    expect(service.events.first.properties, {
      'plan_id': 'p1',
      'plan_name': null,
      'total_days': null,
      'source': 'browse',
    });
    expect(service.events.last.properties, {
      'plan_id': 'p1',
      'plan_name': 'Plan',
      'total_days': 7,
      'source': 'onboarding',
    });
  });

  test('planViewed carries enrolment and the route source when known', () {
    analytics.planViewed(
      planId: 'p1',
      planName: 'Plan',
      totalDays: 7,
      isEnrolled: true,
      source: PlanSource.event,
    );

    expect(service.eventNames, [AnalyticsEvents.planViewed]);
    expect(service.events.single.properties, {
      'plan_id': 'p1',
      'plan_name': 'Plan',
      'total_days': 7,
      'is_enrolled': true,
      'source': 'event',
    });
  });

  test('planDayViewed leaves is_missed open until status has loaded', () {
    analytics.planDayViewed(
      planId: 'p1',
      dayNumber: 3,
      isToday: true,
      isMissed: null,
    );
    analytics.planDayViewed(
      planId: 'p1',
      dayNumber: 2,
      isToday: false,
      isMissed: true,
    );

    expect(service.eventNames, [
      AnalyticsEvents.planDayViewed,
      AnalyticsEvents.planDayViewed,
    ]);
    expect(service.events.first.properties, {
      'plan_id': 'p1',
      'day_number': 3,
      'is_today': true,
      'is_missed': null,
    });
    expect(service.events.last.properties['is_missed'], isTrue);
  });

  test('a task toggle picks the event by its direction', () {
    analytics.planTaskToggled(
      planId: 'p1',
      dayNumber: 1,
      taskId: 't1',
      taskType: 'text',
      completed: true,
    );
    analytics.planTaskToggled(
      planId: 'p1',
      dayNumber: 1,
      taskId: 't1',
      taskType: 'text',
      completed: false,
    );

    expect(service.eventNames, [
      AnalyticsEvents.planTaskCompleted,
      AnalyticsEvents.planTaskUncompleted,
    ]);
    expect(service.events.first.properties, {
      'plan_id': 'p1',
      'day_number': 1,
      'task_id': 't1',
      'task_type': 'text',
    });
  });

  test('taskTypeOf is the shared subtask type, mixed when they differ', () {
    expect(PlanAnalytics.taskTypeOf(_task(['TEXT', 'TEXT'])), 'text');
    expect(
      PlanAnalytics.taskTypeOf(_task(['SOURCE_REFERENCE', 'VIDEO'])),
      'mixed',
    );
    expect(PlanAnalytics.taskTypeOf(_task([])), isNull);
  });

  test('day and plan completion carry their timing', () {
    analytics.planDayCompleted(
      planId: 'p1',
      planName: 'Plan',
      dayNumber: 7,
      totalDays: 7,
      completedDays: 7,
      isOnTime: true,
    );
    analytics.planCompleted(planId: 'p1', totalDays: 7, daysElapsed: 6);

    expect(service.eventNames, [
      AnalyticsEvents.planDayCompleted,
      AnalyticsEvents.planCompleted,
    ]);
    expect(service.events.first.properties, {
      'plan_id': 'p1',
      'plan_name': 'Plan',
      'day_number': 7,
      'total_days': 7,
      'completed_days': 7,
      'is_on_time': true,
    });
    expect(service.events.last.properties, {
      'plan_id': 'p1',
      'total_days': 7,
      'days_elapsed': 6,
    });
  });

  test('routine intent and unenroll name the plan', () {
    analytics.planAddedToPractices(planId: 'p1', planName: 'Plan');
    analytics.planUnenrolled(
      planId: 'p1',
      planName: 'Plan',
      daysCompleted: 2,
      daysSinceEnrolled: 5,
    );

    expect(service.eventNames, [
      AnalyticsEvents.planAddedToPractices,
      AnalyticsEvents.planUnenrolled,
    ]);
    expect(service.events.last.properties, {
      'plan_id': 'p1',
      'plan_name': 'Plan',
      'days_completed': 2,
      'days_since_enrolled': 5,
    });
  });

  test('planSearched carries the query length, never its text', () {
    analytics.planSearched(queryLength: 4, resultCount: 4);

    expect(service.events.single.properties, {
      'query_length': 4,
      'result_count': 4,
    });
  });
}
