import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
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

    final fontSize = ref.watch(fontSizeProvider);
    final theme = Theme.of(context);
    final fontFamily = getFontFamily(language);
    final titleColor =
        theme.brightness == Brightness.dark
            ? AppColors.readerSectionTitleDark
            : AppColors.readerSectionTitle;
    final scale = switch (depth) {
      0 => 1.2,
      1 => 1.0,
      _ => 0.9,
    };

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
                color: theme.dividerColor,
              ),
            ),
          if (depth == 0 && section.sectionNumber > 0) ...[
            Text(
              '${section.sectionNumber}',
              style: TextStyle(
                fontSize: fontSize * 0.9,
                fontFamily: fontFamily,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            Container(
              width: 40,
              height: 1.5,
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              color: theme.textTheme.bodySmall?.color,
            ),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize * scale,
              fontWeight: FontWeight.w600,
              fontFamily: fontFamily,
              color: titleColor,
              height: getLineHeight(language),
            ),
          ),
        ],
      ),
    );
  }
}
