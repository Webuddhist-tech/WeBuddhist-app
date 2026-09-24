import 'package:flutter_pecha/features/library/data/models/library_reader_models.dart';
import 'package:flutter_pecha/features/library/data/models/library_toc.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';

/// Nests [segments] under the [toc] headings whose spans hold them, in reading
/// order. Headings with nothing on this page are left out; runs outside every
/// heading get a titleless section whose id is the same on every page.
List<Section> buildTocSections({
  required List<LibraryTocSection> toc,
  required List<LibraryReaderSegment> segments,
  required Segment Function(LibraryReaderSegment segment) toSegment,
  required String language,
  required String rootId,
}) {
  return _build(toc, segments, toSegment, language, gapPrefix: rootId);
}

List<Section> _build(
  List<LibraryTocSection> toc,
  List<LibraryReaderSegment> segments,
  Segment Function(LibraryReaderSegment segment) toSegment,
  String language, {
  required String gapPrefix,
  String? parentId,
}) {
  final result = <Section>[];
  var start = 0;
  while (start < segments.length) {
    final index = _headingIndex(toc, segments[start]);
    var end = start + 1;
    while (end < segments.length &&
        _headingIndex(toc, segments[end]) == index) {
      end++;
    }
    final run = segments.sublist(start, end);
    start = end;

    if (index < 0) {
      // Numbered by the headings before it, so every page names it alike.
      final preceding =
          toc.where((s) => s.spanStart <= run.first.spanStart).length;
      result.add(
        Section(
          id: '$gapPrefix/gap/$preceding',
          sectionNumber: 0,
          parentId: parentId,
          segments: run.map(toSegment).toList(growable: false),
          sections: const [],
        ),
      );
      continue;
    }

    final heading = toc[index];
    final nested = heading.subsections.isNotEmpty;
    result.add(
      Section(
        id: heading.id,
        title: heading.titleFor(language),
        sectionNumber: index + 1,
        parentId: parentId,
        segments:
            nested ? const [] : run.map(toSegment).toList(growable: false),
        sections:
            nested
                ? _build(
                  heading.subsections,
                  run,
                  toSegment,
                  language,
                  gapPrefix: heading.id,
                  parentId: heading.id,
                )
                : const [],
      ),
    );
  }
  return result;
}

int _headingIndex(List<LibraryTocSection> toc, LibraryReaderSegment segment) =>
    toc.indexWhere((s) => s.contains(segment.spanStart));
