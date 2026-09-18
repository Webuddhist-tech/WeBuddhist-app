import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_transliteration.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_number.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SegmentItem extends ConsumerWidget {
  final Segment segment;
  final int depth;
  final String language;
  final bool isSelected;
  final bool isGreyedOut;
  final VoidCallback? onTap;

  const SegmentItem({
    super.key,
    required this.segment,
    required this.depth,
    required this.language,
    this.isSelected = false,
    this.isGreyedOut = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final primary = primarySegmentHtml(
      ref,
      content: segment.content,
      language: language,
    );

    return AnimatedOpacity(
      opacity: isGreyedOut ? 0.3 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        key: Key(segment.segmentId),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            ReaderConstants.segmentBorderRadius,
          ),
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
                      htmlContent: primary.html,
                      segmentIndex: segment.segmentNumber,
                      fontSize: fontSize,
                      language: primary.fontLanguage,
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
