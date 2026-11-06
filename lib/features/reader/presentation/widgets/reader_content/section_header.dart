import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_numerals.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A section's place among the page's sections, for its overline.
typedef ReaderSectionPlace = ({int position, int total});

/// A table-of-contents heading, left-aligned: an overline "SECTION n / m"
/// for a section the pill counts, the title, and an optional subtitle.
class SectionHeader extends ConsumerWidget {
  final Section section;
  final int depth;
  final String language;

  /// A rule above the title, for a heading that follows another's lines.
  final bool showDivider;

  /// Where the section sits among those the pill counts; null for a heading
  /// the pill does not count (a nested or grouping heading).
  final ReaderSectionPlace? place;

  /// The language the page's numbers are written in.
  final String? numeralLanguage;

  /// Shown in italic under the title.
  final String? subtitle;

  /// Appended to the overline after a "·", e.g. the live round.
  final String? overlineTrailing;

  /// The translation's title, once under the title (a text's title while
  /// both lines show), in [translationLanguage].
  final String? translation;
  final String? translationLanguage;

  const SectionHeader({
    super.key,
    required this.section,
    required this.depth,
    required this.language,
    this.showDivider = false,
    this.place,
    this.numeralLanguage,
    this.subtitle,
    this.overlineTrailing,
    this.translation,
    this.translationLanguage,
  });

  /// Size of the overline in Latin; other scripts scale it like the chrome.
  static const double overlineSize = 11;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = section.title;
    if (title == null || title.isEmpty) return const SizedBox.shrink();

    final style = ReaderStyle.of(context, ref);
    final script = ReaderScript.of(title, language: language);
    final place = this.place;
    final subtitle = this.subtitle;
    final numeralScript = ReaderScript.ofLanguage(numeralLanguage ?? language);

    return Padding(
      padding: EdgeInsets.only(
        left: ReaderConstants.segmentHorizontalPadding,
        right: ReaderConstants.segmentHorizontalPadding,
        top: depth == 0 ? 20 : 12,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Divider(
                height: 1,
                thickness: 1,
                color: style.palette.divider,
              ),
            ),
          // A heading the pill does not count still carries the live round.
          if (place != null || overlineTrailing != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _Overline(
                text: readerSectionOverline(
                  place == null
                      ? null
                      : context.l10n.reader_section_position(
                        '${place.position}',
                        '${place.total}',
                      ),
                  trailing: overlineTrailing,
                  script: numeralScript,
                ),
                numeralScript: numeralScript,
                color: style.palette.verseNumber,
              ),
            ),
          ReaderHeadingTitle(
            title: title,
            language: language,
            depth: depth,
            translation: translation,
            translationLanguage: translationLanguage,
          ),
          if (subtitle != null && subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: style.type.instruction(script).fontSize,
                  fontStyle: FontStyle.italic,
                  fontFamily: style.type.family(language, script: script),
                  color: style.palette.translation,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A heading's title at [depth], and the translation's title once under it
/// in the translation lines' style. A title in a script that breaks lines
/// at spaces is set smaller when its longest word is wider than the page,
/// so no word is split.
class ReaderHeadingTitle extends ConsumerWidget {
  const ReaderHeadingTitle({
    super.key,
    required this.title,
    required this.language,
    this.depth = 0,
    this.translation,
    this.translationLanguage,
  });

  final String title;
  final String language;
  final int depth;
  final String? translation;
  final String? translationLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ReaderStyle.of(context, ref);
    final script = ReaderScript.of(title, language: language);
    final metrics = style.type.heading(depth, script);
    final headingStyle = TextStyle(
      fontSize: metrics.fontSize,
      fontWeight: metrics.fontWeight,
      fontFamily: style.type.headingFamily(language, script),
      color: style.palette.heading,
      height: metrics.height,
    );
    final translation = this.translation;
    final translationLanguage = this.translationLanguage ?? language;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        Text fitted(String text, TextStyle textStyle, ReaderScript script) =>
            Text(
              text,
              style: textStyle.copyWith(
                fontSize:
                    script.breaksAtSpaces
                        ? readerHeadingFitSize(
                          text,
                          textStyle,
                          constraints.maxWidth,
                          textScaler: scaler,
                        )
                        : textStyle.fontSize,
              ),
            );
        if (translation == null || translation.isEmpty) {
          return fitted(title, headingStyle, script);
        }
        final translationScript = ReaderScript.of(
          translation,
          language: translationLanguage,
        );
        final line = style.type.line(
          ReaderTextRole.translationUnder,
          translationScript,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fitted(title, headingStyle, script),
            const SizedBox(height: 6),
            fitted(
              translation,
              TextStyle(
                fontSize: line.fontSize,
                fontFamily: style.type.family(
                  translationLanguage,
                  role: ReaderTextRole.translationUnder,
                  script: translationScript,
                ),
                color: style.palette.translation,
                height: line.height,
              ),
              translationScript,
            ),
          ],
        );
      },
    );
  }
}

/// The size to set [text] in [style] at so its widest word fits
/// [maxWidth]: [style]'s own, or less. Words are what lies between spaces.
double readerHeadingFitSize(
  String text,
  TextStyle style,
  double maxWidth, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final size = style.fontSize ?? 14;
  if (!maxWidth.isFinite || maxWidth <= 0) return size;
  var widest = 0.0;
  for (final word in text.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  if (widest <= maxWidth) return size;
  return (size * maxWidth / widest).floorToDouble();
}

/// The overline's text: [label] ("Section 5 / 15") in capitals, its digits
/// in [script], and [trailing] after a "·"; either may be left out.
String readerSectionOverline(
  String? label, {
  String? trailing,
  required ReaderScript script,
}) {
  final text = [
    if (label != null) label,
    if (trailing != null) trailing,
  ].join(' · ');
  return readerNumerals(text.toUpperCase(), script);
}

class _Overline extends StatelessWidget {
  const _Overline({
    required this.text,
    required this.numeralScript,
    required this.color,
  });

  final String text;
  final ReaderScript numeralScript;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Interface text, in the app's language and its font.
    final script = ReaderScript.ofLanguage(
      Localizations.localeOf(context).languageCode,
    );
    return Text(
      text,
      style: TextStyle(
        fontSize: ReaderTypography.interfaceSize(
          SectionHeader.overlineSize,
          script,
        ),
        fontWeight: FontWeight.w600,
        letterSpacing: script == ReaderScript.latin ? 0.8 : null,
        fontFamilyFallback: readerNumeralFallback(numeralScript),
        color: color,
      ),
    );
  }
}
