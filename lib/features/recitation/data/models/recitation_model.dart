import '../../domain/entities/recitation.dart';
import '../../domain/content_type.dart';

class RecitationModel {
  final String textId;
  final String title;
  final String? imageUrl;
  final RecitationFirstSegmentModel? firstSegment;
  final String? language;
  final int? displayOrder;

  RecitationModel({
    required this.textId,
    required this.title,
    this.imageUrl,
    this.firstSegment,
    this.language,
    this.displayOrder,
  });

  factory RecitationModel.fromJson(Map<String, dynamic> json) {
    return RecitationModel(
      textId: json['text_id'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String?,
      firstSegment:
          json['first_segment'] is Map<String, dynamic>
              ? RecitationFirstSegmentModel.fromJson(
                json['first_segment'] as Map<String, dynamic>,
              )
              : null,
      language: json['language'] as String?,
      displayOrder: json['display_order'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text_id': textId,
      'title': title,
      if (imageUrl != null) 'image_url': imageUrl,
      if (firstSegment != null) 'first_segment': firstSegment!.toJson(),
      'language': language,
      if (displayOrder != null) 'display_order': displayOrder,
    };
  }

  RecitationModel copyWith({
    String? textId,
    String? title,
    String? imageUrl,
    RecitationFirstSegmentModel? firstSegment,
    String? language,
    int? displayOrder,
  }) {
    return RecitationModel(
      textId: textId ?? this.textId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      firstSegment: firstSegment ?? this.firstSegment,
      language: language ?? this.language,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  /// Convert to Recitation domain entity.
  ///
  /// Note: RecitationModel is a summary model with limited fields.
  /// The Recitation entity has additional fields (reciterName, duration, audioUrl, etc.)
  /// that are not available in the model. These will be populated with default values
  /// or should be fetched separately when needed.
  Recitation toEntity() {
    return Recitation(
      id: textId, // Use textId as the entity id
      title: title,
      titleTibetan: null, // Not available in the model
      reciterName: 'Unknown', // Not available in the model
      duration: Duration.zero, // Not available in the model
      audioUrl: null, // Not available in the model
      contentType: ContentType.recitation, // Default to recitation type
      textId: textId,
    );
  }

  /// Create RecitationModel from a Recitation domain entity.
  factory RecitationModel.fromEntity(Recitation entity) {
    return RecitationModel(
      textId: entity.id, // Use entity id as textId
      title: entity.title,
      imageUrl: null,
      firstSegment: null,
      language: 'en', // Default to English, will be set by the caller
      displayOrder: null, // Not available in the entity
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecitationModel && other.textId == textId;
  }

  @override
  int get hashCode => textId.hashCode;

  @override
  String toString() {
    return 'RecitationModel(textId: $textId, title: $title, imageUrl: $imageUrl, firstSegment: $firstSegment, language: $language, displayOrder: $displayOrder)';
  }
}

class RecitationFirstSegmentModel {
  final String id;
  final String content;

  const RecitationFirstSegmentModel({required this.id, required this.content});

  factory RecitationFirstSegmentModel.fromJson(Map<String, dynamic> json) {
    return RecitationFirstSegmentModel(
      id: json['id'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'content': content};
  }

  @override
  String toString() {
    return 'RecitationFirstSegmentModel(id: $id, content: $content)';
  }
}

final mockRecitations = [
  RecitationModel(
    textId: '85eedd68-d56e-4086-bf0d-fd46cf9d0dfc',
    title: 'སྒྲོལ་མ་ཉེར་གཅིག་གི་བསྟོད་པ།.',
    language: 'en',
  ),
  RecitationModel(
    textId: 'abda2074-753e-4472-8864-975b1c7da0c0',
    title:
        'སྒྲོལ་མ་ཕྱག་འཚལ་ཉི་ཤུ་རྩ་གཅིག་གི་བསྟོད་པའི་རྣམ་བཤད་གསལ་བའི་འོད་ཟེར་ཞེས་བྱ་བ་བཞུགས་སོ།',
    language: 'bo',
  ),
  RecitationModel(
    textId: '607a80c5-65ac-4764-a3ca-1290de91987e',
    title: 'བསྟོད་པའི་རྣམ་བཤད་གསལ་བའི་འོད་ཟེར་བཞུགས། ',
    language: 'bo',
  ),
  RecitationModel(
    textId: 'f6d18089-518b-4720-b6dc-47c33e2df1df',
    title: 'Prayer of Dolma',
    language: 'bo',
  ),
  RecitationModel(
    textId: 'd227c1eb-68cf-4dca-ba4b-81f4d45bd1b0',
    title: 'The twenty-one praises of the Dolma are called the clear light',
    language: 'en',
  ),
  RecitationModel(
    textId: 'bf51227a-18dd-4e4b-9174-fe413ad30159',
    title: '二十一首卓玛赞歌，名为清净光明',
    language: 'zh',
  ),
];
