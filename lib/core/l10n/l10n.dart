import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';

class L10n {
  static final all = [
    const Locale(AppConfig.englishLanguageCode),
    const Locale(AppConfig.tibetanLanguageCode),
    const Locale(AppConfig.chineseLanguageCode),
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    const Locale(AppConfig.hindiLanguageCode),
    const Locale(AppConfig.mongolianLanguageCode),
    const Locale(AppConfig.nepaliLanguageCode),
  ];

  /// Parses a stored or backend code (`zh`, `zh-Hans`, `zh_Hans`) into a Locale.
  static Locale localeFor(String code) {
    final parts = code.split(RegExp('[-_]'));
    if (parts.length == 2 && parts[1].length == 4) {
      return Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1]);
    }
    return Locale(code);
  }
}
