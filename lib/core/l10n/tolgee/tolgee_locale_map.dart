import 'dart:ui' show Locale;

/// Maps app UI locales (bare language codes) to Tolgee CDN language tags.
///
/// Content Delivery publishes:
/// `en`, `bo-IN`, `zh-Hant-TW`, `zh-Hans-CN`, `hi`, `mn`, `ne`, `th`, `my`,
/// `vi-VN` under the `webuddhist` namespace. The Flutter UI / ARB stack keeps
/// using `bo`, `zh` (Traditional), `zh_Hans` (Simplified) and `vi`.
class TolgeeLocaleMap {
  TolgeeLocaleMap._();

  /// CDN / Tolgee tag string for [appLocale] (used as `currentLanguage` and
  /// as `Locale.toString()` when the tag has no script subtag issues).
  static String cdnTagFor(Locale appLocale) {
    switch (appLocale.languageCode) {
      case 'bo':
        return 'bo-IN';
      case 'zh':
        return appLocale.scriptCode == 'Hans' ? 'zh-Hans-CN' : 'zh-Hant-TW';
      // The Tolgee project already had `vi-VN`, which another client may read.
      case 'vi':
        return 'vi-VN';
      default:
        return appLocale.languageCode;
    }
  }

  /// Canonical app language code for bridge matching (`bo`, `zh`, `zh-Hans`,
  /// `en`, …).
  static String appLanguageCodeOf(String localeNameOrTag) {
    final String normalized = localeNameOrTag.replaceAll('_', '-');
    final String lower = normalized.toLowerCase();
    if (lower == 'bo-in' || lower == 'bo') {
      return 'bo';
    }
    if (lower.startsWith('zh-hans')) {
      return 'zh-Hans';
    }
    if (lower.startsWith('zh')) {
      return 'zh';
    }
    final int separator = normalized.indexOf('-');
    return separator == -1 ? normalized : normalized.substring(0, separator);
  }
}
