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
/// [spanStart] and [spanEnd] place it in the edition for the table of contents.
class LibraryReaderSegment {
  final String id;
  final String reference;
  final String type;
  final int number;
  final List<String> lines;
  final int spanStart;
  final int spanEnd;

  const LibraryReaderSegment({
    required this.id,
    required this.reference,
    required this.type,
    required this.number,
    required this.lines,
    required this.spanStart,
    required this.spanEnd,
  });

  String get html => libraryLinesToHtml(lines);
}

/// One page of an edition; [currentPosition] is 1-based like the old API.
class LibraryContentWindow {
  final String editionId;
  final List<LibraryReaderSegment> segments;
  final int currentPosition;

  /// Position of the window's last segment; equals [totalSegments] once the
  /// window reaches the end, which [currentPosition] alone cannot show.
  final int lastPosition;
  final int totalSegments;

  const LibraryContentWindow({
    required this.editionId,
    required this.segments,
    required this.currentPosition,
    required this.lastPosition,
    required this.totalSegments,
  });
}

enum LibraryResourceKind { translation, commentary, rootText }

/// One edition aligned to the open segment: its text, its aligned segments in
/// reading order, and (for a commentary) the editions that translate it.
class LibraryRelatedEdition {
  final String editionId;
  final LibraryText? text;
  final List<LibrarySegment> segments;
  final List<LibraryRelatedEdition> translations;

  const LibraryRelatedEdition({
    required this.editionId,
    required this.text,
    required this.segments,
    this.translations = const [],
  });

  String get textId => text?.id ?? segments.first.textId ?? '';

  String get language => text?.language ?? '';

  String get title => text?.displayTitle ?? '';

  LibraryRelatedEdition withTranslations(List<LibraryRelatedEdition> value) =>
      LibraryRelatedEdition(
        editionId: editionId,
        text: text,
        segments: segments,
        translations: value,
      );
}

/// Related editions of a segment sorted the way the website does it: by the
/// work each text belongs to. [rootTexts] is only ever filled when the open
/// text is a commentary or a translation of one ([hasRootWork]).
class LibrarySegmentResources {
  final List<LibraryRelatedEdition> translations;
  final List<LibraryRelatedEdition> commentaries;
  final List<LibraryRelatedEdition> rootTexts;
  final bool hasRootWork;

  const LibrarySegmentResources({
    required this.translations,
    required this.commentaries,
    required this.rootTexts,
    required this.hasRootWork,
  });

  List<LibraryRelatedEdition> of(LibraryResourceKind kind) => switch (kind) {
    LibraryResourceKind.translation => translations,
    LibraryResourceKind.commentary => commentaries,
    LibraryResourceKind.rootText => rootTexts,
  };
}

/// Lines of every segment of a related edition, plus the edition's source.
class LibraryEditionContent {
  final List<List<String>> segmentLines;
  final String? source;

  const LibraryEditionContent({required this.segmentLines, this.source});

  List<String> get htmls => segmentLines.map(libraryLinesToHtml).toList();
}

/// A related segment's lines plus the source of the edition it comes from.
class LibraryResourceContent {
  final List<String> lines;
  final String? source;

  const LibraryResourceContent({required this.lines, this.source});

  String get html => libraryLinesToHtml(lines);
}
