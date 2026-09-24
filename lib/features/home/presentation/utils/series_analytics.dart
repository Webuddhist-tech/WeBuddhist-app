import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Product analytics for series: one method per tracked action, so the event
/// names and their property keys live in one place. Every call fires and
/// forgets; callers fire after the server confirms, never optimistically.
class SeriesAnalytics {
  const SeriesAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// The series detail screen showed a series; fired once per visit.
  void seriesViewed({
    required String seriesId,
    required String seriesTitle,
    required int planCount,
    required int totalDays,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.seriesViewed, {
      AnalyticsProperties.seriesId: seriesId,
      AnalyticsProperties.seriesTitle: seriesTitle,
      AnalyticsProperties.planCount: planCount,
      AnalyticsProperties.totalDays: totalDays,
    });
  }

  void seriesShared({required String seriesId}) {
    _analytics.trackInBackground(AnalyticsEvents.seriesShared, {
      AnalyticsProperties.seriesId: seriesId,
    });
  }

  /// [bookmarked] is the state after the toggle.
  void seriesBookmarked({required String seriesId, required bool bookmarked}) {
    _analytics.trackInBackground(AnalyticsEvents.seriesBookmarked, {
      AnalyticsProperties.seriesId: seriesId,
      AnalyticsProperties.bookmarked: bookmarked,
    });
  }

  /// The user chose to add the series to their routine; enrollment itself
  /// happens when that routine is saved.
  void seriesAddedToPractices({required String seriesId}) {
    _analytics.trackInBackground(AnalyticsEvents.seriesAddedToPractices, {
      AnalyticsProperties.seriesId: seriesId,
    });
  }

  /// A debounced series search returned.
  void seriesSearched({required String query, required int resultCount}) {
    _analytics.trackInBackground(AnalyticsEvents.seriesSearched, {
      AnalyticsProperties.query: query,
      AnalyticsProperties.resultCount: resultCount,
    });
  }
}

final seriesAnalyticsProvider = Provider<SeriesAnalytics>((ref) {
  return SeriesAnalytics(ref.watch(analyticsServiceProvider));
});
