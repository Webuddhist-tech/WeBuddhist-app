import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/home/presentation/utils/home_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

void main() {
  test('homeViewed carries routine, streak and guest state', () {
    final service = RecordingAnalyticsService();
    HomeAnalytics(service).homeViewed(
      hasRoutine: true,
      streakCurrent: null,
      isGuest: false,
    );

    expect(service.eventNames, [AnalyticsEvents.homeViewed]);
    expect(service.events.single.properties, {
      'has_routine': true,
      'streak_current': null,
      'is_guest': false,
    });
  });
}
