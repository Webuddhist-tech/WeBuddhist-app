import 'dart:ui' show Locale;

import 'package:flutter_pecha/core/l10n/tolgee/tolgee_locale_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TolgeeLocaleMap.cdnTagFor', () {
    test('maps bo and zh to published CDN tags', () {
      expect(TolgeeLocaleMap.cdnTagFor(const Locale('bo')), 'bo-IN');
      expect(TolgeeLocaleMap.cdnTagFor(const Locale('zh')), 'zh-Hant-TW');
    });

    test('passes through en hi mn ne', () {
      for (final String code in <String>['en', 'hi', 'mn', 'ne']) {
        expect(TolgeeLocaleMap.cdnTagFor(Locale(code)), code);
      }
    });
  });
}
