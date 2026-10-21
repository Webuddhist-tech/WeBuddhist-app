import 'package:flutter_pecha/core/utils/audio_url.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_accumulator_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_profile_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class GroupRecitationAudioModel {
  final String id;
  final String title;
  final String assetUrl;

  GroupRecitationAudioModel({
    required this.id,
    required this.title,
    required this.assetUrl,
  });

  factory GroupRecitationAudioModel.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String?)?.trim() ?? '';
    final fileName = (json['file_name'] as String?)?.trim() ?? '';
    return GroupRecitationAudioModel(
      id: json['id'] as String? ?? '',
      title: title.isNotEmpty ? title : fileName,
      assetUrl: json['asset_url'] as String? ?? '',
    );
  }

  GroupRecitationAudio toEntity() {
    return GroupRecitationAudio(id: id, title: title, assetUrl: assetUrl);
  }
}

class GroupRecitationCollectionItemModel {
  final String id;
  final String textId;
  final String title;
  final String language;
  final String type;
  final int displayOrder;
  final List<GroupRecitationAudioModel> audio;

  GroupRecitationCollectionItemModel({
    required this.id,
    required this.textId,
    required this.title,
    required this.language,
    required this.type,
    required this.displayOrder,
    this.audio = const [],
  });

  factory GroupRecitationCollectionItemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return GroupRecitationCollectionItemModel(
      id: json['id'] as String? ?? '',
      textId: json['text_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      type: json['type'] as String? ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      audio: _parseAudio(json['audio']),
    );
  }

  /// Keeps recordings that have a playable URL. The title is kept as sent,
  /// including a trailing `.mp3`.
  static List<GroupRecitationAudioModel> _parseAudio(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(GroupRecitationAudioModel.fromJson)
        .where((audio) => hasPlayableAudio(audio.assetUrl))
        .toList();
  }

  GroupRecitationCollectionItem toEntity() {
    return GroupRecitationCollectionItem(
      id: id,
      textId: textId,
      title: title,
      language: language,
      type: type,
      displayOrder: displayOrder,
      audio: audio.map((track) => track.toEntity()).toList(),
    );
  }
}

class GroupRecitationCollectionModel {
  final String id;
  final String groupId;
  final String name;
  final String? imageUrl;
  final DateTime? createdAt;
  final int itemCount;
  final List<GroupRecitationCollectionItemModel> items;

  GroupRecitationCollectionModel({
    required this.id,
    required this.groupId,
    required this.name,
    this.imageUrl,
    this.createdAt,
    this.itemCount = 0,
    this.items = const [],
  });

  factory GroupRecitationCollectionModel.fromJson(Map<String, dynamic> json) {
    final items =
        (json['items'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(GroupRecitationCollectionItemModel.fromJson)
            .toList() ??
        const [];

    return GroupRecitationCollectionModel(
      id: json['id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['img_url'] as String?,
      createdAt: GroupProfileModel.parseDate(json['created_at']),
      itemCount: (json['item_count'] as num?)?.toInt() ?? items.length,
      items: items,
    );
  }

  GroupRecitationCollection toEntity() {
    final sortedItems = [...items]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return GroupRecitationCollection(
      id: id,
      groupId: groupId,
      name: name,
      imageUrl: imageUrl,
      createdAt: createdAt,
      itemCount: itemCount,
      items: sortedItems.map((item) => item.toEntity()).toList(),
    );
  }
}

class GroupPracticePlanModel {
  final String id;
  final String title;
  final String description;
  final String language;
  final String? difficultyLevel;
  final String? imageUrl;
  final int totalDays;
  final DateTime? startDate;
  final String? seriesId;
  final String? groupId;
  final String? authorId;
  final String? authorName;

  GroupPracticePlanModel({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    this.difficultyLevel,
    this.imageUrl,
    this.totalDays = 0,
    this.startDate,
    this.seriesId,
    this.groupId,
    this.authorId,
    this.authorName,
  });

  factory GroupPracticePlanModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final firstName = author?['firstname'] as String? ?? '';
    final lastName = author?['lastname'] as String? ?? '';
    final authorName = '$firstName $lastName'.trim();

    return GroupPracticePlanModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      difficultyLevel: json['difficulty_level'] as String?,
      imageUrl: json['image_url'] as String?,
      totalDays: (json['total_days'] as num?)?.toInt() ?? 0,
      startDate: GroupProfileModel.parseDate(json['start_date']),
      seriesId: json['series_id'] as String?,
      groupId: json['group_id'] as String?,
      authorId: author?['id'] as String?,
      authorName: authorName.isEmpty ? null : authorName,
    );
  }

  GroupPracticePlan toEntity() {
    return GroupPracticePlan(
      id: id,
      title: title,
      description: description,
      language: language,
      difficultyLevel: difficultyLevel,
      imageUrl: imageUrl,
      totalDays: totalDays,
      startDate: startDate,
      seriesId: seriesId,
      groupId: groupId,
      authorId: authorId,
      authorName: authorName,
    );
  }
}

class GroupPracticeModel {
  final GroupPracticeType type;
  final DateTime? practiceAt;
  final bool isJoined;
  final String? groupId;
  final String? groupName;
  final String? groupSlug;
  final String? groupAvatarUrl;
  final Map<String, dynamic>? seriesJson;
  final Map<String, dynamic>? accumulatorJson;
  final Map<String, dynamic>? collectionJson;
  final Map<String, dynamic>? planJson;

  GroupPracticeModel({
    required this.type,
    this.practiceAt,
    this.isJoined = false,
    this.groupId,
    this.groupName,
    this.groupSlug,
    this.groupAvatarUrl,
    this.seriesJson,
    this.accumulatorJson,
    this.collectionJson,
    this.planJson,
  });

  factory GroupPracticeModel.fromJson(Map<String, dynamic> json) {
    final typeValue = (json['type'] as String? ?? '').toLowerCase();
    final type = switch (typeValue) {
      'accumulator' => GroupPracticeType.accumulator,
      'collection' => GroupPracticeType.collection,
      'plan' => GroupPracticeType.plan,
      _ => GroupPracticeType.series,
    };

    return GroupPracticeModel(
      type: type,
      practiceAt: GroupProfileModel.parseDate(json['practice_at']),
      isJoined: json['is_joined'] as bool? ?? false,
      groupId: json['group_id'] as String?,
      groupName: json['group_name'] as String?,
      groupSlug: json['group_slug'] as String?,
      groupAvatarUrl: json['group_avatar_url'] as String?,
      seriesJson: json['series'] as Map<String, dynamic>?,
      accumulatorJson: json['accumulator'] as Map<String, dynamic>?,
      collectionJson: json['collection'] as Map<String, dynamic>?,
      planJson: json['plan'] as Map<String, dynamic>?,
    );
  }

  GroupPractice toEntity() {
    return GroupPractice(
      type: type,
      practiceAt: practiceAt,
      isJoined: isJoined,
      groupId: groupId,
      groupName: groupName,
      groupSlug: groupSlug,
      groupAvatarUrl: groupAvatarUrl,
      series: seriesJson != null ? _parseSeries(seriesJson!) : null,
      accumulator:
          accumulatorJson != null
              ? GroupAccumulatorModel.fromJson(accumulatorJson!).toEntity()
              : null,
      collection:
          collectionJson != null
              ? GroupRecitationCollectionModel.fromJson(
                collectionJson!,
              ).toEntity()
              : null,
      plan:
          planJson != null
              ? GroupPracticePlanModel.fromJson(planJson!).toEntity()
              : null,
    );
  }

  GroupProfileSeries _parseSeries(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>?;
    final imageJson = json['image'] as Map<String, dynamic>?;

    return GroupProfileSeries(
      id: json['id'] as String? ?? '',
      title: meta?['title'] as String? ?? '',
      subTitle: meta?['sub_title'] as String?,
      description: meta?['description'] as String?,
      image: imageJson != null ? ResponsiveImage.fromJson(imageJson) : null,
      featured: json['featured'] as bool? ?? false,
      planCount: (json['plan_count'] as num?)?.toInt() ?? 0,
      totalDays: (json['total_days'] as num?)?.toInt() ?? 0,
      startDate: GroupProfileModel.parseDate(json['start_date']),
      endDate: GroupProfileModel.parseDate(json['end_date']),
      enrolledCount: (json['enrolled_count'] as num?)?.toInt() ?? 0,
      isGroupEnrolled: GroupProfileModel.parseNullableBool(
        json['is_group_enrolled'],
      ),
    );
  }
}

class GroupPracticesPageModel {
  final List<GroupPracticeModel> practices;
  final int total;
  final int skip;
  final int limit;

  GroupPracticesPageModel({
    required this.practices,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory GroupPracticesPageModel.fromJson(Map<String, dynamic> json) {
    return GroupPracticesPageModel(
      practices:
          (json['practices'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(GroupPracticeModel.fromJson)
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
    );
  }

  GroupPracticesPage toEntity() {
    return GroupPracticesPage(
      practices: practices.map((item) => item.toEntity()).toList(),
      total: total,
      skip: skip,
      limit: limit,
    );
  }
}
