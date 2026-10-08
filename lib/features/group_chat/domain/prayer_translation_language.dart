import 'package:flutter_pecha/core/constants/app_config.dart';

/// `translation_language` values the server accepts, by app language code.
const Map<String, String> prayerTranslationLanguages = {
  AppConfig.englishLanguageCode: 'EN',
  AppConfig.chineseLanguageCode: 'ZH',
  AppConfig.tibetanLanguageCode: 'BO',
};

const String defaultPrayerTranslationLanguage = 'EN';

/// The language prayer requests are translated into for [languageCode];
/// English for any app language the server cannot translate into.
String prayerTranslationLanguage(String languageCode) =>
    prayerTranslationLanguages[languageCode.toLowerCase()] ??
    defaultPrayerTranslationLanguage;
