import 'dart:ui' show Locale;

import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/l10n/tolgee/tolgee_bridge.dart';
import 'package:flutter_pecha/core/l10n/tolgee/tolgee_localizations_delegate.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Tolgee SDK is never initialized in these tests, which is exactly the
/// state a release build is in when Tolgee is disabled, offline, or still
/// fetching. Everything must fall through to the bundled ARB translations.
void main() {
  setUp(TolgeeBridge.reset);
  tearDown(TolgeeBridge.reset);

  const List<Locale> locales = <Locale>[
    Locale('en'),
    Locale('bo'),
    Locale('zh'),
    Locale('hi'),
    Locale('mn'),
    Locale('ne'),
  ];

  group('bridge inactive', () {
    test('plain keys match the bundled ARB value in every locale', () {
      for (final Locale locale in locales) {
        final AppLocalizations bundled = lookupAppLocalizations(locale);
        final AppLocalizations bridged = tolgeeAppLocalizationsFor(locale);

        expect(bridged.sign_in, bundled.sign_in, reason: '$locale sign_in');
        expect(bridged.logout, bundled.logout, reason: '$locale logout');
        expect(
          bridged.creator_featured_plan,
          bundled.creator_featured_plan,
          reason: '$locale creator_featured_plan',
        );
      }
    });

    test('parameterized and plural keys match the bundled ARB value', () {
      for (final Locale locale in locales) {
        final AppLocalizations bundled = lookupAppLocalizations(locale);
        final AppLocalizations bridged = tolgeeAppLocalizationsFor(locale);

        expect(bridged.ai_greeting('Tenzin'), bundled.ai_greeting('Tenzin'));
        expect(bridged.plan_day_of(2, 9), bundled.plan_day_of(2, 9));
        for (final int count in <int>[0, 1, 7]) {
          expect(
            bridged.mala_rounds_count(count),
            bundled.mala_rounds_count(count),
            reason: '$locale mala_rounds_count($count)',
          );
        }
      }
    });

    test(
      'localeName is preserved so downstream Intl formatting is correct',
      () {
        for (final Locale locale in locales) {
          expect(
            tolgeeAppLocalizationsFor(locale).localeName,
            lookupAppLocalizations(locale).localeName,
          );
        }
      },
    );

    test('lookups return the fallback without touching the SDK', () {
      expect(TolgeeBridge.get('en', 'sign_in', () => 'Sign in'), 'Sign in');
      expect(
        TolgeeBridge.format('en', 'ai_greeting', <String, Object>{
          'name': 'Tenzin',
        }, () => 'Hi Tenzin'),
        'Hi Tenzin',
      );
    });
  });

  group('payload loaded', () {
    void load(String languageCode, Map<String, String> strings) {
      TolgeeBridge.load(languageCode: languageCode, strings: strings);
    }

    test('serves a loaded string over the bundled one', () {
      load('en', <String, String>{'sign_in': 'Sign in over the air'});

      expect(
        TolgeeBridge.get('en', 'sign_in', () => 'bundled'),
        'Sign in over the air',
      );
    });

    test('a multi-part CDN tag still serves its app locale', () {
      // The whole reason the bridge owns this lookup. Published tags are
      // `bo-IN` and `zh-Hant-TW` while the app locales are `bo` and `zh`, and
      // the SDK dropped the region from one and re-cased the other, so neither
      // ever resolved a single string.
      load('bo-IN', <String, String>{'sign_in': 'ནང་འཛུལ།'});
      expect(TolgeeBridge.get('bo', 'sign_in', () => 'bundled'), 'ནང་འཛུལ།');

      load('zh-Hant-TW', <String, String>{'sign_in': '登入'});
      expect(TolgeeBridge.get('zh', 'sign_in', () => 'bundled'), '登入');
    });

    test('refuses to serve one language while another is on screen', () {
      // A language switch swaps the payload asynchronously; until it lands the
      // bundled value is right and the old language would be a visible mix.
      load('bo', <String, String>{'sign_in': 'ནང་འཛུལ།'});

      expect(TolgeeBridge.get('hi', 'sign_in', () => 'bundled'), 'bundled');
    });

    test('a missing or blank key falls back', () {
      load('en', <String, String>{'sign_in': ''});

      expect(TolgeeBridge.get('en', 'sign_in', () => 'bundled'), 'bundled');
      expect(TolgeeBridge.get('en', 'absent', () => 'bundled'), 'bundled');
    });

    test('invalidate makes the bridge inert again', () {
      load('en', <String, String>{'sign_in': 'over the air'});
      TolgeeBridge.invalidate();

      expect(TolgeeBridge.active, isFalse);
      expect(TolgeeBridge.get('en', 'sign_in', () => 'bundled'), 'bundled');
    });

    test('a placeholder string formats from the loaded payload', () {
      load('en', <String, String>{'ai_greeting': 'Hey {name}!'});

      expect(
        TolgeeBridge.format('en', 'ai_greeting', <String, Object>{
          'name': 'Tenzin',
        }, () => 'bundled'),
        'Hey Tenzin!',
      );
    });
  });
}
