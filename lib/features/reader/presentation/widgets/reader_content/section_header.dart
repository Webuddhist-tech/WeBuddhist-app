import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A table-of-contents heading; top-level ones also carry their number.
class SectionHeader extends ConsumerWidget {
  final Section section;
  final int depth;
  final String language;

  /// A rule above the title, for a heading that follows another's lines.
  final bool showDivider;

  const SectionHeader({
    super.key,
    required this.section,
    required this.depth,
    required this.language,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = section.title;
    if (title == null || title.isEmpty) return const SizedBox.shrink();

    final style = ReaderStyle.of(context, ref);
    final fontFamily = style.type.family(language);
    final script = ReaderScript.of(title, language: language);
    final metrics = style.type.heading(depth, script);

    return Padding(
      padding: EdgeInsets.only(
        left: ReaderConstants.segmentHorizontalPadding,
        right: ReaderConstants.segmentHorizontalPadding,
        top: depth == 0 ? 20 : 12,
        bottom: 12,
      ),
      child: Column(
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
          if (depth == 0 && section.sectionNumber > 0) ...[
            Text(
              '${section.sectionNumber}',
              style: TextStyle(
                fontSize: style.type.sectionNumberSize(script),
                fontFamily: fontFamily,
                color: style.palette.heading,
              ),
            ),
            Container(
              width: 40,
              height: 1.5,
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              color: style.palette.headingRule,
            ),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: metrics.fontSize,
              fontWeight: metrics.fontWeight,
              fontFamily: fontFamily,
              color: style.palette.heading,
              height: metrics.height,
            ),
          ),
        ],
      ),
    );
  }
}
