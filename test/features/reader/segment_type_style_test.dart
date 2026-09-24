import 'package:flutter/painting.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/segment_type_style.dart';
import 'package:flutter_pecha/features/texts/data/models/segment_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('front and back matter are italic', () {
    for (final type in [SegmentType.frontMatter, SegmentType.backMatter]) {
      final style = SegmentTypeStyle.of(type);
      expect(style.fontStyle, FontStyle.italic);
      expect(style.fontWeight, isNull);
    }
  });

  test('titles are bold', () {
    final style = SegmentTypeStyle.of(SegmentType.title);
    expect(style.fontWeight, FontWeight.bold);
    expect(style.fontStyle, isNull);
  });

  test('everything else keeps the default style', () {
    for (final type in [
      SegmentType.verse,
      SegmentType.paragraph,
      SegmentType.topSegment,
      SegmentType.unknown,
    ]) {
      final style = SegmentTypeStyle.of(type);
      expect(style.fontStyle, isNull);
      expect(style.fontWeight, isNull);
    }
  });
}
