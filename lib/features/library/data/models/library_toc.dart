import 'package:flutter_pecha/features/library/data/models/library_json.dart';

/// A heading of an edition's table of contents; [spanEnd] is exclusive.
class LibraryTocSection {
  final String id;
  final Map<String, String> title;
  final int spanStart;
  final int spanEnd;
  final List<LibraryTocSection> subsections;

  const LibraryTocSection({
    required this.id,
    required this.title,
    required this.spanStart,
    required this.spanEnd,
    this.subsections = const [],
  });

  factory LibraryTocSection.fromJson(Map<String, dynamic> json) {
    final span = json['span'];
    final raw = json['subsections'] as List<dynamic>? ?? const [];
    return LibraryTocSection(
      id: json['id'] as String,
      title: stringMapFromJson(json['title']),
      spanStart: span is Map ? span['start'] as int? ?? 0 : 0,
      spanEnd: span is Map ? span['end'] as int? ?? 0 : 0,
      subsections:
          raw
              .whereType<Map<String, dynamic>>()
              .map(LibraryTocSection.fromJson)
              .toList(growable: false),
    );
  }

  /// Title in [language], else any title, else null.
  String? titleFor(String language) {
    final own = title[language];
    if (own != null && own.isNotEmpty) return own;
    for (final value in title.values) {
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  bool contains(int offset) => offset >= spanStart && offset < spanEnd;
}

/// A heading of an edition's table of contents placed on its verses: the
/// first verse it holds ([segmentId], numbered [number]) and the number of
/// its last ([endNumber]). [depth] is 0 for a top-level heading.
/// [opensText] when no verse comes before it.
class LibraryOutlineEntry {
  final String id;
  final String? parentId;
  final int depth;
  final Map<String, String> title;
  final String segmentId;
  final int number;
  final int endNumber;
  final bool opensText;

  const LibraryOutlineEntry({
    required this.id,
    this.parentId,
    required this.depth,
    required this.title,
    required this.segmentId,
    required this.number,
    required this.endNumber,
    this.opensText = false,
  });
}

/// One entry of `GET /v2/editions/{id}/table-of-contents`.
class LibraryTableOfContents {
  final String id;
  final String editionId;
  final String textId;
  final List<LibraryTocSection> sections;

  const LibraryTableOfContents({
    required this.id,
    required this.editionId,
    required this.textId,
    required this.sections,
  });

  factory LibraryTableOfContents.fromJson(Map<String, dynamic> json) {
    final raw = json['sections'] as List<dynamic>? ?? const [];
    return LibraryTableOfContents(
      id: json['id'] as String? ?? '',
      editionId: json['edition_id'] as String? ?? '',
      textId: json['text_id'] as String? ?? '',
      sections:
          raw
              .whereType<Map<String, dynamic>>()
              .map(LibraryTocSection.fromJson)
              .toList(growable: false),
    );
  }
}
