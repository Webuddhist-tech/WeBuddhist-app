import 'dart:ui' show Locale;

/// Maps app UI locales (bare language codes) to Tolgee CDN language tags.
///
/// Content Delivery publishes:
/// `en`, `bo-IN`, `zh-Hant-TW`, `hi`, `mn`, `ne` under the `webuddhist`
/// namespace. The Flutter UI / ARB stack keeps using `bo` and `zh`.
class TolgeeLocaleMap {
  TolgeeLocaleMap._();

  /// CDN / Tolgee tag string for [appLocale] (used as `currentLanguage` and
  /// as `Locale.toString()` when the tag has no script subtag issues).
  static String cdnTagFor(Locale appLocale) {
    switch (appLocale.languageCode) {
      case 'bo':
        return 'bo-IN';
      case 'zh':
        return 'zh-Hant-TW';
      default:
        return appLocale.languageCode;
    }
  }

  /// Canonical app language code for bridge matching (`bo`, `zh`, `en`, …).
  static String appLanguageCodeOf(String localeNameOrTag) {
    final String normalized = localeNameOrTag.replaceAll('_', '-');
    final String lower = normalized.toLowerCase();
    if (lower == 'bo-in' || lower == 'bo') {
      return 'bo';
    }
    if (lower.startsWith('zh')) {
      return 'zh';
    }
    final int separator = normalized.indexOf('-');
    return separator == -1 ? normalized : normalized.substring(0, separator);
  }
}
