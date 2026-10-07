// Font configuration for multi-language support
// Defines system fonts (for UI) and content fonts (for backend texts)
// for each supported language.

// - Tibetan (bo): bundled NotoSerifTibetanWB for system UI and WBTibetanContent
//   (BabelStone Tibetan) for content/source. Both ship with vertical metrics
//   fitted to Tibetan ink so `height:` boxes enclose vowel signs and stacks
//   (see assets/fonts/README.md and FONT_SYSTEM_GUIDE.md).
// - English (en): Inter for system UI and Source Serif 4 for content/source
// - Chinese (zh): Noto Sans Traditional Chinese for system UI and Noto Serif Traditional Chinese for content
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';

/// Defines the type of font usage in the application
enum FontType {
  /// System font: Used for UI elements like tabs, navigation, settings, buttons
  system,

  /// Content font: Used for content from backend like texts, practice plans, recitations
  content,
}

enum AppTextSize {
  caption,
  label,
  body,
  bodyLarge,
  title,
  titleLarge,
  content,
  contentLarge,
  display,
}

/// Configuration for a language's font families
class LanguageFontConfig {
  final String systemFont;

  final String contentFont;

  final bool systemFontIsGoogle;
  final bool contentFontIsGoogle;

  const LanguageFontConfig({
    required this.systemFont,
    required this.contentFont,
    this.systemFontIsGoogle = true,
    this.contentFontIsGoogle = true,
  });
}

/// Central font configuration for all supported languages
class AppFontConfig {
  AppFontConfig._();

  static const TextLeadingDistribution tibetanLeadingDistribution =
      TextLeadingDistribution.even;

  static const double tibetanUiLineHeight = 1.55;
  static const double tibetanCompactLineHeight = 1.25;
  static const double tibetanContentLineHeight = 1.55;

  static const double captionFontSize = 12;
  static const double labelFontSize = 14;
  static const double bodyFontSize = 16;
  static const double bodyLargeFontSize = 18;
  static const double titleFontSize = 20;
  static const double titleLargeFontSize = 22;
  static const double contentFontSize = 20;
  static const double contentLargeFontSize = 22;
  static const double displayFontSize = 24;

  static const double tibetanLabelFontSize = labelFontSize;
  static const double tibetanBodyFontSize = bodyFontSize;
  static const double tibetanBodyLargeFontSize = bodyLargeFontSize;
  static const double tibetanTitleFontSize = titleFontSize;
  static const double tibetanContentFontSize = contentFontSize;
  static const double tibetanContentLargeFontSize = contentLargeFontSize;
  static const double tibetanDisplayFontSize = displayFontSize;

  static bool isTibetanLanguage(String? languageCode) {
    final code = languageCode?.toLowerCase();
    return code == AppConfig.tibetanLanguageCode ||
        code == AppConfig.tibetanAdaptationLanguageCode;
  }

  static double getTextSize(AppTextSize size) {
    return switch (size) {
      AppTextSize.caption => captionFontSize,
      AppTextSize.label => labelFontSize,
      AppTextSize.body => bodyFontSize,
      AppTextSize.bodyLarge => bodyLargeFontSize,
      AppTextSize.title => titleFontSize,
      AppTextSize.titleLarge => titleLargeFontSize,
      AppTextSize.content => contentFontSize,
      AppTextSize.contentLarge => contentLargeFontSize,
      AppTextSize.display => displayFontSize,
    };
  }

  static double getLineHeight(String? languageCode, {bool compact = false}) {
    if (!isTibetanLanguage(languageCode)) return 1.5;
    return compact ? tibetanCompactLineHeight : tibetanContentLineHeight;
  }

  static TextStyle? applyTibetanMetrics(
    String? languageCode,
    TextStyle? style, {
    bool compact = false,
  }) {
    if (!isTibetanLanguage(languageCode)) return style;

    final effectiveStyle = style ?? const TextStyle();
    return effectiveStyle.copyWith(
      height: compact ? tibetanCompactLineHeight : tibetanUiLineHeight,
      leadingDistribution: tibetanLeadingDistribution,
    );
  }

  static StrutStyle? tibetanStrutStyle(
    String? languageCode,
    double fontSize, {
    bool compact = false,
  }) {
    if (!isTibetanLanguage(languageCode)) return null;

    return StrutStyle(
      fontSize: fontSize,
      height: compact ? tibetanCompactLineHeight : tibetanUiLineHeight,
      leadingDistribution: tibetanLeadingDistribution,
      forceStrutHeight: true,
    );
  }

  static TextTheme applyTibetanTextTheme(TextTheme textTheme) {
    TextStyle? style(TextStyle? value) =>
        applyTibetanMetrics(AppConfig.tibetanLanguageCode, value);

    return textTheme.copyWith(
      displayLarge: style(textTheme.displayLarge),
      displayMedium: style(textTheme.displayMedium),
      displaySmall: style(textTheme.displaySmall),
      headlineLarge: style(textTheme.headlineLarge),
      headlineMedium: style(textTheme.headlineMedium),
      headlineSmall: style(textTheme.headlineSmall),
      titleLarge: style(textTheme.titleLarge),
      titleMedium: style(textTheme.titleMedium),
      titleSmall: style(textTheme.titleSmall),
      bodyLarge: style(textTheme.bodyLarge),
      bodyMedium: style(textTheme.bodyMedium),
      bodySmall: style(textTheme.bodySmall),
      labelLarge: style(textTheme.labelLarge),
      labelMedium: style(textTheme.labelMedium),
      labelSmall: style(textTheme.labelSmall),
    );
  }

  static const Map<String, LanguageFontConfig> _languageFonts = {
    // Tibetan - bundled NotoSerifTibetanWB for UI, WBTibetanContent for
    // content/source (both local assets, see assets/fonts/README.md)
    AppConfig.tibetanLanguageCode: LanguageFontConfig(
      systemFont: AppConfig.tibetanSystemFont,
      contentFont: AppConfig.tibetanContentFont,
      systemFontIsGoogle: false,
      contentFontIsGoogle: false,
    ),

    AppConfig.tibetanAdaptationLanguageCode: LanguageFontConfig(
      systemFont: AppConfig.tibetanSystemFont,
      contentFont: AppConfig.tibetanContentFont,
      systemFontIsGoogle: false,
      contentFontIsGoogle: false,
    ),

    // English - Google Inter for UI, Source Serif 4 for content
    AppConfig.englishLanguageCode: LanguageFontConfig(
      systemFont: AppConfig.englishSystemFont,
      contentFont: AppConfig.englishContentFont,
      systemFontIsGoogle: true,
      contentFontIsGoogle: true,
    ),

    AppConfig.tibetanTransliterationLanguageCode: LanguageFontConfig(
      systemFont: AppConfig.englishSystemFont,
      contentFont: AppConfig.englishContentFont,
      systemFontIsGoogle: true,
      contentFontIsGoogle: true,
    ),

    // Chinese (zh-TW) - Noto Sans Traditional Chinese for UI, Noto Serif Traditional Chinese for content
    AppConfig.chineseLanguageCode: LanguageFontConfig(
      systemFont: AppConfig.chineseSystemFont,
      contentFont: AppConfig.chineseContentFont,
      systemFontIsGoogle: true,
      contentFontIsGoogle: true,
    ),
  };

  /// Default font configuration (used when language is not found)
  static const LanguageFontConfig _defaultConfig = LanguageFontConfig(
    systemFont: AppConfig.englishSystemFont,
    contentFont: AppConfig.englishContentFont,
    systemFontIsGoogle: true,
    contentFontIsGoogle: true,
  );

  /// Get font configuration for a specific language
  static LanguageFontConfig getConfig(String? languageCode) {
    if (languageCode == null) return _defaultConfig;
    return _languageFonts[languageCode.toLowerCase()] ?? _defaultConfig;
  }

  /// Get font family name for a specific language and font type
  /// Returns the actual font family string that can be used with TextStyle
  static String getFontFamily(String? languageCode, FontType fontType) {
    final config = getConfig(languageCode);
    final fontName =
        fontType == FontType.system ? config.systemFont : config.contentFont;
    final isGoogle =
        fontType == FontType.system
            ? config.systemFontIsGoogle
            : config.contentFontIsGoogle;

    if (!isGoogle) {
      // Return local font family name as-is
      return fontName;
    }

    // For Google Fonts, return the font family name from the GoogleFonts API
    return _getGoogleFontFamilyName(fontName);
  }

  /// Helper to get the actual font family name from Google Fonts
  static String _getGoogleFontFamilyName(String fontName) {
    switch (fontName) {
      case AppConfig.englishSystemFont:
        return GoogleFonts.inter().fontFamily ?? AppConfig.englishSystemFont;
      case AppConfig.englishContentFont:
        return GoogleFonts.sourceSerif4().fontFamily ??
            AppConfig.englishContentFont;
      case AppConfig.chineseSystemFont:
        return GoogleFonts.notoSansTc().fontFamily ??
            AppConfig.chineseSystemFont;
      case AppConfig.chineseContentFont:
        return GoogleFonts.notoSerifTc().fontFamily ??
            AppConfig.chineseContentFont;
      default:
        return GoogleFonts.inter().fontFamily ?? AppConfig.englishSystemFont;
    }
  }

  /// Get TextTheme with appropriate font for a language and font type
  /// This is used for system UI elements
  static TextTheme getTextTheme(
    String? languageCode,
    FontType fontType,
    Brightness brightness,
  ) {
    final config = getConfig(languageCode);
    final fontName =
        fontType == FontType.system ? config.systemFont : config.contentFont;
    final isGoogle =
        fontType == FontType.system
            ? config.systemFontIsGoogle
            : config.contentFontIsGoogle;

    if (!isGoogle) {
      // Local (asset) font: stamp the family onto every theme style, the
      // same way the GoogleFonts text themes do.
      return ThemeData(brightness: brightness).textTheme.apply(
        fontFamily: fontName,
      );
    }

    // Use Google Fonts
    return _getGoogleFontTextTheme(fontName, brightness);
  }

  /// Helper method to get Google Font TextTheme by font name
  static TextTheme _getGoogleFontTextTheme(
    String fontName,
    Brightness brightness,
  ) {
    final baseTextTheme = ThemeData(brightness: brightness).textTheme;

    switch (fontName) {
      case AppConfig.englishSystemFont:
        return GoogleFonts.interTextTheme(baseTextTheme);
      case AppConfig.englishContentFont:
        return GoogleFonts.sourceSerif4TextTheme(baseTextTheme);
      case AppConfig.chineseSystemFont:
        return GoogleFonts.notoSansTcTextTheme(baseTextTheme);
      case AppConfig.chineseContentFont:
        return GoogleFonts.notoSerifTcTextTheme(baseTextTheme);
      default:
        return GoogleFonts.interTextTheme(baseTextTheme);
    }
  }

  /// Get text style for content with appropriate font
  static TextStyle? getContentTextStyle(
    String? languageCode,
    TextStyle? baseStyle,
  ) {
    final config = getConfig(languageCode);

    if (!config.contentFontIsGoogle) {
      // For local fonts
      return baseStyle?.copyWith(fontFamily: config.contentFont);
    }

    // Use Google Fonts
    return _getGoogleFontTextStyle(config.contentFont, baseStyle);
  }

  /// Helper method to get Google Font TextStyle by font name
  static TextStyle? _getGoogleFontTextStyle(
    String fontName,
    TextStyle? baseStyle,
  ) {
    switch (fontName) {
      case AppConfig.englishSystemFont:
        return GoogleFonts.inter(textStyle: baseStyle);
      case AppConfig.englishContentFont:
        return GoogleFonts.sourceSerif4(textStyle: baseStyle);
      case AppConfig.chineseSystemFont:
        return GoogleFonts.notoSansTc(textStyle: baseStyle);
      case AppConfig.chineseContentFont:
        return GoogleFonts.notoSerifTc(textStyle: baseStyle);
      default:
        return GoogleFonts.inter(textStyle: baseStyle);
    }
  }

  /// Get all supported language codes
  static List<String> get supportedLanguages => _languageFonts.keys.toList();
}
