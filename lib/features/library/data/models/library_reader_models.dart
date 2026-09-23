import 'dart:convert';

import 'package:flutter_pecha/features/library/data/models/library_segment.dart';
import 'package:flutter_pecha/features/library/data/models/library_text.dart';

const HtmlEscape _htmlEscape = HtmlEscape(HtmlEscapeMode.element);

/// Plain lines as one HTML block for the reader; blank lines dropped.
String libraryLinesToHtml(List<String> lines) {
  return lines
      .where((line) => line.isNotEmpty)
      .map(_htmlEscape.convert)
      .join('<br>');
}

/// A segment with its lines cut from the content and its reader number.
class LibraryReaderSegment {
  final String id;
  final String reference;
  final String type;
  final int number;
  final List<String> lines;

  const LibraryReaderSegment({
    required this.id,
    required this.reference,
    required this.type,
    required this.number,
    required this.lines,
  });

  String get html => libraryLinesToHtml(lines);
}

/// One page of an edition; [currentPosition] is 1-based like the old API.
class LibraryContentWindow {
  final String editionId;
  final List<LibraryReaderSegment> segments;
  final int currentPosition;
  final int totalSegments;

  const LibraryContentWindow({
    required this.editionId,
    required this.segments,
    required this.currentPosition,
    required this.totalSegments,
  });
}

enum LibraryResourceKind { commentary, version }

/// A related segment paired with the text it belongs to.
class LibraryRelatedResource {
  final LibrarySegment segment;
  final LibraryText text;

  const LibraryRelatedResource({required this.segment, required this.text});

  String get segmentId => segment.id;

  String get language => text.language;

  String get title => text.displayTitle;

  LibraryResourceKind get kind =>
      text.isCommentary
          ? LibraryResourceKind.commentary
          : LibraryResourceKind.version;
}

class LibrarySegmentResources {
  final List<LibraryRelatedResource> commentaries;
  final List<LibraryRelatedResource> versions;

  const LibrarySegmentResources({
    required this.commentaries,
    required this.versions,
  });

  List<LibraryRelatedResource> of(LibraryResourceKind kind) => switch (kind) {
    LibraryResourceKind.commentary => commentaries,
    LibraryResourceKind.version => versions,
  };
}

/// A related segment's lines plus the source of the edition it comes from.
class LibraryResourceContent {
  final List<String> lines;
  final String? source;

  const LibraryResourceContent({required this.lines, this.source});

  String get html => libraryLinesToHtml(lines);
}
