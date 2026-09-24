import 'package:flutter_pecha/core/analytics/clarity_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatEventDetails', () {
    test('returns null without properties', () {
      expect(ClarityAnalyticsService.formatEventDetails('x', null), isNull);
      expect(ClarityAnalyticsService.formatEventDetails('x', {}), isNull);
      expect(
        ClarityAnalyticsService.formatEventDetails('x', {'a': null}),
        isNull,
      );
    });

    test('appends properties in order and skips redacted keys', () {
      final String? details = ClarityAnalyticsService.formatEventDetails(
        'auth_login_failed',
        {
          'method': 'google',
          'email': 'someone@example.com',
          'reason': 'user\ncancelled',
          'attempt': 2,
        },
      );

      expect(
        details,
        'auth_login_failed method=google reason=user cancelled attempt=2',
      );
    });

    test('cuts to the Clarity custom event limit', () {
      final String? details = ClarityAnalyticsService.formatEventDetails(
        'plan_viewed',
        {'note': 'x' * 300},
      );

      expect(details, hasLength(254));
      expect(details, startsWith('plan_viewed note=xxx'));
    });
  });

  test('tagEntries drops blanks and stringifies values', () {
    final List<MapEntry<String, String>> entries =
        ClarityAnalyticsService.tagEntries({
          'is_guest': true,
          'blank': '   ',
          'access_token': 'secret',
          'count': 3,
        });

    expect(
      {for (final entry in entries) entry.key: entry.value},
      {'is_guest': 'true', 'count': '3'},
    );
  });
}
