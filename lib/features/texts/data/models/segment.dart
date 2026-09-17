import 'package:flutter_pecha/features/texts/data/models/translation.dart';
import '../../domain/entities/segment.dart';

class Segment {
  final String segmentId;
  final int segmentNumber;
  final String? content;
  final Translation? translation;

  /// Ids of this same line in the text's other languages, from `mappings`.
  /// Lets a live position published against one language land here.
  final List<String> mappedSegmentIds;

  const Segment({
    required this.segmentId,
    required this.segmentNumber,
    this.content,
    this.translation,
    this.mappedSegmentIds = const [],
  });

  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(
      segmentId: json['segment_id'] as String,
      segmentNumber: json['segment_number'] as int,
      content: json['content'] as String?,
      translation:
          json['translation'] != null
              ? Translation.fromJson(
                json['translation'] as Map<String, dynamic>,
              )
              : null,
      mappedSegmentIds: parseMappedSegmentIds(json['mappings']),
    );
  }

  /// Collects every segment id in a `mappings` value, whatever its shape:
  /// `{lang: id}`, `{lang: {id, ...}}`, `[{segment_id, ...}]` or `[id]`.
  static List<String> parseMappedSegmentIds(Object? raw) {
    final ids = <String>{};
    void collect(Object? node) {
      if (node is String) {
        if (node.isNotEmpty) ids.add(node);
      } else if (node is List) {
        node.forEach(collect);
      } else if (node is Map) {
        final id = node['segment_id'] ?? node['id'];
        if (id is String) {
          collect(id);
          return;
        }
        node.values.forEach(collect);
      }
    }

    collect(raw);
    return List.unmodifiable(ids);
  }

  Map<String, dynamic> toJson() {
    return {
      'segment_id': segmentId,
      'segment_number': segmentNumber,
      'content': content ?? '',
      'translation': translation?.toJson(),
      if (mappedSegmentIds.isNotEmpty) 'mappings': mappedSegmentIds,
    };
  }

  /// Convert to SegmentEntity domain entity.
  ///
  /// Maps content fields to the appropriate language fields based on
  /// the translation language. If no translation is available,
  /// uses the default content field.
  SegmentEntity toEntity() {
    // Map content to Tibetan (default)
    final tibetanContent = content ?? '';

    // Map translation based on language
    String? sanskritContent;
    String? englishContent;
    String? chineseContent;

    if (translation != null) {
      switch (translation!.language.toLowerCase()) {
        case 'sa':
        case 'sanskrit':
          sanskritContent = translation!.content;
          break;
        case 'en':
        case 'english':
          englishContent = translation!.content;
          break;
        case 'zh':
        case 'chinese':
          chineseContent = translation!.content;
          break;
      }
    }

    return SegmentEntity(
      id: segmentId,
      segmentNumber: segmentNumber,
      contentTibetan: tibetanContent,
      contentSanskrit: sanskritContent,
      contentEnglish: englishContent,
      contentChinese: chineseContent,
    );
  }

  /// Create Segment from a SegmentEntity domain entity.
  factory Segment.fromEntity(SegmentEntity entity) {
    // For simplicity, we'll create a segment with Tibetan content
    // and no translation. More sophisticated implementations could
    // determine the best language to use based on context.
    return Segment(
      segmentId: entity.id,
      segmentNumber: entity.segmentNumber,
      content: entity.contentTibetan,
      translation: null, // Will be set separately if needed
    );
  }
}
