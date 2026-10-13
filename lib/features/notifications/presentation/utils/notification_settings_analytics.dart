import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The toggles on the notification settings screen, carried as `setting`.
/// The last four are the server-backed Connect switches.
enum NotificationSetting {
  master,
  routine,
  recitation,
  practice,
  timer,
  groupPosts,
  groupChats,
  prayerReceived,
  prayerRequest,
}

/// Fires once the flag is in SharedPreferences and the schedule was resynced,
/// or for a Connect switch once the backend confirmed it; a toggle that failed
/// or was reverted is not a change.
class NotificationSettingsAnalytics {
  const NotificationSettingsAnalytics(this._analytics);

  final AnalyticsService _analytics;

  void settingChanged({
    required NotificationSetting setting,
    required bool enabled,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.notificationSettingChanged, {
      AnalyticsProperties.setting: setting.name,
      AnalyticsProperties.enabled: enabled,
    });
  }
}

final notificationSettingsAnalyticsProvider =
    Provider<NotificationSettingsAnalytics>((ref) {
      return NotificationSettingsAnalytics(ref.watch(analyticsServiceProvider));
    });
