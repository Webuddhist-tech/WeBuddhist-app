import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What changed the content language, carried on `content_language_changed`.
/// `reconcile` is the backend kill switch replacing a disabled language.
enum ContentLanguageSource { settings, onboarding, reconcile }

/// Fires once the new code is persisted, never for re-selecting the current
/// one.
class ContentLanguageAnalytics {
  const ContentLanguageAnalytics(this._analytics);

  final AnalyticsService _analytics;

  void contentLanguageChanged({
    required String from,
    required String to,
    ContentLanguageSource? source,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.contentLanguageChanged, {
      AnalyticsProperties.from: from,
      AnalyticsProperties.to: to,
      AnalyticsProperties.source: source?.name,
    });
  }
}

final contentLanguageAnalyticsProvider = Provider<ContentLanguageAnalytics>((
  ref,
) {
  return ContentLanguageAnalytics(ref.watch(analyticsServiceProvider));
});
