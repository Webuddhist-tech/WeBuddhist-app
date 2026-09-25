import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/auth/presentation/utils/auth_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

void main() {
  late RecordingAnalyticsService service;
  late AuthAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = AuthAnalytics(service);
  });

  test('loginStarted carries the provider and the screen it was tapped on', () {
    analytics.loginStarted(method: 'google', source: AuthSource.loginDrawer);

    expect(service.eventNames, [AnalyticsEvents.authLoginStarted]);
    expect(service.events.single.properties, {
      'method': 'google',
      'source': 'login_drawer',
    });
  });

  test('login outcome keeps method and source, failure adds the reason', () {
    analytics.loginSucceeded(method: 'apple', source: AuthSource.loginPage);
    analytics.loginFailed(
      method: 'sms',
      source: AuthSource.loginPage,
      reason: 'cancelled',
    );

    expect(service.eventNames, [
      AnalyticsEvents.authLoginSucceeded,
      AnalyticsEvents.authLoginFailed,
    ]);
    expect(service.events.first.properties, {
      'method': 'apple',
      'source': 'login_page',
    });
    expect(service.events.last.properties, {
      'method': 'sms',
      'source': 'login_page',
      'reason': 'cancelled',
    });
  });

  test('a login started elsewhere has a default method and no source', () {
    analytics.loginSucceeded();

    expect(service.events.single.properties, {
      'method': 'default',
      'source': null,
    });
  });

  test('guestStarted names where the guest session began', () {
    analytics.guestStarted(source: AuthSource.onboarding);

    expect(service.eventNames, [AnalyticsEvents.authGuestStarted]);
    expect(service.events.single.properties, {'source': 'onboarding'});
  });

  test('login prompt events carry the feature that asked for login', () {
    analytics.loginPromptShown(feature: 'home-group-event');
    analytics.loginPromptDismissed(feature: 'home-group-event');

    expect(service.eventNames, [
      AnalyticsEvents.loginPromptShown,
      AnalyticsEvents.loginPromptDismissed,
    ]);
    for (final event in service.events) {
      expect(event.properties, {'feature': 'home-group-event'});
    }
  });
}
