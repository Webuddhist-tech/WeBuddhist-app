import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/plans/presentation/utils/plan_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

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

  test('routine intent, unenroll and share name the plan', () {
    analytics.planAddedToPractices(planId: 'p1', planName: 'Plan');
    analytics.planUnenrolled(planId: 'p1', planName: 'Plan');
    analytics.planDayShared(planId: 'p1', dayNumber: 3);

    expect(service.eventNames, [
      AnalyticsEvents.planAddedToPractices,
      AnalyticsEvents.planUnenrolled,
      AnalyticsEvents.planDayShared,
    ]);
    expect(service.events.last.properties, {'plan_id': 'p1', 'day_number': 3});
  });

  test('planSearched carries the query and the result count', () {
    analytics.planSearched(query: 'tara', resultCount: 4);

    expect(service.events.single.properties, {
      'query': 'tara',
      'result_count': 4,
    });
  });
}
