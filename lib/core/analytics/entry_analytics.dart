import 'dart:io';

import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App state when a push was tapped, carried on `push_notification_opened`.
enum PushAppState { foreground, background, terminated }

/// Whose permission dialog was shown, carried on the permission events.
enum NotificationOs { android, ios }

/// The running OS. macOS counts as iOS, as the notification code treats it.
NotificationOs get currentNotificationOs =>
    Platform.isAndroid ? NotificationOs.android : NotificationOs.ios;

/// Minutes since the last daily occurrence of [scheduledMinuteOfDay].
int minutesSinceScheduled(int scheduledMinuteOfDay, DateTime now) {
  final nowMinute = now.hour * 60 + now.minute;
  return (nowMinute - scheduledMinuteOfDay) % Duration.minutesPerDay;
}

/// Product analytics for the ways into the app: deep links, notification taps
/// and the OS notification permission. One method per tracked action; every
/// call fires and forgets, after the link or tap was actually routed.
class EntryAnalytics {
  const EntryAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// A deep link was routed to a screen. [source] is the handler that got it
  /// (`app_links` or `airbridge`).
  void deepLinkOpened({
    required String source,
    required String routeKind,
    String? targetId,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.deepLinkOpened, {
      AnalyticsProperties.source: source,
      AnalyticsProperties.routeKind: routeKind,
      AnalyticsProperties.targetId: targetId,
    });
  }

  /// A push tap was routed. [sessionType] and [sourceId] are the payload's
  /// own values, null when it carried none.
  void pushNotificationOpened({
    required PushAppState appState,
    String? sessionType,
    String? sourceId,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.pushNotificationOpened, {
      AnalyticsProperties.sessionType: sessionType,
      AnalyticsProperties.sourceId: sourceId,
      AnalyticsProperties.appState: appState.name,
    });
  }

  /// A local notification tap was handled. [type] is the payload's routine
  /// item type (`recitation`, `timer`, `accumulator`, ...) or `timer_session`.
  void localNotificationOpened({
    required String type,
    int? minutesAfterScheduled,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.localNotificationOpened, {
      AnalyticsProperties.type: type,
      AnalyticsProperties.minutesAfterScheduled: minutesAfterScheduled,
    });
  }

  /// The OS notification dialog is being shown.
  void notificationPermissionPrompted({NotificationOs? os}) {
    _analytics.trackInBackground(
      AnalyticsEvents.notificationPermissionPrompted,
      {AnalyticsProperties.os: (os ?? currentNotificationOs).name},
    );
  }

  /// The dialog returned: `notification_permission_granted` or `_denied`.
  void notificationPermissionAnswered({
    required bool granted,
    NotificationOs? os,
  }) {
    _analytics.trackInBackground(
      granted
          ? AnalyticsEvents.notificationPermissionGranted
          : AnalyticsEvents.notificationPermissionDenied,
      {AnalyticsProperties.os: (os ?? currentNotificationOs).name},
    );
  }
}

final entryAnalyticsProvider = Provider<EntryAnalytics>((ref) {
  return EntryAnalytics(ref.watch(analyticsServiceProvider));
});
