import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_transliteration.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_verse_lines.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/segment_type_style.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_verse_frame.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_number.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An original line with its translation under it ends at its letters, not
/// at the bottom of its line box; the translation starts at its own. Most
/// of the room inside a pair was that empty line box (Tibetan's 1.9 above
/// all), so trimming it is what pulls the pair together.
const _trimUnder = TextHeightBehavior(applyHeightToLastDescent: false);
const _trimOver = TextHeightBehavior(applyHeightToFirstAscent: false);

/// Which lines a verse draws in the dual layout. "Translation only"
/// ([showOriginal] false) still draws the original when the translation
/// could not be loaded, so the page never turns into a column of
/// placeholders; a verse the translation has no line for says "Not
/// translated" instead ([InterlinearSegmentItem.untranslated], from
/// `SecondaryReaderState.lacks`). While the verse's translation is
/// still on its way ([translationPending]) it draws the loading line instead,
/// so the original does not flash in before it.
({bool original, bool translation}) interlinearLayers({
  required bool showOriginal,
  required bool hasTranslation,
  bool translationPending = false,
}) => (
  original: showOriginal || (!hasTranslation && !translationPending),
  translation: showOriginal || hasTranslation || translationPending,
);

/// This verse's line in the translation, or null while there is none to show
/// — not loaded yet, failed to load, or no aligned line for the verse. Shared
/// by the verse widget and the copy action, so both agree on which line is
/// on screen.
String? interlinearTranslationFor(
  Map<int, String>? contentBySegmentNumber,
  int segmentNumber,
) {
  final line = contentBySegmentNumber?[segmentNumber];
  return line == null || line.trim().isEmpty ? null : line;
}

class InterlinearSegmentItem extends ConsumerWidget {
  const InterlinearSegmentItem({
    super.key,
    required this.segment,
    required this.depth,
    required this.primaryLanguage,
    required this.scope,
    this.showPrimary = true,
    required this.secondarySlot,
    this.secondaryContentBySegmentNumber,
    this.secondaryIsLoading = false,
    this.isSelected = false,
    this.isHighlighted = false,
    this.highlightSource = NavigationSource.normal,
    this.isGreyedOut = false,
    this.isLive = false,
    this.followingLive = false,
    this.untranslated = false,
    this.onTap,
  });

  final Segment segment;
  final int depth;
  final String primaryLanguage;

  /// The reader this line is shown in; decides which script pick applies.
  final ReaderSettingsScope scope;

  /// False for "translation only": the primary line is left out and the
  /// translation is drawn as the main text rather than in the muted tone.
  /// A verse with no translation to show keeps its primary line
  /// ([interlinearLayers]).
  final bool showPrimary;
  final ReaderSlotConfig secondarySlot;

  /// Lookup map of secondary version content keyed by segment_number.
  /// Falls back to a placeholder when the key is missing or while loading.
  final Map<int, String>? secondaryContentBySegmentNumber;

  /// True while this verse's translation is still being fetched.
  final bool secondaryIsLoading;
  final bool isSelected;
  // Received from caller but visual highlight not yet applied in interlinear mode.
  final bool isHighlighted;
  final NavigationSource highlightSource;
  final bool isGreyedOut;

  /// The line the puja leader is on right now.
  final bool isLive;

  /// A live room is being followed: verses other than [isLive]'s are muted.
  final bool followingLive;

  /// "Translation only", and the translation has no line for this verse: a
  /// muted "Not translated" stands in its place, with its number, so no
  /// verse goes missing without a word.
  final bool untranslated;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ReaderStyle.of(context, ref);
    final primary = primarySegmentHtml(
      ref,
      content: segment.content,
      language: primaryLanguage,
      scope: scope,
    );
    final secondary =
        untranslated
            ? _SecondaryResolved(
              text: context.l10n.reader_not_translated,
              isPlaceholder: true,
            )
            : _resolveSecondaryContent(context);
    final layers =
        untranslated
            ? (original: false, translation: true)
            : interlinearLayers(
              showOriginal: showPrimary,
              hasTranslation: !secondary.isPlaceholder,
              translationPending: secondary.isPending,
            );
    // The aligned line is the same kind of segment, so it shares the style.
    final typeStyle = SegmentTypeStyle.of(segment.type);

    final originalRole =
        layers.translation
            ? ReaderTextRole.originalWithTranslation
            : ReaderTextRole.originalAlone;
    final originalScript = ReaderScript.of(
      primary.html,
      language: primary.fontLanguage,
    );
    final originalMetrics = style.type.line(originalRole, originalScript);
    final translationRole =
        layers.original
            ? ReaderTextRole.translationUnder
            : ReaderTextRole.translationAlone;
    final translationScript = ReaderScript.of(
      secondary.text,
      language: secondarySlot.languageCode,
    );
    final translationMetrics = style.type.line(
      translationRole,
      translationScript,
    );
    // Each line asks its font for the file of the weight it is set in.
    final originalWeight = typeStyle.fontWeight ?? originalMetrics.fontWeight;
    final translationWeight =
        typeStyle.fontWeight ?? translationMetrics.fontWeight;
    final translationFamily = style.type.family(
      secondarySlot.languageCode,
      role: translationRole,
      script: translationScript,
      weight: translationWeight ?? FontWeight.w400,
    );

    // Gaps follow the larger of the lines shown; the number, the line it
    // sits under.
    final settings = style.type.settings;
    final gaps = style.type.gaps(
      style.type.pairGapStep(
        original: layers.original,
        translation: layers.translation,
      ),
    );
    final numberStep =
        layers.translation ? settings.translationStep : settings.originalStep;
    final colors = readerVerseColors(
      style.palette,
      isLive: isLive,
      followingLive: followingLive,
      // "Not translated" is in the muted colour, as under an original.
      translationUnderOriginal: layers.original || untranslated,
    );
    final lines = pairLines(
      layers.original ? primary.html : null,
      layers.translation && !secondary.isPlaceholder ? secondary.text : null,
    );

    // A script whose fonts sit the letters high in their own box (Myanmar)
    // takes a fixed box instead, which needs no trimming.
    final originalStrut = ReaderTypography.lineStrut(
      originalScript,
      originalMetrics,
    );
    final translationStrut = ReaderTypography.lineStrut(
      translationScript,
      translationMetrics,
    );
    final trimUnder =
        layers.translation && originalStrut == null ? _trimUnder : null;
    final trimOver =
        layers.original && translationStrut == null ? _trimOver : null;

    Widget original(String html) => SegmentHtmlWidget(
      htmlContent: html,
      segmentIndex: segment.segmentNumber,
      fontSize: originalMetrics.fontSize,
      lineHeight: originalMetrics.height,
      language: primary.fontLanguage,
      textColor: colors.original,
      fontStyle: typeStyle.fontStyle ?? originalMetrics.fontStyle,
      fontWeight: originalWeight,
      fontFamily: style.type.family(
        primary.fontLanguage,
        role: originalRole,
        script: originalScript,
        weight: originalWeight ?? FontWeight.w400,
      ),
      textHeightBehavior: trimUnder,
      strutStyle: originalStrut,
    );
    Widget translation(String html) => SegmentHtmlWidget(
      htmlContent: html,
      segmentIndex: segment.segmentNumber,
      fontSize: translationMetrics.fontSize,
      lineHeight: translationMetrics.height,
      language: secondarySlot.languageCode,
      textColor: colors.translation,
      fontStyle: typeStyle.fontStyle ?? translationMetrics.fontStyle,
      fontWeight: translationWeight,
      fontFamily: translationFamily,
      textHeightBehavior: trimOver,
      strutStyle: translationStrut,
    );

    Widget translationBlock() =>
        secondary.isPlaceholder
            ? _SecondaryPlaceholder(
              text: secondary.text,
              fontFamily: translationFamily,
              metrics: translationMetrics,
              color: colors.translation,
              textHeightBehavior: trimOver,
            )
            : lines.translation.isEmpty
            ? const SizedBox.shrink()
            : translation(lines.translation.single);

    // The card marks the selected verse; its lines are not underlined.
    return ReaderVerseFrame(
      style: style,
      verseGap: gaps.verse,
      isLive: isLive,
      isSelected: isSelected,
      isGreyedOut: isGreyedOut,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lines.paired)
            for (var i = 0; i < lines.original.length; i++) ...[
              if (i > 0) SizedBox(height: gaps.pair),
              original(lines.original[i]),
              SizedBox(height: gaps.inPair),
              translation(lines.translation[i]),
            ]
          else ...[
            if (lines.original.isNotEmpty) original(lines.original.single),
            if (lines.original.isNotEmpty && layers.translation)
              SizedBox(height: gaps.inPair),
            if (layers.translation) translationBlock(),
          ],
          Padding(
            padding: EdgeInsets.only(top: gaps.number),
            child: SegmentNumber(
              label: segment.displayNumber,
              language: secondarySlot.languageCode,
              step: numberStep,
            ),
          ),
        ],
      ),
    );
  }

  _SecondaryResolved _resolveSecondaryContent(BuildContext context) {
    final fromMap = interlinearTranslationFor(
      secondaryContentBySegmentNumber,
      segment.segmentNumber,
    );
    if (fromMap != null) {
      return _SecondaryResolved(
        text: normalizeSegmentHtml(fromMap),
        isPlaceholder: false,
      );
    }
    if (secondaryIsLoading) {
      return _SecondaryResolved(
        text: context.l10n.loading,
        isPlaceholder: true,
        isPending: true,
      );
    }
    // A version is selected but this particular segment has no translation.
    // Show a quiet centered em-dash rather than a verbose error line.
    return const _SecondaryResolved(text: '—', isPlaceholder: true);
  }
}

class _SecondaryResolved {
  final String text;
  final bool isPlaceholder;

  /// The placeholder is the loading line: the translation is on its way.
  final bool isPending;
  const _SecondaryResolved({
    required this.text,
    required this.isPlaceholder,
    this.isPending = false,
  });
}

class _SecondaryPlaceholder extends StatelessWidget {
  const _SecondaryPlaceholder({
    required this.text,
    required this.fontFamily,
    required this.metrics,
    required this.color,
    this.textHeightBehavior,
  });

  final String text;
  final String? fontFamily;

  /// The translation line's size and line height, which this stands in for.
  final ReaderTextMetrics metrics;
  final Color? color;

  /// As the translation line's, so the verse keeps its height when it lands.
  final TextHeightBehavior? textHeightBehavior;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textHeightBehavior: textHeightBehavior,
        style: TextStyle(
          fontSize: metrics.fontSize,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w400,
          color: color,
          height: metrics.height,
        ),
      ),
    );
  }
}
