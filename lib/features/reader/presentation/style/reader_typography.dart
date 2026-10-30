import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_fonts_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_text_size_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_fonts.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_script.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_text_size.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:flutter_pecha/features/reader/presentation/style/reader_fonts.dart';
export 'package:flutter_pecha/features/reader/presentation/style/reader_script.dart';
export 'package:flutter_pecha/features/reader/presentation/style/reader_text_size.dart';

/// What a line of the reader page is, for its size.
enum ReaderTextRole {
  /// An original line with no translation shown.
  originalAlone,

  /// An original line with its translation shown under it.
  originalWithTranslation,

  /// A translation shown under its original.
  translationUnder,

  /// A translation shown without its original.
  translationAlone;

  bool get isTranslation =>
      this == translationUnder || this == translationAlone;
}

/// A line's size, line height and default weight and style.
class ReaderTextMetrics {
  const ReaderTextMetrics({
    required this.fontSize,
    required this.lineHeight,
    this.fontWeight,
    this.fontStyle,
  });

  final double fontSize;

  /// In logical pixels.
  final double lineHeight;

  /// Null is the font's regular weight.
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;

  /// [lineHeight] as a multiple of [fontSize], for `TextStyle.height`.
  double get height => lineHeight / fontSize;
}

/// The space between lines and verses at one size step, in pixels.
typedef ReaderGaps = ({double verse, double pair, double inPair});

/// Sizes, font families and line heights of the reader page.
///
/// Sizes are looked up by role and by the script of the line: an English
/// translation under a Tibetan original uses the Latin column. Each line
/// then scales by its size step and its line height by the spacing.
/// Values are rounded only at the end.
class ReaderTypography {
  const ReaderTypography({
    this.settings = const ReaderTextSize(),
    this.fonts = const ReaderFontChoices(),
  });

  final ReaderTextSize settings;

  /// The fonts picked per line. They change only the family, never a size.
  final ReaderFontChoices fonts;

  /// The typography for the reader's current settings.
  static ReaderTypography resolve(WidgetRef ref) => ReaderTypography(
    settings: ref.watch(readerTextSizeProvider),
    fonts: ref.watch(readerFontsProvider),
  );

  /// Sizes at step 3, by role and script.
  static const Map<ReaderTextRole, Map<ReaderScript, double>> baseSizes = {
    ReaderTextRole.originalAlone: {
      ReaderScript.latin: 18,
      ReaderScript.tibetan: 27,
      ReaderScript.chinese: 19,
      ReaderScript.devanagari: 18,
      ReaderScript.cyrillic: 18,
    },
    // The original gets smaller under a translation, so it does not
    // overpower it.
    ReaderTextRole.originalWithTranslation: {
      ReaderScript.latin: 18,
      ReaderScript.tibetan: 22,
      ReaderScript.chinese: 18,
      ReaderScript.devanagari: 18,
      ReaderScript.cyrillic: 18,
    },
    ReaderTextRole.translationUnder: {
      ReaderScript.latin: 16,
      ReaderScript.tibetan: 19,
      ReaderScript.chinese: 17,
      ReaderScript.devanagari: 17,
      ReaderScript.cyrillic: 16,
    },
    ReaderTextRole.translationAlone: {
      ReaderScript.latin: 17,
      ReaderScript.tibetan: 27,
      ReaderScript.chinese: 19,
      ReaderScript.devanagari: 18,
      ReaderScript.cyrillic: 17,
    },
  };

  /// Heading sizes against the script's "original alone" size, by depth.
  static double headingScale(int depth) => switch (depth) {
    0 => 1.2,
    1 => 1.0,
    _ => 0.9,
  };

  static const double instructionScale = 0.85;
  static const double verseNumberScale = 0.6;
  static const double minVerseNumberSize = 10;

  /// Tibetan at Compact keeps a fixed 1.5 rather than 1.9 × 0.9.
  static const double tibetanCompactRatio = 1.5;

  /// A line in [role] written in [script].
  ReaderTextMetrics line(ReaderTextRole role, ReaderScript script) {
    final step =
        role.isTranslation ? settings.translationStep : settings.originalStep;
    final metrics = _metrics(baseSizes[role]![script]!, script, step);
    return ReaderTextMetrics(
      fontSize: metrics.fontSize,
      lineHeight: metrics.lineHeight,
      fontWeight: switch (role) {
        ReaderTextRole.originalAlone || ReaderTextRole.originalWithTranslation
            when script == ReaderScript.latin => FontWeight.w600,
        _ => null,
      },
      fontStyle:
          role == ReaderTextRole.translationUnder &&
                  (script == ReaderScript.latin ||
                      script == ReaderScript.cyrillic)
              ? FontStyle.italic
              : null,
    );
  }

  /// A section heading [depth] levels down, written in [script]. Headings
  /// follow the original line's size step.
  ReaderTextMetrics heading(int depth, ReaderScript script) {
    final metrics = _metrics(
      _alone(script) * headingScale(depth),
      script,
      settings.originalStep,
    );
    return ReaderTextMetrics(
      fontSize: metrics.fontSize,
      lineHeight: metrics.lineHeight,
      fontWeight: FontWeight.w600,
    );
  }

  /// A ritual direction between verses, written in [script].
  ReaderTextMetrics instruction(ReaderScript script) {
    final metrics = _metrics(
      _alone(script) * instructionScale,
      script,
      settings.originalStep,
    );
    return ReaderTextMetrics(
      fontSize: metrics.fontSize,
      lineHeight: metrics.lineHeight,
      fontStyle:
          script == ReaderScript.latin || script == ReaderScript.cyrillic
              ? FontStyle.italic
              : null,
    );
  }

  /// Size of a verse number whose numerals are in [script].
  double verseNumberSize([ReaderScript script = ReaderScript.latin]) =>
      math.max(
        minVerseNumberSize,
        _round(
          _alone(script) *
              verseNumberScale *
              ReaderTextSize.scaleOf(settings.originalStep),
        ),
      );

  /// A top-level heading's number above its title.
  double sectionNumberSize(ReaderScript script) =>
      _round(_alone(script) * 0.9 * ReaderTextSize.scaleOf(settings.originalStep));

  /// The space between lines and verses when the topmost line shown has
  /// size [step].
  ReaderGaps gaps(int step) {
    final scale = ReaderTextSize.scaleOf(step);
    final spacing = settings.spacing;
    return (
      verse: _round(spacing.verseGap * scale),
      pair: _round(spacing.pairGap * scale),
      inPair: _round(spacing.inPairGap * scale),
    );
  }

  /// Size of authored plan text, which has no original or translation of
  /// its own: the old default scaled by the original line's step.
  double get planTextSize => _round(
    ReaderTextSize.legacyDefaultFontSize *
        ReaderTextSize.scaleOf(settings.originalStep),
  );

  /// Size of reader chrome (the sections pill, the bottom bar) written in
  /// [script], given its Latin [size]. Chrome does not follow the size steps.
  static double chromeSize(double size, ReaderScript script) =>
      _round(size * script.interfaceScale);

  /// Tibetan interface text in the app's Tibetan UI font is set ×1.1, not
  /// the card's ×1.5: that font draws bigger letters per point than the
  /// mocks', and at ×1.1 labels measure as WF27 and WF28 draw them.
  static const double tibetanInterfaceScale = 1.1;

  /// Size of interface text (sheets, a heading's overline) written in
  /// [script], given its Latin [size].
  static double interfaceSize(double size, ReaderScript script) =>
      script == ReaderScript.tibetan
          ? _round(size * tibetanInterfaceScale)
          : chromeSize(size, script);

  /// The sections pill's text.
  static const double sectionPillSize = 14;

  /// The bottom bar's title and count.
  static const double bottomBarSize = 13;

  /// The family for a line in [language]: the font picked for [role]'s line
  /// in [script], which defaults to [language]'s. Verse numbers, the pill
  /// and the sheet follow the original's pick.
  String family(
    String language, {
    ReaderTextRole role = ReaderTextRole.originalAlone,
    ReaderScript? script,
  }) =>
      fonts
          .fontFor(
            role.isTranslation
                ? ReaderFontLine.translation
                : ReaderFontLine.original,
            script ?? ReaderScript.ofLanguage(language),
          )
          .family();

  /// The family for a section heading in [script]: Latin and Cyrillic
  /// headings are in [ReaderFonts.latinHeading] at
  /// [ReaderFonts.headingWeight]; others follow the original's pick.
  String headingFamily(String language, ReaderScript script) =>
      script == ReaderScript.latin || script == ReaderScript.cyrillic
          ? ReaderFonts.latinHeading.family(weight: ReaderFonts.headingWeight)
          : family(language, script: script);

  /// Line height of list rows outside the page, such as the sections sheet;
  /// these do not follow the size steps.
  double? listLineHeight(String language) => getLineHeight(language);

  double _alone(ReaderScript script) =>
      baseSizes[ReaderTextRole.originalAlone]![script]!;

  ({double fontSize, double lineHeight}) _metrics(
    double base,
    ReaderScript script,
    int step,
  ) {
    final scaled = base * ReaderTextSize.scaleOf(step);
    final spacing = settings.spacing;
    final lineHeight =
        script == ReaderScript.tibetan && spacing == ReaderSpacing.compact
            ? scaled * tibetanCompactRatio
            : scaled * script.lineHeightRatio * spacing.lineHeight;
    return (fontSize: _round(scaled), lineHeight: _round(lineHeight));
  }

  /// Rounds half away from zero, as the design's tables do.
  static double _round(double value) => value.roundToDouble();
}
