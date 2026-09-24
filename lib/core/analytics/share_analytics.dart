import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// What was shared, carried on `content_shared` as `surface`.
enum ShareSurface {
  verse,
  streak,
  plan,
  planDay,
  poem,
  segment,
  text,
  group,
  event,
  series,
  timer,
  app;

  String get key => switch (this) {
    ShareSurface.planDay => 'plan_day',
    _ => name,
  };
}

/// One event for every share sheet in the app; the per-surface funnels are
/// filters on `surface`.
class ShareAnalytics {
  const ShareAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// Only a confirmed share counts. Android 23+ and iOS 15+ (the app's
  /// floors) always report a result, so `unavailable` never happens here and
  /// is treated as not shared rather than guessed at.
  static bool wasUsed(ShareResult result) =>
      result.status == ShareResultStatus.success;

  void contentShared({
    required ShareSurface surface,
    String? targetId,
    String? format,
    String? method,
    String? groupId,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.contentShared, {
      AnalyticsProperties.surface: surface.key,
      AnalyticsProperties.targetId: targetId,
      AnalyticsProperties.format: format,
      AnalyticsProperties.method: method,
      AnalyticsProperties.groupId: groupId,
    });
  }
}

final shareAnalyticsProvider = Provider<ShareAnalytics>((ref) {
  return ShareAnalytics(ref.watch(analyticsServiceProvider));
});
