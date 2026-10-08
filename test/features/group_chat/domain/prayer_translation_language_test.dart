import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_translation_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prayerTranslationLanguage', () {
    test('maps the supported app languages to server codes', () {
      expect(prayerTranslationLanguage('en'), 'EN');
      expect(prayerTranslationLanguage('zh'), 'ZH');
      expect(prayerTranslationLanguage('bo'), 'BO');
    });

    test('ignores the case of the app language code', () {
      expect(prayerTranslationLanguage('ZH'), 'ZH');
      expect(prayerTranslationLanguage('Bo'), 'BO');
      expect(prayerTranslationLanguage('EN'), 'EN');
    });

    test('falls back to English for every other app language', () {
      for (final code in ['hi', 'mn', 'ne', 'th', 'tib', 'tibphono', '']) {
        expect(prayerTranslationLanguage(code), 'EN', reason: "'$code'");
      }
    });

    test('supported languages are keyed by the AppConfig codes', () {
      expect(prayerTranslationLanguages, {
        AppConfig.englishLanguageCode: 'EN',
        AppConfig.chineseLanguageCode: 'ZH',
        AppConfig.tibetanLanguageCode: 'BO',
      });
      expect(defaultPrayerTranslationLanguage, 'EN');
    });
  });
}
