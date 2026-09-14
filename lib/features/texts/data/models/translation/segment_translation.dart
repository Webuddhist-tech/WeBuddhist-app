class SegmentTranslation {
  final String textId;
  final String title;
  final String language;
  final String? source;
  final String? license;
  final List<TranslationSegment> segments;

  SegmentTranslation({
    required this.textId,
    required this.title,
    required this.language,
    required this.segments,
    this.source,
    this.license,
  });

  factory SegmentTranslation.fromJson(Map<String, dynamic> json) {
    return SegmentTranslation(
      textId: json['text_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      language: json['language'] as String? ?? '',
      source: json['source_link'] as String? ?? json['source'] as String?,
      license: json['license'] as String?,
      segments: (json['segments'] as List<dynamic>? ?? const [])
          .map((e) => TranslationSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text_id': textId,
      'title': title,
      'language': language,
      'source_link': source,
      'license': license,
      'segments': segments.map((e) => e.toJson()).toList(),
    };
  }
}

class TranslationSegment {
  final String id;
  final String content;

  TranslationSegment({required this.id, required this.content});

  factory TranslationSegment.fromJson(Map<String, dynamic> json) {
    return TranslationSegment(
      id: json['id'] as String? ?? json['segment_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'content': content};
  }
}
