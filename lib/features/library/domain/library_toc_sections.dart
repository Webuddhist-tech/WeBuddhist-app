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
        titles: heading.title,
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

/// A verse as the outline places headings on it: where it starts in the
/// edition and the number the reader gives it.
typedef LibraryOutlineVerse = ({String id, int spanStart, int number});

/// Every heading of [toc] that holds a verse, in reading order, with the
/// first and last of [verses] it holds. [verses] are in reading order, so by
/// where they start. Headings holding none are left out, with their
/// subheadings.
List<LibraryOutlineEntry> buildTocOutline({
  required List<LibraryTocSection> toc,
  required List<LibraryOutlineVerse> verses,
}) {
  final entries = <LibraryOutlineEntry>[];

  // The first verse starting at or after [offset].
  int firstFrom(int offset) {
    var low = 0;
    var high = verses.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (verses[middle].spanStart < offset) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  void walk(List<LibraryTocSection> headings, int depth, String? parentId) {
    for (final heading in headings) {
      final first = firstFrom(heading.spanStart);
      if (first >= verses.length ||
          verses[first].spanStart >= heading.spanEnd) {
        continue;
      }
      var low = verses[first].number;
      var high = low;
      for (
        var i = first;
        i < verses.length && verses[i].spanStart < heading.spanEnd;
        i++
      ) {
        final number = verses[i].number;
        if (number < low) low = number;
        if (number > high) high = number;
      }
      entries.add(
        LibraryOutlineEntry(
          id: heading.id,
          parentId: parentId,
          depth: depth,
          title: heading.title,
          segmentId: verses[first].id,
          number: low,
          endNumber: high,
          opensText: first == 0,
        ),
      );
      walk(heading.subsections, depth + 1, heading.id);
    }
  }

  walk(toc, 0, null);
  return entries;
}
