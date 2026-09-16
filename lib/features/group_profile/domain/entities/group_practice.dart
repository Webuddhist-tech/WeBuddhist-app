import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

enum GroupPracticeType { accumulator, series, collection, plan }

class GroupRecitationCollectionItem extends Equatable {
  final String id;
  final String textId;
  final String title;
  final String language;
  final String type;
  final int displayOrder;

  const GroupRecitationCollectionItem({
    required this.id,
    required this.textId,
    required this.title,
    required this.language,
    required this.type,
    required this.displayOrder,
  });

  @override
  List<Object?> get props => [id, textId, title, language, type, displayOrder];
}

class GroupRecitationCollection extends Equatable {
  final String id;
  final String groupId;
  final String name;
  final String? imageUrl;
  final DateTime? createdAt;
  final int itemCount;
  final List<GroupRecitationCollectionItem> items;

  const GroupRecitationCollection({
    required this.id,
    required this.groupId,
    required this.name,
    this.imageUrl,
    this.createdAt,
    this.itemCount = 0,
    this.items = const [],
  });

  @override
  List<Object?> get props => [
    id,
    groupId,
    name,
    imageUrl,
    createdAt,
    itemCount,
    items,
  ];
}

class GroupPracticePlan extends Equatable {
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

  const GroupPracticePlan({
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

  Plan toPlan() {
    final difficulty = switch (difficultyLevel?.toUpperCase()) {
      'BEGINNER' => DifficultyLevel.beginner,
      'INTERMEDIATE' => DifficultyLevel.intermediate,
      'ADVANCED' => DifficultyLevel.advanced,
      _ => DifficultyLevel.allLevels,
    };

    return Plan(
      id: id,
      title: title,
      description: description,
      authorId: authorId ?? '',
      authorName: authorName,
      coverImage:
          imageUrl != null && imageUrl!.isNotEmpty
              ? ResponsiveImage.uniform(imageUrl!)
              : null,
      totalDays: totalDays,
      difficulty: difficulty,
      language: language,
      startDate: startDate,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    language,
    difficultyLevel,
    imageUrl,
    totalDays,
    startDate,
    seriesId,
    groupId,
    authorId,
    authorName,
  ];
}

class GroupPractice extends Equatable {
  final GroupPracticeType type;
  final DateTime? practiceAt;
  final bool isJoined;
  final String? groupId;
  final String? groupName;
  final String? groupSlug;
  final String? groupAvatarUrl;
  final GroupProfileSeries? series;
  final GroupAccumulator? accumulator;
  final GroupRecitationCollection? collection;
  final GroupPracticePlan? plan;

  const GroupPractice({
    required this.type,
    this.practiceAt,
    this.isJoined = false,
    this.groupId,
    this.groupName,
    this.groupSlug,
    this.groupAvatarUrl,
    this.series,
    this.accumulator,
    this.collection,
    this.plan,
  });

  GroupPractice copyWith({
    String? groupId,
    String? groupName,
    String? groupSlug,
    String? groupAvatarUrl,
  }) {
    return GroupPractice(
      type: type,
      practiceAt: practiceAt,
      isJoined: isJoined,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupSlug: groupSlug ?? this.groupSlug,
      groupAvatarUrl: groupAvatarUrl ?? this.groupAvatarUrl,
      series: series,
      accumulator: accumulator,
      collection: collection,
      plan: plan,
    );
  }

  @override
  List<Object?> get props => [
    type,
    practiceAt,
    isJoined,
    groupId,
    groupName,
    groupSlug,
    groupAvatarUrl,
    series,
    accumulator,
    collection,
    plan,
  ];
}

class GroupPracticesPage extends Equatable {
  final List<GroupPractice> practices;
  final int total;
  final int skip;
  final int limit;

  const GroupPracticesPage({
    required this.practices,
    required this.total,
    required this.skip,
    required this.limit,
  });

  bool get hasMore => skip + practices.length < total;

  @override
  List<Object?> get props => [practices, total, skip, limit];
}
