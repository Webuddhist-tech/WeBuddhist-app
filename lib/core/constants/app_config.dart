class AppConfig {
  AppConfig._();

  static const String appName = 'WeBuddhist';
  static const String appPackageName = 'org.pecha.app';
  
  /// Airbridge tracking link that handles attribution and deep linking
  /// Automatically redirects to the appropriate app store (iOS/Android)
  static const String airbridgeTrackingLink = 'https://join.webuddhist.com/get-app';
  
  // Direct store URLs (kept for reference, use airbridgeTrackingLink for sharing)
  static const String appStoreUrl =
      'https://apps.apple.com/app/webuddhist/id6745810914';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=org.pecha.app';

  // Font configuration
  static const String englishSystemFont = 'Inter';
  static const String englishContentFont = 'Source Serif 4';
  static const String chineseSystemFont = 'Noto Sans Traditional Chinese';
  static const String chineseContentFont = 'Noto Serif Traditional Chinese';
  // Bundled builds of Noto Serif Tibetan / BabelStone Tibetan with vertical
  // metrics fitted to Tibetan ink (assets/fonts/README.md).
  static const String tibetanSystemFont = 'NotoSerifTibetanWB';
  static const String tibetanContentFont = 'WBTibetanContent';

  // Language configuration
  static const String tibetanLanguageCode = 'bo';
  static const String englishLanguageCode = 'en';
  static const String chineseLanguageCode = 'zh';
  static const String hindiLanguageCode = 'hi';
  static const String mongolianLanguageCode = 'mn';
  static const String nepaliLanguageCode = 'ne';
  static const String tibetanAdaptationLanguageCode = 'tib';
  static const String tibetanTransliterationLanguageCode = 'tibphono';
  static const List<String> supportedLanguages = [
    'en',
    'zh',
    'bo',
    'hi',
    'mn',
    'ne',
  ];

  /// Maps a language [localeCode] onto a bundled UI locale.
  ///
  /// Returns [localeCode] when the app ships an ARB for it; otherwise English.
  /// Used by `applyUiLocaleForContent` so chrome can fall back when the user
  /// picks a content language the UI cannot render.
  static String resolveContentLanguage(String localeCode) {
    final code = localeCode.toLowerCase();
    if (supportedLanguages.contains(code)) return code;
    return englishLanguageCode;
  }

  // Theme configuration
  static const String defaultLanguage = 'en';
  static const String defaultThemeMode = 'system';
}
