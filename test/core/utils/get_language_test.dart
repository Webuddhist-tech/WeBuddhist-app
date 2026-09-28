import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getNativeLanguageName', () {
    test('names the app languages as the language picker does', () {
      for (final language in AppLanguage.bundledFallback) {
        expect(
          getNativeLanguageName(language.code),
          language.nativeName,
          reason: language.code,
        );
      }
    });

    test('names other library languages in their own script', () {
      expect(getNativeLanguageName('vi'), 'Tiếng Việt');
      expect(getNativeLanguageName('lzh'), '文言文');
      expect(getNativeLanguageName('sa'), 'संस्कृतम्');
    });

    test('ignores case and surrounding space', () {
      expect(getNativeLanguageName(' ZH '), '中文');
      expect(getNativeLanguageName('Hi'), 'हिन्दी');
    });

    test('is null for a language it does not know', () {
      expect(getNativeLanguageName('i9'), isNull);
      expect(getNativeLanguageName(''), isNull);
    });
  });
}
