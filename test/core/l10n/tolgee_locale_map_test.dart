import 'dart:ui' show Locale;

import 'package:flutter_pecha/core/l10n/tolgee/tolgee_locale_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TolgeeLocaleMap.cdnTagFor', () {
    test('maps bo and zh to published CDN tags', () {
      expect(TolgeeLocaleMap.cdnTagFor(const Locale('bo')), 'bo-IN');
      expect(TolgeeLocaleMap.cdnTagFor(const Locale('zh')), 'zh-Hant-TW');
    });

    test('maps Simplified Chinese to zh-Hans-CN', () {
      expect(
        TolgeeLocaleMap.cdnTagFor(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        ),
        'zh-Hans-CN',
      );
    });

    test('passes through en hi mn ne', () {
      for (final String code in <String>['en', 'hi', 'mn', 'ne']) {
        expect(TolgeeLocaleMap.cdnTagFor(Locale(code)), code);
      }
    });
  });

  group('TolgeeLocaleMap.appLanguageCodeOf', () {
    test('keeps Traditional and Simplified Chinese apart', () {
      expect(TolgeeLocaleMap.appLanguageCodeOf('zh'), 'zh');
      expect(TolgeeLocaleMap.appLanguageCodeOf('zh-Hant-TW'), 'zh');
      expect(TolgeeLocaleMap.appLanguageCodeOf('zh_Hans'), 'zh-Hans');
      expect(TolgeeLocaleMap.appLanguageCodeOf('zh-Hans-CN'), 'zh-Hans');
    });
  });
}
