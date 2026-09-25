import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which screen started a login or guest session, carried as `source`.
enum AuthSource {
  loginPage,
  loginDrawer,
  onboarding,
  meScreen;

  String get key => switch (this) {
    AuthSource.loginPage => 'login_page',
    AuthSource.loginDrawer => 'login_drawer',
    AuthSource.onboarding => 'onboarding',
    AuthSource.meScreen => 'me_screen',
  };
}

/// Product analytics for auth: one method per tracked action, so the event
/// names and their property keys live in one place. Every call fires and
/// forgets; callers fire after the action happened, never optimistically.
class AuthAnalytics {
  const AuthAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// The user tapped a provider button; [method] is the Auth0 connection.
  void loginStarted({required String method, required AuthSource source}) {
    _analytics.trackInBackground(AnalyticsEvents.authLoginStarted, {
      AnalyticsProperties.method: method,
      AnalyticsProperties.source: source.key,
    });
  }

  /// [source] is null when login started somewhere other than the login page
  /// or drawer.
  void loginSucceeded({String? method, AuthSource? source}) {
    _analytics.trackInBackground(AnalyticsEvents.authLoginSucceeded, {
      AnalyticsProperties.method: method ?? 'default',
      AnalyticsProperties.source: source?.key,
    });
  }

  void loginFailed({
    String? method,
    AuthSource? source,
    required String reason,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.authLoginFailed, {
      AnalyticsProperties.method: method ?? 'default',
      AnalyticsProperties.source: source?.key,
      AnalyticsProperties.reason: reason,
    });
  }

  /// Guest mode was persisted.
  void guestStarted({required AuthSource source}) {
    _analytics.trackInBackground(AnalyticsEvents.authGuestStarted, {
      AnalyticsProperties.source: source.key,
    });
  }

  /// The login drawer opened; [feature] is what asked for login.
  void loginPromptShown({required String feature}) {
    _analytics.trackInBackground(AnalyticsEvents.loginPromptShown, {
      AnalyticsProperties.feature: feature,
    });
  }

  /// The login drawer closed without a login.
  void loginPromptDismissed({required String feature}) {
    _analytics.trackInBackground(AnalyticsEvents.loginPromptDismissed, {
      AnalyticsProperties.feature: feature,
    });
  }
}

final authAnalyticsProvider = Provider<AuthAnalytics>((ref) {
  return AuthAnalytics(ref.watch(analyticsServiceProvider));
});
