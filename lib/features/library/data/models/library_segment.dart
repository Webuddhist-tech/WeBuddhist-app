/// Code-point span of one line inside an edition's content; [end] is exclusive.
class LibraryLineSpan {
  final int start;
  final int end;

  const LibraryLineSpan({required this.start, required this.end});

  factory LibraryLineSpan.fromJson(Map<String, dynamic> json) {
    return LibraryLineSpan(
      start: json['start'] as int? ?? 0,
      end: json['end'] as int? ?? 0,
    );
  }
}

/// A segment; related ones also carry `edition_id` and `text_id`.
class LibrarySegment {
  final String id;
  final String type;
  final String reference;
  final List<LibraryLineSpan> lines;
  final String? segmentationId;
  final String? editionId;
  final String? textId;

  const LibrarySegment({
    required this.id,
    required this.type,
    required this.reference,
    required this.lines,
    this.segmentationId,
    this.editionId,
    this.textId,
  });

  factory LibrarySegment.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? const [];
    return LibrarySegment(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      reference: json['reference']?.toString() ?? '',
      lines:
          rawLines
              .whereType<Map<String, dynamic>>()
              .map(LibraryLineSpan.fromJson)
              .toList(growable: false),
      segmentationId: json['segmentation_id'] as String?,
      editionId: json['edition_id'] as String?,
      textId: json['text_id'] as String?,
    );
  }

  int? get spanStart => lines.isEmpty ? null : lines.first.start;

  int? get spanEnd => lines.isEmpty ? null : lines.last.end;

  @override
  bool operator ==(Object other) => other is LibrarySegment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class LibrarySegmentPage {
  final List<LibrarySegment> items;
  final bool hasMore;
  final int offset;
  final int limit;

  const LibrarySegmentPage({
    required this.items,
    required this.hasMore,
    required this.offset,
    required this.limit,
  });

  factory LibrarySegmentPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return LibrarySegmentPage(
      items:
          rawItems
              .whereType<Map<String, dynamic>>()
              .map(LibrarySegment.fromJson)
              .toList(growable: false),
      hasMore: json['has_more'] as bool? ?? false,
      offset: json['offset'] as int? ?? 0,
      limit: json['limit'] as int? ?? rawItems.length,
    );
  }
}
