import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_transliteration.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/segment_type_style.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_number.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SegmentItem extends ConsumerWidget {
  final Segment segment;
  final int depth;
  final String language;

  /// The reader this line is shown in; decides which script pick applies.
  final ReaderSettingsScope scope;
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
    required this.scope,
    this.isSelected = false,
    this.isGreyedOut = false,
    this.isLive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ReaderStyle.of(context, ref);
    final primary = primarySegmentHtml(
      ref,
      content: segment.content,
      language: language,
      scope: scope,
    );
    final typeStyle = SegmentTypeStyle.of(segment.type);

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
          color: isLive ? style.palette.liveHighlight : null,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentNumber(
                    label: segment.displayNumber,
                    language: language,
                  ),
                  // Segment content
                  SegmentHtmlWidget(
                    htmlContent: primary.html,
                    segmentIndex: segment.segmentNumber,
                    fontSize: style.type.originalSize,
                    lineHeight: style.type.verseHeight(primary.fontLanguage),
                    language: primary.fontLanguage,
                    isSelected: isSelected,
                    textColor: style.palette.text,
                    fontStyle: typeStyle.fontStyle,
                    fontWeight: typeStyle.fontWeight,
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
