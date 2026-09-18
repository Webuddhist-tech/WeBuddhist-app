import 'package:flutter_pecha/features/texts/data/models/commentary/parent_segment.dart';
import 'package:flutter_pecha/features/texts/data/models/translation/segment_translation.dart';

class SegmentTranslationResponse {
  final ParentSegment parentSegment;
  final List<SegmentTranslation> translations;
  final bool hasMore;

  SegmentTranslationResponse({
    required this.parentSegment,
    required this.translations,
    this.hasMore = false,
  });

  factory SegmentTranslationResponse.fromJson(Map<String, dynamic> json) {
    return SegmentTranslationResponse(
      parentSegment: ParentSegment.fromJson(json['parent_segment']),
      translations:
          (json['translations'] as List<dynamic>? ?? const [])
              .map(
                (e) => SegmentTranslation.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      hasMore: json['has_more'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_segment': parentSegment.toJson(),
      'translations': translations.map((e) => e.toJson()).toList(),
      'has_more': hasMore,
    };
  }
}
