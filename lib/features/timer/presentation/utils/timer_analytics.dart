import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Product analytics for the meditation timer: one method per tracked action,
/// so the event names and their property keys live in one place. Every call
/// fires and forgets; callers fire once the session really changed state.
class TimerAnalytics {
  const TimerAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// The pre-roll countdown ran out and the main timer is running.
  void timerStarted({required String presetId, required int durationSeconds}) {
    _analytics.trackInBackground(AnalyticsEvents.timerStarted, {
      AnalyticsProperties.presetId: presetId,
      AnalyticsProperties.durationSeconds: durationSeconds,
    });
  }

  /// The session reached zero and the completion bell rang.
  void timerCompleted({
    required String presetId,
    required int durationSeconds,
    required bool wasBackgrounded,
    required int pauseCount,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.timerCompleted, {
      AnalyticsProperties.presetId: presetId,
      AnalyticsProperties.durationSeconds: durationSeconds,
      AnalyticsProperties.wasBackgrounded: wasBackgrounded,
      AnalyticsProperties.pauseCount: pauseCount,
    });
  }

  /// The user left the session before the bell. [pctComplete] is 0-100.
  void timerDiscarded({
    required String presetId,
    required int elapsedSeconds,
    required int pctComplete,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.timerDiscarded, {
      AnalyticsProperties.presetId: presetId,
      AnalyticsProperties.elapsedSeconds: elapsedSeconds,
      AnalyticsProperties.pctComplete: pctComplete,
    });
  }
}

final timerAnalyticsProvider = Provider<TimerAnalytics>((ref) {
  return TimerAnalytics(ref.watch(analyticsServiceProvider));
});
