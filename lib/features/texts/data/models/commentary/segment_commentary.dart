class SegmentCommentary {
  final String textId;
  final String title;
  final List<MappedSegmentDTO> segments;
  final String language;
  final int count;
  final String? source;
  final String? license;

  /// Editions that translate this commentary, shown under its card.
  final List<SegmentCommentary> translations;

  SegmentCommentary({
    required this.textId,
    required this.title,
    required this.segments,
    required this.language,
    required this.count,
    this.source,
    this.license,
    this.translations = const [],
  });

  factory SegmentCommentary.fromJson(Map<String, dynamic> json) {
    return SegmentCommentary(
      textId: json['text_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      segments:
          json['segments'] != null
              ? (json['segments'] as List<dynamic>)
                  .map(
                    (e) => MappedSegmentDTO.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
              : <MappedSegmentDTO>[],
      language: json['language'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      source: json['source'] as String?,
      license: json['license'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text_id': textId,
      'title': title,
      'segments': segments.map((e) => e.toJson()).toList(),
      'language': language,
      'count': count,
      'source': source,
      'license': license,
    };
  }
}

class MappedSegmentDTO {
  final String segmentId;
  final String content;

  MappedSegmentDTO({required this.segmentId, required this.content});

  factory MappedSegmentDTO.fromJson(Map<String, dynamic> json) {
    return MappedSegmentDTO(
      segmentId: json['segment_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'segment_id': segmentId, 'content': content};
  }
}
