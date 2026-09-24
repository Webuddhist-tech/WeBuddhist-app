import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/home/presentation/utils/series_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

void main() {
  late RecordingAnalyticsService service;
  late SeriesAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = SeriesAnalytics(service);
  });

  test('seriesViewed carries the series and its size', () {
    analytics.seriesViewed(
      seriesId: 's1',
      seriesTitle: 'Daily Tipitaka',
      planCount: 3,
      totalDays: 90,
    );

    expect(service.eventNames, [AnalyticsEvents.seriesViewed]);
    expect(service.events.single.properties, {
      'series_id': 's1',
      'series_title': 'Daily Tipitaka',
      'plan_count': 3,
      'total_days': 90,
    });
  });

  test('bookmark reports the state after the toggle', () {
    analytics.seriesBookmarked(seriesId: 's1', bookmarked: false);

    expect(service.eventNames, [AnalyticsEvents.seriesBookmarked]);
    expect(service.events.single.properties, {
      'series_id': 's1',
      'bookmarked': false,
    });
  });

  test('enrolment carries the group it went through', () {
    analytics.seriesEnrolled(seriesId: 's1', groupId: 'g1');
    analytics.seriesEnrolled(seriesId: 's2');
    analytics.seriesUnenrolled(seriesId: 's1');

    expect(service.eventNames, [
      AnalyticsEvents.seriesEnrolled,
      AnalyticsEvents.seriesEnrolled,
      AnalyticsEvents.seriesUnenrolled,
    ]);
    expect(service.events.first.properties, {
      'series_id': 's1',
      'group_id': 'g1',
    });
    expect(service.events[1].properties, {'series_id': 's2', 'group_id': null});
    expect(service.events.last.properties, {'series_id': 's1'});
  });

  test('routine intent and search fire their own events', () {
    analytics.seriesAddedToPractices(seriesId: 's1');
    analytics.seriesSearched(queryLength: 8, resultCount: 1);

    expect(service.eventNames, [
      AnalyticsEvents.seriesAddedToPractices,
      AnalyticsEvents.seriesSearched,
    ]);
    expect(service.events.last.properties, {
      'query_length': 8,
      'result_count': 1,
    });
  });
}
