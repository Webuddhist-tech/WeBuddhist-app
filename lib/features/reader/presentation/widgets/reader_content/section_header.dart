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
  });

  /// Size of the overline in Latin; other scripts scale it like the chrome.
  static const double overlineSize = 11;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = section.title;
    if (title == null || title.isEmpty) return const SizedBox.shrink();

    final style = ReaderStyle.of(context, ref);
    final script = ReaderScript.of(title, language: language);
    final fontFamily = style.type.headingFamily(language, script);
    final metrics = style.type.heading(depth, script);
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
          if (place != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _Overline(
                text: readerSectionOverline(
                  context.l10n.reader_section_position(
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
          Text(
            title,
            style: TextStyle(
              fontSize: metrics.fontSize,
              fontWeight: metrics.fontWeight,
              fontFamily: fontFamily,
              color: style.palette.heading,
              height: metrics.height,
            ),
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

/// The overline's text: [label] ("Section 5 / 15") in capitals, its digits
/// in [script], and [trailing] after a "·".
String readerSectionOverline(
  String label, {
  String? trailing,
  required ReaderScript script,
}) {
  final text = trailing == null ? label : '$label · $trailing';
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
        fontSize: ReaderTypography.chromeSize(
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
