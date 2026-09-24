import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

void main() {
  late RecordingAnalyticsService service;
  late ConnectAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = ConnectAnalytics(service);
  });

  test('tabViewed carries the sub-tab and the followed count', () {
    analytics.tabViewed(subTab: 'events', followedGroupCount: 3);

    expect(service.eventNames, [AnalyticsEvents.connectTabViewed]);
    expect(service.events.single.properties, {
      'sub_tab': 'events',
      'followed_group_count': 3,
    });
  });

  test('the followed count is null until my groups have loaded', () {
    analytics.tabViewed(subTab: 'feed', followedGroupCount: null);

    expect(service.events.single.properties, {
      'sub_tab': 'feed',
      'followed_group_count': null,
    });
    expect(service.groups, isEmpty);
  });
}
