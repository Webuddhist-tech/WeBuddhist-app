import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/timer/presentation/utils/timer_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

void main() {
  late RecordingAnalyticsService service;
  late TimerAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = TimerAnalytics(service);
  });

  test('timerStarted carries the preset and its length in seconds', () {
    analytics.timerStarted(presetId: 't1', durationSeconds: 600);

    expect(service.eventNames, [AnalyticsEvents.timerStarted]);
    expect(service.events.single.properties, {
      'preset_id': 't1',
      'duration_s': 600,
    });
  });

  test('timerCompleted carries the pause count and backgrounding', () {
    analytics.timerCompleted(
      presetId: 't1',
      durationSeconds: 600,
      wasBackgrounded: true,
      pauseCount: 2,
    );

    expect(service.eventNames, [AnalyticsEvents.timerCompleted]);
    expect(service.events.single.properties, {
      'preset_id': 't1',
      'duration_s': 600,
      'was_backgrounded': true,
      'pause_count': 2,
    });
  });

  test('timerDiscarded carries elapsed seconds and progress', () {
    analytics.timerDiscarded(
      presetId: 't1',
      elapsedSeconds: 90,
      pctComplete: 15,
    );

    expect(service.eventNames, [AnalyticsEvents.timerDiscarded]);
    expect(service.events.single.properties, {
      'preset_id': 't1',
      'elapsed_s': 90,
      'pct_complete': 15,
    });
  });
}
