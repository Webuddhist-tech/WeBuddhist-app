import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/domain/services/section_flattener_service.dart';
import 'package:flutter_pecha/features/reader/domain/services/section_merger_service.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_test/flutter_test.dart';

Section _section(String id, List<String> segmentIds) => Section(
  id: id,
  title: id,
  sectionNumber: 1,
  segments: [
    for (final segmentId in segmentIds)
      Segment(segmentId: segmentId, segmentNumber: 1, content: segmentId),
  ],
  sections: const [],
);

/// Headers as `#id`, segments as their id.
List<String> _shape(Iterable<dynamic> items) => [
  for (final item in items)
    item.isHeader ? '#${item.section.id}' : item.segmentId as String,
];

void main() {
  const flattener = SectionFlattenerService();
  final merger = SectionMergerService(flattener: flattener);

  test('a previous page carrying a section\'s first lines moves its header up', () {
    final existing = flattener.flatten([
      _section('B', ['b3', 'b4']),
    ]);

    final merged = merger.merge(
      existing,
      [
        _section('A', ['a1']),
        _section('B', ['b1', 'b2']),
      ],
      PaginationDirection.previous,
    );

    expect(_shape(merged.items), ['#A', 'a1', '#B', 'b1', 'b2', 'b3', 'b4']);
    expect(merged.getSegmentIndex('b3'), 5);
    expect(merged.totalSegments, 5);
  });

  test('a next page keeps the header already on screen', () {
    final existing = flattener.flatten([
      _section('A', ['a1']),
      _section('B', ['b1']),
    ]);

    final merged = merger.merge(
      existing,
      [
        _section('B', ['b1', 'b2']),
        _section('C', ['c1']),
      ],
      PaginationDirection.next,
    );

    expect(_shape(merged.items), ['#A', 'a1', '#B', 'b1', 'b2', '#C', 'c1']);
    expect(merged.getSegmentIndex('c1'), 6);
  });

  test('a page with no new lines changes nothing', () {
    final existing = flattener.flatten([
      _section('B', ['b1', 'b2']),
    ]);

    final merged = merger.merge(
      existing,
      [
        _section('B', ['b1']),
      ],
      PaginationDirection.previous,
    );

    expect(identical(merged, existing), isTrue);
  });
}
