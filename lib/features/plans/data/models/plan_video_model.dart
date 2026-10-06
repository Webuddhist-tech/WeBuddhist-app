class PlanVideoModel {
  final String id;
  final String url;
  final String videoId;
  final String? title;
  final int displayOrder;

  PlanVideoModel({
    required this.id,
    required this.url,
    required this.videoId,
    this.title,
    required this.displayOrder,
  });

  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  factory PlanVideoModel.fromJson(Map<String, dynamic> json) {
    return PlanVideoModel(
      id: json['id'] as String,
      url: json['url'] as String,
      // Nullable on the API; EventReplays falls back to parsing the URL.
      videoId: json['video_id'] as String? ?? '',
      title: json['title'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'video_id': videoId,
      'title': title,
      'display_order': displayOrder,
    };
  }
}
