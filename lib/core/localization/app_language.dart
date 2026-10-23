import 'package:flutter_pecha/core/constants/app_config.dart';

/// A content language the backend can serve.
///
/// [code] is the only load-bearing field: it is sent verbatim as the
/// `language` query parameter to content APIs. [nativeName] labels the language
/// in its own script inside the picker, and [name] is the English/canonical
/// fallback label. Whether the app can also localize its *UI* into this
/// language is a client-side fact (does a bundled ARB exist in `L10n.all`?) and
/// is intentionally NOT carried here.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    this.enabled = true,
  });

  /// Code sent to content APIs (e.g. `bo`, `en`, `zh`).
  final String code;

  /// English/canonical display name (e.g. `Tibetan`).
  final String name;

  /// Name shown in the picker, in the language's own script (e.g. `བོད་ཡིག`).
  final String nativeName;

  /// Server-side kill switch. Disabled languages are hidden from the picker.
  final bool enabled;

  factory AppLanguage.fromJson(Map<String, dynamic> json) {
    final code = (json['code'] as String? ?? '').trim();
    final name = (json['name'] as String? ?? '').trim();
    final nativeName = (json['native_name'] as String? ?? '').trim();
    return AppLanguage(
      code: code,
      name: name.isNotEmpty ? name : code,
      // Fall back to the English name, then the raw code, so a row always
      // renders even if the backend omits the native name.
      nativeName:
          nativeName.isNotEmpty ? nativeName : (name.isNotEmpty ? name : code),
      // Default to enabled when the backend omits the flag.
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'native_name': nativeName,
    'enabled': enabled,
  };

  @override
  bool operator ==(Object other) =>
      other is AppLanguage &&
      other.code == code &&
      other.name == name &&
      other.nativeName == nativeName &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(code, name, nativeName, enabled);

  /// Bundled list used before the backend responds, and as the offline
  /// fallback. Mirrors the UI locales the app ships ARB translations for.
  static const List<AppLanguage> bundledFallback = [
    AppLanguage(
      code: AppConfig.englishLanguageCode,
      name: 'English',
      nativeName: 'English',
    ),
    AppLanguage(
      code: AppConfig.tibetanLanguageCode,
      name: 'Tibetan',
      nativeName: 'བོད་ཡིག',
    ),
    AppLanguage(
      code: AppConfig.chineseLanguageCode,
      name: 'Traditional Chinese',
      nativeName: '中文',
    ),
    AppLanguage(
      code: AppConfig.simplifiedChineseLanguageCode,
      name: 'Simplified Chinese',
      nativeName: '简体中文',
    ),
    AppLanguage(
      code: AppConfig.hindiLanguageCode,
      name: 'Hindi',
      nativeName: 'हिन्दी',
    ),
    AppLanguage(
      code: AppConfig.mongolianLanguageCode,
      name: 'Mongolian',
      nativeName: 'Монгол',
    ),
    AppLanguage(
      code: AppConfig.nepaliLanguageCode,
      name: 'Nepali',
      nativeName: 'नेपाली',
    ),
  ];
}
