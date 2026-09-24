import 'package:flutter_pecha/features/library/data/models/library_json.dart';

/// A hit from `GET /v2/content-search`.
class LibrarySearchResult {
  final String textId;
  final String editionId;
  final List<String> segmentIds;
  final String context;
  final double score;

  const LibrarySearchResult({
    required this.textId,
    required this.editionId,
    required this.segmentIds,
    required this.context,
    required this.score,
  });

  factory LibrarySearchResult.fromJson(Map<String, dynamic> json) {
    return LibrarySearchResult(
      textId: json['text_id'] as String? ?? '',
      editionId: json['edition_id'] as String? ?? '',
      segmentIds: stringListFromJson(json['segment_ids']),
      context: json['context'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}
