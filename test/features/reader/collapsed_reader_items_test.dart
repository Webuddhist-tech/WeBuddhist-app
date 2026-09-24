import 'package:flutter_pecha/features/reader/data/models/secondary_reader_state.dart';
import 'package:flutter_pecha/features/reader/domain/services/section_flattener_service.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/collapsed_reader_items.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_test/flutter_test.dart';

Segment _verse(int n) => Segment(segmentId: 's$n', segmentNumber: n);

Section _section(
  String id, {
  String? title,
  List<Segment> segments = const [],
  List<Section> sections = const [],
}) => Section(
  id: id,
  title: title,
  sectionNumber: 1,
  segments: segments,
  sections: sections,
);

/// Ritual > [Prayer: 1-2, Offering: 3-4], then an untitled run with 5.
final _content = const SectionFlattenerService().flatten([
  _section(
    'ritual',
    title: 'Ritual',
    sections: [
      _section('prayer', title: 'Prayer', segments: [_verse(1), _verse(2)]),
      _section('offering', title: 'Offering', segments: [_verse(3), _verse(4)]),
    ],
  ),
  _section('gap', segments: [_verse(5)]),
]);

List<String> _labels(Set<String> active) => [
  for (final item in collapsedReaderItems(_content, active))
    item.isHeader ? item.section!.title! : item.segmentId!,
];

SecondaryHeading _heading(String id, int depth, int start, int end) =>
    SecondaryHeading(
      section: _section(id, title: id),
      depth: depth,
      segmentNumber: start,
      endSegmentNumber: end,
    );

void main() {
  group('collapsedReaderItems', () {
    test('a range mid-section keeps the headings that enclose it', () {
      expect(_labels({'s2', 's3'}), ['Ritual', 'Prayer', 's2', 'Offering', 's3']);
    });

    test('each heading shows once, untitled runs add none', () {
      expect(_labels({'s3', 's4', 's5'}), ['Ritual', 'Offering', 's3', 's4', 's5']);
    });

    test('no active verses, no items', () {
      expect(_labels({}), isEmpty);
    });
  });

  group('collapsedTranslationHeadings', () {
    test("places the translation's enclosing headings above the first verse "
        'that needs them', () {
      final secondary = SecondaryReaderState(
        headingsBySegmentNumber: {
          1: [_heading('Ritual', 0, 1, 4), _heading('Prayer', 1, 1, 2)],
          3: [_heading('Offering', 1, 3, 4)],
        },
      );
      final items = collapsedReaderItems(_content, {'s2', 's3', 's4'});

      final headings = collapsedTranslationHeadings(items, secondary);

      expect(headings.map((k, v) => MapEntry(k, v.map((h) => h.section.id))), {
        's2': ['Ritual', 'Prayer'],
        's3': ['Offering'],
      });
    });
  });
}
