import 'package:flutter/painting.dart';
import 'package:flutter_pecha/features/texts/data/models/segment_type.dart';

/// How the reader draws a segment of each [SegmentType]; null keeps the
/// default. Front and back matter read as italics, titles as bold.
class SegmentTypeStyle {
  final FontStyle? fontStyle;
  final FontWeight? fontWeight;

  const SegmentTypeStyle({this.fontStyle, this.fontWeight});

  static const SegmentTypeStyle plain = SegmentTypeStyle();

  factory SegmentTypeStyle.of(SegmentType type) => switch (type) {
    SegmentType.frontMatter ||
    SegmentType.backMatter => const SegmentTypeStyle(
      fontStyle: FontStyle.italic,
    ),
    SegmentType.title => const SegmentTypeStyle(fontWeight: FontWeight.bold),
    SegmentType.verse ||
    SegmentType.paragraph ||
    SegmentType.topSegment ||
    SegmentType.unknown => plain,
  };
}
