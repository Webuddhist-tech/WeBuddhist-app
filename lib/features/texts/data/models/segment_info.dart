class SegmentInfo {
  const SegmentInfo({
    required this.segmentId,
    required this.textId,
    required this.translations,
    required this.relatedText,
    required this.resources,
    required this.videos,
  });

  final String segmentId;
  final String textId;
  final int translations;
  final SegmentRelatedTextInfo relatedText;
  final SegmentResourcesInfo resources;
  final List<SegmentVideo> videos;

  factory SegmentInfo.fromJson(Map<String, dynamic> json) {
    final segmentInfoJson =
        json['segment_info'] as Map<String, dynamic>? ?? json;
    final videos =
        (segmentInfoJson['videos'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SegmentVideo.fromJson)
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return SegmentInfo(
      segmentId: segmentInfoJson['segment_id'] as String? ?? '',
      textId: segmentInfoJson['text_id'] as String? ?? '',
      translations: segmentInfoJson['translations'] as int? ?? 0,
      relatedText: SegmentRelatedTextInfo.fromJson(
        segmentInfoJson['related_text'] as Map<String, dynamic>? ?? const {},
      ),
      resources: SegmentResourcesInfo.fromJson(
        segmentInfoJson['resources'] as Map<String, dynamic>? ?? const {},
      ),
      videos: videos,
    );
  }
}

class SegmentRelatedTextInfo {
  const SegmentRelatedTextInfo({
    required this.commentaries,
    required this.rootText,
    this.hasRootText = false,
  });

  final int commentaries;
  final int rootText;

  /// The open text is a commentary or a translation of one, so a Root text
  /// button applies even when [rootText] is zero.
  final bool hasRootText;

  factory SegmentRelatedTextInfo.fromJson(Map<String, dynamic> json) {
    return SegmentRelatedTextInfo(
      commentaries: json['commentaries'] as int? ?? 0,
      rootText: json['root_text'] as int? ?? 0,
    );
  }
}

class SegmentResourcesInfo {
  const SegmentResourcesInfo({required this.sheets});

  final int sheets;

  factory SegmentResourcesInfo.fromJson(Map<String, dynamic> json) {
    return SegmentResourcesInfo(sheets: json['sheets'] as int? ?? 0);
  }
}

class SegmentVideo {
  const SegmentVideo({
    required this.id,
    required this.planId,
    required this.url,
    required this.videoId,
    required this.title,
    required this.displayOrder,
  });

  final String id;
  final String planId;
  final String url;
  final String videoId;
  final String title;
  final int displayOrder;

  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  factory SegmentVideo.fromJson(Map<String, dynamic> json) {
    return SegmentVideo(
      id: json['id'] as String? ?? '',
      planId: json['plan_id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      videoId: json['video_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }
}
