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

  test('login outcome keeps method and source, failure adds a short code', () {
    const rawText =
        'Phone login failed: AuthException: Login failed: '
        'The user closed the browser app and the authentication was canceled.';

    analytics.loginSucceeded(method: 'apple', source: AuthSource.loginPage);
    analytics.loginFailed(
      method: 'sms',
      source: AuthSource.loginPage,
      failureMessage: rawText,
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
      'reason_code': 'user_cancelled',
      'reason_detail':
          'The user closed the browser app and the authentication was '
          'canceled.',
    });
  });

  group('reason_detail cleans the failure text', () {
    test('keeps a bare message as it is', () {
      expect(
        cleanLoginFailureMessage('Google login failed'),
        'Google login failed',
      );
    });

    test('drops the wrappers around the message', () {
      expect(
        cleanLoginFailureMessage(
          'Google login failed: AuthException: Login failed: Forbidden',
        ),
        'Forbidden',
      );
      expect(
        cleanLoginFailureMessage(
          'Phone login failed: AuthException: An unexpected error occurred '
          'during login',
        ),
        'An unexpected error occurred during login',
      );
    });

    test('takes the readable part of an iOS error dump', () {
      expect(
        cleanLoginFailureMessage(
          'Google login failed: AuthException: Login failed: An unexpected '
          'error occurred. CAUSE: Error Domain=com.apple.AuthenticationServices'
          '.WebAuthenticationSession Code=3 "The UIWindowScene for the returned '
          'window was not in the foreground active state." '
          'UserInfo={NSDebugDescription=The UIWindowScene}',
        ),
        'The UIWindowScene for the returned window was not in the foreground '
        'active state.',
      );
      expect(
        cleanLoginFailureMessage(
          'Google login failed: AuthException: Login failed: An unexpected '
          'error occurred. CAUSE: Unable to complete the operation. CAUSE: '
          'Error Domain=NSURLErrorDomain Code=-1005 "The network connection '
          'was lost." UserInfo={_kCFStreamErrorCodeKey=53}',
        ),
        'The network connection was lost.',
      );
    });

    test('removes the Auth0 domain, URLs, emails and phone numbers', () {
      final cleaned = cleanLoginFailureMessage(
        'Apple login failed: AuthException: Login failed: An unexpected error '
        'occurred. CAUSE: Error Domain=com.apple.AuthenticationServices'
        '.WebAuthenticationSession Code=1 "Application with identifier '
        'org.pecha.app is not associated with domain tenant.us.auth0.com. '
        'Using HTTPS callbacks requires Associated Domains" UserInfo={}',
      );
      expect(cleaned, isNot(contains('auth0.com')));
      expect(cleaned, contains('is not associated with domain <redacted>.'));

      expect(
        cleanLoginFailureMessage(
          'See https://example.com/a?b=c for someone@example.com on '
          '+1 202-555-0143',
        ),
        'See <redacted> for <redacted> on <redacted>',
      );
    });

    test('caps the length', () {
      expect(cleanLoginFailureMessage('x' * 500), 'x' * 200);
    });
  });

  group('failure text maps to a reason code', () {
    // Real auth_login_failed reasons from PostHog, plus AuthService's own.
    const cases = {
      'Google login failed: AuthException: Login failed: The user closed the '
              'browser app and the authentication was canceled.':
          'user_cancelled',
      'Apple login failed: AuthException: Login failed: The user cancelled '
              'the Web Auth operation.':
          'user_cancelled',
      'Google login failed: AuthException: Login failed: User did not '
              'authorize the request':
          'user_cancelled',
      'Google login failed: AuthException: Login failed: No compatible '
              'Browser application is installed.':
          'no_browser',
      'Google login failed: AuthException: Login failed: An unexpected error '
              'occurred. CAUSE: Unable to complete the operation. CAUSE: Error '
              'Domain=NSURLErrorDomain':
          'network',
      'Phone login failed: AuthException: Network error during login':
          'network',
      'Google login failed: AuthException: Login is not configured': 'config',
      'Apple login failed: AuthException: Login failed: An unexpected error '
              'occurred. CAUSE: Error Domain=com.apple.AuthenticationServices.'
              'WebAuthenticationSession Code=1 "Application with identifier '
              'org.pecha.app is not associated with domain <host>. Using HTTPS '
              'callbacks requires Associated Domains using the `webcredentials` '
              'service type"':
          'config',
      'Google login failed: AuthException: Login failed: An unexpected error '
              'occurred. CAUSE: Error Domain=com.apple.AuthenticationServices.'
              'WebAuthenticationSession Code=3 "The UIWindowScene for the '
              'returned window was not in the foreground active state."':
          'unexpected',
      'Google login failed: AuthException: An unexpected error occurred '
              'during login':
          'unexpected',
      'Google login failed: AuthException: Login failed: Forbidden':
          'unexpected',
      'Google login failed': 'unexpected',
    };

    cases.forEach((message, expected) {
      test(expected, () {
        expect(LoginFailureCode.fromMessage(message).key, expected);
      });
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
