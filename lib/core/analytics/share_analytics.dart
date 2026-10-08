import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
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
  app,
  post,
  accumulator,
  recitationCollection,
  mala;

  String get key => switch (this) {
    ShareSurface.planDay => 'plan_day',
    ShareSurface.recitationCollection => 'recitation_collection',
    _ => name,
  };
}

/// One event for every share sheet in the app; the per-surface funnels are
/// filters on `surface`, and `language` splits them by content language.
class ShareAnalytics {
  const ShareAnalytics(this._analytics, {String? Function()? contentLanguage})
    : _contentLanguage = contentLanguage;

  final AnalyticsService _analytics;

  /// Reads the user's content language (`bo`, `en`, ...) at share time.
  final String? Function()? _contentLanguage;

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
      AnalyticsProperties.targetId: _nonBlank(targetId),
      AnalyticsProperties.language: _readContentLanguage(),
      AnalyticsProperties.format: format,
      AnalyticsProperties.method: method,
      AnalyticsProperties.groupId: _nonBlank(groupId),
    });
  }

  /// A failed read leaves `language` empty; it never costs the share event.
  String? _readContentLanguage() {
    try {
      return _nonBlank(_contentLanguage?.call());
    } catch (_) {
      return null;
    }
  }

  /// Blank IDs (a post outside any group, say) are sent as absent.
  static String? _nonBlank(String? value) =>
      value == null || value.trim().isEmpty ? null : value;
}

final shareAnalyticsProvider = Provider<ShareAnalytics>((ref) {
  return ShareAnalytics(
    ref.watch(analyticsServiceProvider),
    contentLanguage: () => ref.read(contentLanguageProvider),
  );
});
