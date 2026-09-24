import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where a plan preview was opened from, carried on `plan_previewed`.
enum PlanPreviewSource { catalog, series, event }

/// Product analytics for plans: one method per tracked action, so the event
/// names and their property keys live in one place. Every call fires and
/// forgets; callers fire after the server confirms, never optimistically.
class PlanAnalytics {
  const PlanAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// An unenrolled plan was opened for preview.
  void planPreviewed({
    required String planId,
    required String planName,
    required int totalDays,
    required PlanPreviewSource source,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.planPreviewed, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.planName: planName,
      AnalyticsProperties.totalDays: totalDays,
      AnalyticsProperties.source: source.name,
    });
  }

  /// The user chose to add the plan to their routine; enrollment itself
  /// happens when that routine is saved.
  void planAddedToPractices({
    required String planId,
    required String planName,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.planAddedToPractices, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.planName: planName,
    });
  }

  void planUnenrolled({required String planId, required String planName}) {
    _analytics.trackInBackground(AnalyticsEvents.planUnenrolled, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.planName: planName,
    });
  }

  void planDayShared({required String planId, required int dayNumber}) {
    _analytics.trackInBackground(AnalyticsEvents.planDayShared, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.dayNumber: dayNumber,
    });
  }

  /// A debounced catalog search returned its first page.
  void planSearched({required String query, required int resultCount}) {
    _analytics.trackInBackground(AnalyticsEvents.planSearched, {
      AnalyticsProperties.query: query,
      AnalyticsProperties.resultCount: resultCount,
    });
  }
}

final planAnalyticsProvider = Provider<PlanAnalytics>((ref) {
  return PlanAnalytics(ref.watch(analyticsServiceProvider));
});
