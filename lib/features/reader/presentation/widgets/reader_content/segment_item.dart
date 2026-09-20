import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_number.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SegmentItem extends ConsumerWidget {
  final Segment segment;
  final int depth;
  final String language;
  final bool isSelected;
  final bool isGreyedOut;

  /// The line the puja leader is on right now.
  final bool isLive;
  final VoidCallback? onTap;

  const SegmentItem({
    super.key,
    required this.segment,
    required this.depth,
    required this.language,
    this.isSelected = false,
    this.isGreyedOut = false,
    this.isLive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final segmentHtmlContent = normalizeSegmentHtml(segment.content);

    return AnimatedOpacity(
      opacity: isGreyedOut ? 0.3 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        key: Key(segment.segmentId),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        // Square-edged so the tint reads as a band across the page.
        decoration: BoxDecoration(
          color: isLive ? liveSegmentHighlightColor(context) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(
              ReaderConstants.segmentBorderRadius,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: ReaderConstants.segmentHorizontalPadding + (depth * 8),
                right: ReaderConstants.segmentHorizontalPadding,
                top: ReaderConstants.segmentVerticalPadding,
                bottom: ReaderConstants.segmentVerticalPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentNumber(
                    segmentNumber: segment.segmentNumber,
                    fontSize: fontSize,
                    language: language,
                  ),
                  // Segment content
                  Expanded(
                    child: SegmentHtmlWidget(
                      htmlContent: segmentHtmlContent,
                      segmentIndex: segment.segmentNumber,
                      fontSize: fontSize,
                      language: language,
                      isSelected: isSelected,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tint behind the live recitation line, per theme.
Color liveSegmentHighlightColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? AppColors.liveSegmentHighlightDark
        : AppColors.liveSegmentHighlight;
