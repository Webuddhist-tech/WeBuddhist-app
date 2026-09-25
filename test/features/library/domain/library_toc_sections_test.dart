import 'package:flutter_pecha/features/library/data/models/library_reader_models.dart';
import 'package:flutter_pecha/features/library/data/models/library_toc.dart';
import 'package:flutter_pecha/features/library/domain/library_toc_sections.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_test/flutter_test.dart';

LibraryReaderSegment _segment(String id, int start, int end) =>
    LibraryReaderSegment(
      id: id,
      reference: id,
      type: 'verse',
      number: 1,
      lines: const ['x'],
      spanStart: start,
      spanEnd: end,
    );

Segment _toSegment(LibraryReaderSegment s) =>
    Segment(segmentId: s.id, segmentNumber: s.number, content: s.html);

const _toc = [
  LibraryTocSection(
    id: 'A',
    title: {'en': 'Alpha'},
    spanStart: 0,
    spanEnd: 100,
    subsections: [
      LibraryTocSection(
        id: 'A1',
        title: {'en': 'Alpha one'},
        spanStart: 0,
        spanEnd: 40,
      ),
      LibraryTocSection(
        id: 'A2',
        title: {'bo': 'ཀ'},
        spanStart: 40,
        spanEnd: 80,
      ),
    ],
  ),
  LibraryTocSection(id: 'B', title: {'en': 'Beta'}, spanStart: 100, spanEnd: 200),
];

List<Section> _build(List<LibraryReaderSegment> segments) => buildTocSections(
  toc: _toc,
  segments: segments,
  toSegment: _toSegment,
  language: 'en',
  rootId: 'E',
);

Iterable<String> _ids(Section section) =>
    section.segments.map((s) => s.segmentId);

void main() {
  test('nests segments under the headings whose spans hold them', () {
    final sections = _build([
      _segment('s1', 0, 20),
      _segment('s2', 20, 40),
      _segment('s3', 40, 60),
      _segment('s4', 100, 150),
    ]);

    expect(sections.map((s) => s.id), ['A', 'B']);
    final alpha = sections.first;
    expect(alpha.title, 'Alpha');
    expect(alpha.sectionNumber, 1);
    expect(alpha.parentId, isNull);
    expect(alpha.segments, isEmpty);
    expect(alpha.sections!.map((s) => s.id), ['A1', 'A2']);
    expect(_ids(alpha.sections![0]), ['s1', 's2']);
    expect(_ids(alpha.sections![1]), ['s3']);
    expect(alpha.sections![0].parentId, 'A');
    expect(alpha.sections![1].sectionNumber, 2);
    // No English title: any title is better than none.
    expect(alpha.sections![1].title, 'ཀ');

    final beta = sections.last;
    expect(beta.sectionNumber, 2);
    expect(_ids(beta), ['s4']);
    expect(beta.sections, isEmpty);
  });

  test('a page leaves out headings it has nothing for', () {
    final sections = _build([_segment('s4', 100, 150)]);
    expect(sections.map((s) => s.id), ['B']);
  });

  test('segments outside every heading get a titleless section', () {
    final sections = _build([
      _segment('s3', 40, 60),
      _segment('gap', 80, 100),
      _segment('s4', 100, 150),
      _segment('tail', 200, 210),
    ]);

    expect(sections.map((s) => s.id), ['A', 'B', 'E/gap/2']);
    final tail = sections.last;
    expect(tail.title, isNull);
    expect(tail.sectionNumber, 0);
    expect(_ids(tail), ['tail']);

    final alphaChildren = sections.first.sections!;
    expect(alphaChildren.map((s) => s.id), ['A2', 'A/gap/2']);
    expect(_ids(alphaChildren.last), ['gap']);
  });

  test('the same gap gets the same id on another page', () {
    final later = _build([_segment('tail2', 210, 220)]);
    expect(later.single.id, 'E/gap/2');
  });

  test('without headings everything is one titleless section', () {
    final sections = buildTocSections(
      toc: const [],
      segments: [_segment('s1', 0, 20)],
      toSegment: _toSegment,
      language: 'en',
      rootId: 'E',
    );
    expect(sections.single.id, 'E/gap/0');
    expect(sections.single.title, isNull);
  });
}
