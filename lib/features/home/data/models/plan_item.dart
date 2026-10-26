import '../../domain/entities/featured_content.dart';

/// PlanItem model for JSON serialization.
///
/// This handles conversion between JSON and the FeaturedContent domain entity.
class PlanItem {
  final String label;
  final String contentType;
  final String content;
  final String? author;
  final String? imageUrl;

  PlanItem({
    required this.label,
    required this.contentType,
    required this.content,
    this.author,
    this.imageUrl,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      label: json['label'],
      contentType: json['contentType'],
      content: json['content'],
      author: json['author'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'contentType': contentType,
      'content': content,
      'author': author,
      'imageUrl': imageUrl,
    };
  }

  /// Convert to FeaturedContent domain entity.
  FeaturedContent toEntity({
    required String id,
    String? targetId,
  }) {
    // Map contentType to FeaturedContentType
    FeaturedContentType type;
    switch (contentType.toLowerCase()) {
      case 'plan':
        type = FeaturedContentType.plan;
        break;
      case 'text':
        type = FeaturedContentType.text;
        break;
      case 'recitation':
        type = FeaturedContentType.recitation;
        break;
      case 'video':
        type = FeaturedContentType.video;
        break;
      default:
        type = FeaturedContentType.plan;
    }

    return FeaturedContent(
      id: id,
      title: label,
      description: content,
      imageUrl: imageUrl ?? '',
      type: type,
      targetId: targetId,
    );
  }

  /// Create PlanItem from a FeaturedContent domain entity.
  factory PlanItem.fromEntity(FeaturedContent featuredContent) {
    // Map FeaturedContentType to contentType string
    String contentTypeStr;
    switch (featuredContent.type) {
      case FeaturedContentType.plan:
        contentTypeStr = 'plan';
        break;
      case FeaturedContentType.text:
        contentTypeStr = 'text';
        break;
      case FeaturedContentType.recitation:
        contentTypeStr = 'recitation';
        break;
      case FeaturedContentType.video:
        contentTypeStr = 'video';
        break;
    }

    return PlanItem(
      label: featuredContent.title,
      contentType: contentTypeStr,
      content: featuredContent.description,
      imageUrl: featuredContent.imageUrl.isNotEmpty ? featuredContent.imageUrl : null,
      author: null, // Not mapped from FeaturedContent
    );
  }
}

// class PlanItem {
//   final String verseText;
//   final String scriptureVideoUrl;
//   final String meditationVideoUrl;
//   final String intentionImageUrl;
//   final String bringingImageUrl;

//   PlanItem({
//     required this.verseText,
//     required this.scriptureVideoUrl,
//     required this.meditationVideoUrl,
//     required this.intentionImageUrl,
//     required this.bringingImageUrl,
//   });

//   factory PlanItem.fromJson(Map<String, dynamic> json) {
//     return PlanItem(
//       verseText: json['verseText'],
//       scriptureVideoUrl: json['scriptureVideoUrl'],
//       meditationVideoUrl: json['meditationVideoUrl'],
//       intentionImageUrl: json['intentionImageUrl'],
//       bringingImageUrl: json['bringingImageUrl'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'verseText': verseText,
//       'scriptureVideoUrl': scriptureVideoUrl,
//       'meditationVideoUrl': meditationVideoUrl,
//       'intentionImageUrl': intentionImageUrl,
//       'bringingImageUrl': bringingImageUrl,
//     };
//   }
// }

// class PlanItem {
//   final String verseText;
//   final String verseImageUrl;
//   final String scriptureVideoUrl;
//   final String meditationAudioUrl;
//   final String meditationImageUrl;
//   final List<PrayerData> prayerData;
//   final String prayerAudioUrl;
//   final String mindTrainingImageUrl;

//   PlanItem({
//     required this.verseText,
//     required this.verseImageUrl,
//     required this.scriptureVideoUrl,
//     required this.meditationAudioUrl,
//     required this.meditationImageUrl,
//     required this.prayerData,
//     required this.prayerAudioUrl,
//     required this.mindTrainingImageUrl,
//   });

//   factory PlanItem.fromJson(Map<String, dynamic> json) {
//     return PlanItem(
//       verseText: json['verseText'],
//       verseImageUrl: json['verseImageUrl'],
//       scriptureVideoUrl: json['scriptureVideoUrl'],
//       meditationAudioUrl: json['meditationAudioUrl'],
//       meditationImageUrl: json['meditationImageUrl'],
//       prayerData:
//           (json['prayerData'] as List)
//               .map((prayerData) => PrayerData.fromJson(prayerData))
//               .toList(),
//       prayerAudioUrl: json['prayerAudioUrl'],
//       mindTrainingImageUrl: json['mindTrainingImageUrl'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'verseText': verseText,
//       'verseImageUrl': verseImageUrl,
//       'scriptureVideoUrl': scriptureVideoUrl,
//       'meditationAudioUrl': meditationAudioUrl,
//       'meditationImageUrl': meditationImageUrl,
//       'prayerData':
//           prayerData.map((prayerData) => prayerData.toJson()).toList(),
//       'prayerAudioUrl': prayerAudioUrl,
//       'mindTrainingImageUrl': mindTrainingImageUrl,
//     };
//   }
// }
