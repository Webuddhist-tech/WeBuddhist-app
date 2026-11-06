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
typedef ReaderGaps = ({
  double verse,
  double pair,
  double inPair,
  double number,
});

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

  /// Sizes at step 3, by role and script. The transliteration scripts' are
  /// set from how much of its size each one's letters fill, against Latin's
  /// half: Gujarati, Thai and Khmer draw smaller per point, Telugu and
  /// Kannada larger. Myanmar's letters fill about what Latin's do (0.51 in
  /// Noto Serif Myanmar against Source Serif's 0.49), so it takes Latin's
  /// sizes. Starting values, to be checked by eye.
  static const Map<ReaderTextRole, Map<ReaderScript, double>> baseSizes = {
    ReaderTextRole.originalAlone: {
      ReaderScript.latin: 18,
      ReaderScript.tibetan: 27,
      ReaderScript.chinese: 19,
      ReaderScript.devanagari: 18,
      ReaderScript.cyrillic: 18,
      ReaderScript.bengali: 18,
      ReaderScript.gurmukhi: 18,
      ReaderScript.gujarati: 19,
      ReaderScript.telugu: 17,
      ReaderScript.kannada: 17,
      ReaderScript.malayalam: 18,
      ReaderScript.sinhala: 18,
      ReaderScript.thai: 19,
      ReaderScript.myanmar: 18,
      ReaderScript.khmer: 20,
    },
    // The original gets smaller under a translation, so it does not
    // overpower it. Tibetan draws about 0.34 of its size against English's
    // 0.5, so at 24 its letters stand level with a 16 English translation.
    ReaderTextRole.originalWithTranslation: {
      ReaderScript.latin: 18,
      ReaderScript.tibetan: 24,
      ReaderScript.chinese: 18,
      ReaderScript.devanagari: 18,
      ReaderScript.cyrillic: 18,
      ReaderScript.bengali: 18,
      ReaderScript.gurmukhi: 18,
      ReaderScript.gujarati: 19,
      ReaderScript.telugu: 17,
      ReaderScript.kannada: 17,
      ReaderScript.malayalam: 18,
      ReaderScript.sinhala: 18,
      ReaderScript.thai: 19,
      ReaderScript.myanmar: 18,
      ReaderScript.khmer: 20,
    },
    // Chinese characters fill their size: at 16 they read as large as the
    // other translations.
    ReaderTextRole.translationUnder: {
      ReaderScript.latin: 16,
      ReaderScript.tibetan: 19,
      ReaderScript.chinese: 16,
      ReaderScript.devanagari: 17,
      ReaderScript.cyrillic: 16,
      ReaderScript.bengali: 16,
      ReaderScript.gurmukhi: 16,
      ReaderScript.gujarati: 17,
      ReaderScript.telugu: 15,
      ReaderScript.kannada: 15,
      ReaderScript.malayalam: 16,
      ReaderScript.sinhala: 16,
      ReaderScript.thai: 17,
      ReaderScript.myanmar: 16,
      ReaderScript.khmer: 18,
    },
    ReaderTextRole.translationAlone: {
      ReaderScript.latin: 17,
      ReaderScript.tibetan: 27,
      ReaderScript.chinese: 19,
      ReaderScript.devanagari: 18,
      ReaderScript.cyrillic: 17,
      ReaderScript.bengali: 17,
      ReaderScript.gurmukhi: 17,
      ReaderScript.gujarati: 18,
      ReaderScript.telugu: 16,
      ReaderScript.kannada: 16,
      ReaderScript.malayalam: 17,
      ReaderScript.sinhala: 17,
      ReaderScript.thai: 18,
      ReaderScript.myanmar: 17,
      ReaderScript.khmer: 19,
    },
  };

  /// Heading sizes against the script's "original alone" size, by depth.
  static double headingScale(int depth) => switch (depth) {
    0 => 1.2,
    1 => 1.0,
    _ => 0.9,
  };

  /// A heading's size multiplier at [step]: the verse text's up to the
  /// default step, then half its growth (×1.375 rather than ×1.75 at 7).
  static double headingStepScale(int step) {
    final scale = ReaderTextSize.scaleOf(step);
    return scale <= 1 ? scale : 1 + (scale - 1) / 2;
  }

  static const double instructionScale = 0.85;
  static const double verseNumberScale = 0.6;
  static const double minVerseNumberSize = 10;

  /// Tibetan at Compact keeps a fixed 1.5 rather than 1.9 × 0.9.
  static const double tibetanCompactRatio = 1.5;

  /// From this step up, line heights taper by [largeStepTaper]: big text
  /// needs less room between its lines, as Apple's and Material's type
  /// scales tighten as they grow.
  static const int largeStepFrom = 6;
  static const double largeStepTaper = 0.1;

  /// [script]'s line height as a multiple of its size, at size [step].
  static double lineHeightRatio(ReaderScript script, int step) =>
      script.lineHeightRatio -
      (ReaderTextSize.clampStep(step) >= largeStepFrom ? largeStepTaper : 0);

  /// The line box a verse line in [script] is laid out in, or null for its
  /// font's own.
  ///
  /// Myanmar fonts declare a descent of 1.26 em for marks that reach about
  /// 0.53 em below the line, so their own box leaves a deep empty band under
  /// the letters, and trimming a line's box down to its descent, as a verse
  /// pair does, makes that band deeper still. A Myanmar line takes a box
  /// shaped like the Latin reading font's instead: the same height
  /// ([metrics]), its baseline as low as a Latin line's. The room is then
  /// above the letters, between pairs, and the lowest marks dip about
  /// 0.08 em into the space above the line under them.
  static StrutStyle? lineStrut(
    ReaderScript script,
    ReaderTextMetrics metrics,
  ) =>
      script.hasDeepDescent
          ? StrutStyle(
            fontFamily: ReaderFonts.sourceSerif4.family(),
            fontSize: metrics.fontSize,
            height: metrics.height,
            forceStrutHeight: true,
          )
          : null;

  /// A line in [role] written in [script].
  ReaderTextMetrics line(ReaderTextRole role, ReaderScript script) {
    final step =
        role.isTranslation ? settings.translationStep : settings.originalStep;
    final metrics = _metrics(baseSizes[role]![script]!, script, step);
    return ReaderTextMetrics(
      fontSize: metrics.fontSize,
      lineHeight: metrics.lineHeight,
      // A Latin or Cyrillic original leads its translation by one weight;
      // translations are upright and regular in every script.
      fontWeight: switch (role) {
        ReaderTextRole.originalAlone || ReaderTextRole.originalWithTranslation
            when script == ReaderScript.latin ||
                script == ReaderScript.cyrillic =>
          ReaderFonts.originalWeight,
        _ => null,
      },
    );
  }

  /// A section heading [depth] levels down, written in [script]. Headings
  /// follow the original line's size step, growing at half its rate above
  /// the default ([headingStepScale]) so a title stays a title on screen.
  ReaderTextMetrics heading(int depth, ReaderScript script) {
    final step = settings.originalStep;
    final metrics = _metrics(
      _alone(script) *
          headingScale(depth) *
          headingStepScale(step) /
          ReaderTextSize.scaleOf(step),
      script,
      step,
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

  /// Size of a verse number whose numerals are in [script], under a line at
  /// size [step] (the original's by default).
  double verseNumberSize([ReaderScript script = ReaderScript.latin, int? step]) =>
      math.max(
        minVerseNumberSize,
        _round(
          _alone(script) *
              verseNumberScale *
              ReaderTextSize.scaleOf(step ?? settings.originalStep),
        ),
      );

  /// A top-level heading's number above its title.
  double sectionNumberSize(ReaderScript script) =>
      _round(_alone(script) * 0.9 * ReaderTextSize.scaleOf(settings.originalStep));

  /// The space between lines and verses when the larger line shown has size
  /// [step] ([pairGapStep]).
  ReaderGaps gaps(int step) {
    final scale = ReaderTextSize.scaleOf(step);
    final spacing = settings.spacing;
    return (
      verse: _round(spacing.verseGap * scale),
      pair: _round(spacing.pairGap * scale),
      inPair: _round(spacing.inPairGap * scale),
      number: _round(spacing.numberGap * scale),
    );
  }

  /// The step a verse's gaps follow: the larger of its lines' steps, so a
  /// small original keeps its distance from the big translation above it
  /// and reads with its own.
  int pairGapStep({required bool original, required bool translation}) =>
      original && translation
          ? math.max(settings.originalStep, settings.translationStep)
          : original
          ? settings.originalStep
          : settings.translationStep;

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
  /// and the sheet follow the original's pick. [weight] is the line's own,
  /// so a downloaded font draws that weight's file rather than a thickened
  /// regular.
  String family(
    String language, {
    ReaderTextRole role = ReaderTextRole.originalAlone,
    ReaderScript? script,
    FontWeight weight = FontWeight.w400,
  }) =>
      fonts
          .fontFor(
            role.isTranslation
                ? ReaderFontLine.translation
                : ReaderFontLine.original,
            script ?? ReaderScript.ofLanguage(language),
          )
          .family(weight: weight);

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
            : scaled * lineHeightRatio(script, step) * spacing.lineHeight;
    return (fontSize: _round(scaled), lineHeight: _round(lineHeight));
  }

  /// Rounds half away from zero, as the design's tables do.
  static double _round(double value) => value.roundToDouble();
}
