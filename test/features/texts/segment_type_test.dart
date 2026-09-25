import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/segment_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses every library type and falls back to unknown', () {
    expect(SegmentType.fromApi('front_matter'), SegmentType.frontMatter);
    expect(SegmentType.fromApi('back_matter'), SegmentType.backMatter);
    expect(SegmentType.fromApi('title'), SegmentType.title);
    expect(SegmentType.fromApi('verse'), SegmentType.verse);
    expect(SegmentType.fromApi('paragraph'), SegmentType.paragraph);
    expect(SegmentType.fromApi('top_segment'), SegmentType.topSegment);
    expect(SegmentType.fromApi('colophon'), SegmentType.unknown);
    expect(SegmentType.fromApi(null), SegmentType.unknown);
    expect(SegmentType.fromApi(''), SegmentType.unknown);
  });

  test('a segment keeps its type through the cache json', () {
    const segment = Segment(
      segmentId: 's',
      segmentNumber: 1,
      content: 'x',
      type: SegmentType.frontMatter,
    );
    final json = segment.toJson();
    expect(json['type'], 'front_matter');
    expect(Segment.fromJson(json).type, SegmentType.frontMatter);

    const untyped = Segment(segmentId: 's', segmentNumber: 1);
    expect(untyped.toJson().containsKey('type'), isFalse);
    expect(Segment.fromJson(untyped.toJson()).type, SegmentType.unknown);
  });
}
