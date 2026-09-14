import 'package:intl/message_format.dart';

import 'tolgee_locale_map.dart';

/// Runtime lookup layer sitting between the generated `AppLocalizations`
/// overrides and the Content Delivery payload.
///
/// Every lookup falls back to the bundled ARB translation, so the app behaves
/// exactly as it did before Tolgee whenever it is disabled, still loading,
/// offline, or missing the key.
///
/// The strings are held here rather than read back out of the Tolgee SDK: the
/// SDK cannot serve a multi-part language tag, which left `bo` and `zh`
/// resolving nothing at all. See [TolgeeCdn].
class TolgeeBridge {
  TolgeeBridge._();

  /// True only while [_strings] holds a payload. While false the bridge is
  /// completely inert and every lookup resolves to the bundled ARB value.
  static bool get active => _strings.isNotEmpty;

  /// The loaded payload, keyed exactly as the CDN publishes it.
  static Map<String, String> _strings = const <String, String>{};

  /// App language code the payload belongs to (`bo`, `zh`, …), used to refuse
  /// serving one language's strings while another is on screen.
  static String? _language;

  /// Adopts a freshly fetched payload for [languageCode].
  static void load({
    required String languageCode,
    required Map<String, String> strings,
  }) {
    _language = TolgeeLocaleMap.appLanguageCodeOf(languageCode);
    _strings = strings;
  }

  /// Drops the loaded payload, making the bridge inert until the next load.
  /// Called before a fetch so the previous language cannot leak into the new
  /// one while it is in flight.
  static void invalidate() {
    _strings = const <String, String>{};
    _language = null;
  }

  /// Resets all bridge state. Used by tests.
  static void reset() => invalidate();

  /// Resolves a translation with no placeholders.
  static String get(String localeName, String key, String Function() fallback) {
    return _raw(localeName, key) ?? fallback();
  }

  /// Resolves a translation containing ICU placeholders or plurals.
  ///
  /// Falls back to the bundled ARB value when the remote string cannot be
  /// formatted, which guards against a malformed ICU message published in
  /// Tolgee taking down a screen.
  static String format(
    String localeName,
    String key,
    Map<String, Object> args,
    String Function() fallback,
  ) {
    final String? raw = _raw(localeName, key);
    if (raw == null || !raw.contains('{')) {
      return fallback();
    }
    try {
      return MessageFormat(raw, locale: localeName).format(args);
    } catch (_) {
      return fallback();
    }
  }

  static String? _raw(String localeName, String key) {
    if (!_matchesLoadedLanguage(localeName)) {
      return null;
    }
    final String? value = _strings[key];
    // An empty string is a key that exists but says nothing; the bundled value
    // is better than blank UI.
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  /// Guards against serving strings for the wrong language.
  ///
  /// Only one payload is held at a time and it is swapped asynchronously. Until
  /// the fetch for a newly chosen language lands, the requested locale and the
  /// loaded one disagree, and serving the loaded one would mix languages in the
  /// UI.
  ///
  /// CDN tags like `bo-IN` / `zh-Hant-TW` are treated as matching app locales
  /// `bo` / `zh` via [TolgeeLocaleMap].
  static bool _matchesLoadedLanguage(String localeName) {
    final String? loaded = _language;
    if (loaded == null) return false;
    return TolgeeLocaleMap.appLanguageCodeOf(localeName) == loaded;
  }
}
