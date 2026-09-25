import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Product analytics for the Connect tab: one method per tracked action, so
/// the event names and their property keys live in one place. Every call
/// fires and forgets; callers fire once the tab really is on screen.
class ConnectAnalytics {
  const ConnectAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// A Connect sub-tab settled on screen; [followedGroupCount] only when the
  /// my-groups provider already holds it.
  void tabViewed({required String subTab, required int? followedGroupCount}) {
    _analytics.trackInBackground(AnalyticsEvents.connectTabViewed, {
      AnalyticsProperties.subTab: subTab,
      AnalyticsProperties.followedGroupCount: followedGroupCount,
    });
  }
}

final connectAnalyticsProvider = Provider<ConnectAnalytics>((ref) {
  return ConnectAnalytics(ref.watch(analyticsServiceProvider));
});
