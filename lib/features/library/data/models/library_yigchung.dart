import 'package:flutter_pecha/features/library/data/models/library_segment.dart';

/// One entry of `GET /v2/editions/{id}/yigchungs`: a small-text run of the
/// edition's content; the span's end is exclusive.
class LibraryYigchung {
  final String id;
  final String editionId;
  final String textId;
  final LibraryLineSpan span;

  const LibraryYigchung({
    required this.id,
    required this.editionId,
    required this.textId,
    required this.span,
  });

  factory LibraryYigchung.fromJson(Map<String, dynamic> json) {
    final span = json['span'];
    return LibraryYigchung(
      id: json['id'] as String? ?? '',
      editionId: json['edition_id'] as String? ?? '',
      textId: json['text_id'] as String? ?? '',
      span:
          span is Map<String, dynamic>
              ? LibraryLineSpan.fromJson(span)
              : const LibraryLineSpan(start: 0, end: 0),
    );
  }
}
