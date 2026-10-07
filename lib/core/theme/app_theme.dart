// This file provides a shared theme utility for the application,
// defining the light and dark themes and other styling elements.
// Defines the application's light and dark themes and theme utilities.
// Shared across all features for consistent styling.
//
// Typography specs from Figma (for reference):
// - Font sizes: 32px, 24px, 18px, 16px, 14px, 12px, 10px, 8px
// - Font weights: Light (300), Regular (400), Medium (500), Semi Bold (600), Bold (700), Extra Bold (800)
// - Primary font: System default (Roboto on Android, SF Pro on iOS)
// - Accent font: Serif fallback for special headings
// - Tibetan: WBTibetanContent (local) for content and NotoSerifTibetanWB (local) for system UI
// - English: Inter for system UI and EB Garamond for content
// - Chinese: Inter for system UI and EB Garamond for content

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'app_colors.dart';
import 'font_config.dart';

class AppTheme {
  static ThemeData lightTheme([Locale? locale]) {
    final fontConfig = _getFontConfiguration(locale, Brightness.light);
    final systemFontFamily = fontConfig.fontFamily;
    final contentFontFamily = getFontFamily(
      locale?.languageCode ?? AppConfig.englishLanguageCode,
    );
    final buttonTextStyle = _buttonTextStyle(locale, 14, FontWeight.w500);
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: systemFontFamily,
      textTheme: fontConfig.textTheme,
      scaffoldBackgroundColor: AppColors.surfaceLight,

      // Color scheme based on Figma design
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.primary,
        onSecondary: AppColors.onPrimary,
        error: AppColors.error,
        surface: AppColors.surfaceWhite,
        onSurface: AppColors.textPrimary,
        surfaceContainer: AppColors.surfaceWhite, // used for container bgcolor
        outline: AppColors.greyLight, // used for container border color
        surfaceTint: Colors.transparent,
      ),
      extensions: const [
        SkeletonizerConfigData(
          effect: ShimmerEffect(
            baseColor: AppColors.greyLight,
            highlightColor: AppColors.grey50,
          ),
        ),
      ],

      // AppBar with cream background matching scaffold
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle:
            (fontConfig.textTheme?.headlineSmall ?? const TextStyle()).copyWith(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
      ),

      // Card theme with white cards on cream background
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.greyLight, width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // List tiles
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textPrimary,
      ),

      // Input fields with rounded corners
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: AppColors.textSecondary,
          fontFamily: contentFontFamily,
        ),
        prefixIconColor: AppColors.greyMedium,
        fillColor: AppColors.primarySurface,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.grey500, width: 2),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),

      // Bottom navigation bar with burgundy background and rounded top corners
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryDark, // MAN 800
        selectedItemColor: AppColors.surfaceLight,
        unselectedItemColor: AppColors.surfaceLight,
        selectedIconTheme: IconThemeData(
          size: 28,
          color: AppColors.surfaceLight,
        ),
        unselectedIconTheme: IconThemeData(
          size: 24,
          color: AppColors.surfaceLight,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.surfaceLight,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: AppColors.surfaceLight,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: buttonTextStyle,
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: buttonTextStyle,
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: buttonTextStyle,
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.greyLight,
        thickness: 1,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryContainer,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: AppColors.surfaceLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (locale?.languageCode == AppConfig.tibetanLanguageCode) {
      return baseTheme.copyWith(
        textTheme: AppFontConfig.applyTibetanTextTheme(baseTheme.textTheme),
      );
    }
    return baseTheme;
  }

  static ThemeData darkTheme([Locale? locale]) {
    final fontConfig = _getFontConfiguration(locale, Brightness.dark);
    final systemFontFamily = fontConfig.fontFamily;
    final contentFontFamily = getFontFamily(
      locale?.languageCode ?? AppConfig.englishLanguageCode,
    );
    final buttonTextStyle = _buttonTextStyle(locale, 14, FontWeight.w500);
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: systemFontFamily,
      textTheme: fontConfig.textTheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // Color scheme based on Figma dark mode design
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark, // Use darker primary for dark mode
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryDarkest,
        secondary: AppColors.primaryDark,
        onSecondary: AppColors.onPrimary,
        error: AppColors.error,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainer:
            AppColors.cardBorderDark, // used for container bgcolor
        outline: AppColors.cardBorderDark, // used for container border color
        surfaceTint: Colors.transparent,
      ),
      extensions: const [
        SkeletonizerConfigData.dark(
          effect: ShimmerEffect(
            baseColor: Color(0xFF3A3A3A),
            highlightColor: Color(0xFF4A4A4A),
          ),
        ),
      ],

      // AppBar with dark background
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle:
            (fontConfig.textTheme?.headlineSmall ?? const TextStyle()).copyWith(
              color: AppColors.textPrimaryDark,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
      ),

      // Card theme with dark background and border
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorderDark, width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // List tiles
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimaryDark,
        iconColor: AppColors.textPrimaryDark,
      ),

      // Input fields with dark background
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: AppColors.textSubtleDark,
          fontFamily: contentFontFamily,
        ),
        prefixIconColor: AppColors.grey600,
        fillColor: AppColors.surfaceVariantDark,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.greyDark, width: 2),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryDark,
        size: 24,
      ),

      // Bottom navigation bar (same burgundy as light mode)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryDark, // MAN 800
        selectedItemColor: AppColors.surfaceLight,
        unselectedItemColor: AppColors.surfaceLight,
        selectedIconTheme: IconThemeData(
          size: 28,
          color: AppColors.surfaceLight,
        ),
        unselectedIconTheme: IconThemeData(
          size: 24,
          color: AppColors.surfaceLight,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.surfaceLight,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: AppColors.surfaceLight,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark, // Darker in dark mode
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: buttonTextStyle,
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: buttonTextStyle,
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primaryDark, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: buttonTextStyle,
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorderDark,
        thickness: 1,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        selectedColor: AppColors.primaryDark,
        labelStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardDark,
        contentTextStyle: const TextStyle(color: AppColors.textPrimaryDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (locale?.languageCode == AppConfig.tibetanLanguageCode) {
      return baseTheme.copyWith(
        textTheme: AppFontConfig.applyTibetanTextTheme(baseTheme.textTheme),
      );
    }
    return baseTheme;
  }

  static _FontConfiguration _getFontConfiguration(
    Locale? locale,
    Brightness brightness,
  ) {
    // Get system font configuration for the locale
    final textTheme = AppFontConfig.getTextTheme(
      locale?.languageCode,
      FontType.system,
      brightness,
    );
    // Google Fonts text themes carry their own family per style; a bundled
    // system font is also set as the ThemeData default so widgets that
    // build a bare TextStyle still pick it up.
    final config = AppFontConfig.getConfig(locale?.languageCode);
    final fontFamily =
        config.systemFontIsGoogle
            ? null
            : AppFontConfig.getFontFamily(
              locale?.languageCode,
              FontType.system,
            );

    return _FontConfiguration(fontFamily: fontFamily, textTheme: textTheme);
  }

  static TextStyle _buttonTextStyle(
    Locale? locale,
    double fontSize,
    FontWeight fontWeight,
  ) {
    final style = TextStyle(fontSize: fontSize, fontWeight: fontWeight);
    return AppFontConfig.applyTibetanMetrics(
          locale?.languageCode,
          style,
          compact: true,
        ) ??
        style;
  }
}

class _FontConfiguration {
  final String? fontFamily;
  final TextTheme? textTheme;

  _FontConfiguration({required this.fontFamily, required this.textTheme});
}
