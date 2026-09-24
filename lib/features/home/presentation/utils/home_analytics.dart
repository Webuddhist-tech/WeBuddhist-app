import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Product analytics for the Home tab. Every call fires and forgets.
class HomeAnalytics {
  const HomeAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// The Home tab was shown; [streakCurrent] is null until the streak loads.
  void homeViewed({
    required bool hasRoutine,
    required int? streakCurrent,
    required bool isGuest,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.homeViewed, {
      AnalyticsProperties.hasRoutine: hasRoutine,
      AnalyticsProperties.streakCurrent: streakCurrent,
      AnalyticsProperties.isGuest: isGuest,
    });
  }
}

final homeAnalyticsProvider = Provider<HomeAnalytics>((ref) {
  return HomeAnalytics(ref.watch(analyticsServiceProvider));
});
