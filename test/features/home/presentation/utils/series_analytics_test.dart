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

  test('share, routine intent and search fire their own events', () {
    analytics.seriesShared(seriesId: 's1');
    analytics.seriesAddedToPractices(seriesId: 's1');
    analytics.seriesSearched(query: 'tipitaka', resultCount: 1);

    expect(service.eventNames, [
      AnalyticsEvents.seriesShared,
      AnalyticsEvents.seriesAddedToPractices,
      AnalyticsEvents.seriesSearched,
    ]);
    expect(service.events.last.properties, {
      'query': 'tipitaka',
      'result_count': 1,
    });
  });
}
