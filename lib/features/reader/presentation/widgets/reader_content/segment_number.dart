import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Segment label shown centered above segment content.
///
/// Shared by [SegmentItem] and [InterlinearSegmentItem] so both render the
/// label with identical padding, scale, and font conventions.
class SegmentNumber extends StatelessWidget {
  const SegmentNumber({
    super.key,
    required this.label,
    required this.fontSize,
    required this.language,
  });

  /// The edition's reference (e.g. `1-12`) or the segment number.
  final String label;

  /// Base content font size; the label is rendered at
  /// [ReaderConstants.segmentNumberFontScale] of this.
  final double fontSize;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize * ReaderConstants.segmentNumberFontScale,
          fontWeight: FontWeight.w500,
          fontFamily: getFontFamily(language),
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}
