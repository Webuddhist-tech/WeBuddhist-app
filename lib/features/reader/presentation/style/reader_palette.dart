import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every colour the reader page and its sheets draw with.
///
/// Reader widgets take their colours from here rather than from the theme,
/// so the page background and the colours derived from it are decided in
/// one place.
class ReaderPalette {
  const ReaderPalette({
    required this.background,
    required this.text,
    required this.translation,
    required this.heading,
    required this.headingRule,
    required this.verseNumber,
    required this.divider,
    required this.liveHighlight,
    required this.yigchung,
    required this.footnoteMarker,
    required this.footnoteText,
    required this.footnoteBackground,
    required this.pillBackground,
    required this.pillText,
    required this.pillMuted,
    required this.sheetMuted,
    required this.sheetCurrentRow,
  });

  /// The page behind the text; null keeps the app theme's.
  final Color? background;

  /// A verse's original line; null inherits the theme's text colour.
  final Color? text;

  /// A translation shown under its original.
  final Color translation;

  /// Section headings, their numbers and text titles.
  final Color? heading;

  /// The short rule under a top-level heading's number.
  final Color? headingRule;
  final Color? verseNumber;

  /// Rules between headings and between the texts of a page.
  final Color divider;

  /// The band behind the line the puja leader is on.
  final Color liveHighlight;
  final Color yigchung;
  final Color footnoteMarker;
  final Color footnoteText;
  final Color footnoteBackground;

  /// The sections pill: its fill, its title and its count.
  final Color pillBackground;
  final Color pillText;
  final Color pillMuted;

  /// The sections sheet: secondary text and the row on screen.
  final Color sheetMuted;
  final Color sheetCurrentRow;

  /// The palette for [theme]. Reader settings that pick colours are read
  /// through [ref].
  static ReaderPalette resolve(ThemeData theme, WidgetRef ref) {
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    return ReaderPalette(
      // White pages in light mode; dark mode keeps the app's.
      background: isDark ? null : Colors.white,
      text: null,
      translation: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF707070),
      heading: theme.textTheme.bodyMedium?.color,
      headingRule: theme.textTheme.bodySmall?.color,
      verseNumber: theme.textTheme.bodySmall?.color,
      divider: theme.dividerColor,
      liveHighlight:
          isDark
              ? AppColors.liveSegmentHighlightDark
              : AppColors.liveSegmentHighlight,
      yigchung: isDark ? AppColors.readerYigchungDark : AppColors.readerYigchung,
      footnoteMarker: const Color(0xFF007bff),
      footnoteText: const Color(0xFF8a8a8a),
      footnoteBackground: const Color(0xFFF0F0F0),
      pillBackground: onSurface.withValues(alpha: 0.06),
      pillText: onSurface,
      pillMuted: onSurface.withValues(alpha: 0.55),
      sheetMuted: onSurface.withValues(alpha: 0.55),
      sheetCurrentRow: onSurface.withValues(alpha: 0.06),
    );
  }
}
