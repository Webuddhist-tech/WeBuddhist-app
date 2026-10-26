import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class GroupAccumulatorModel {
  final String id;
  final String presetAccumulatorId;
  final String? textId;
  final String? mantraId;
  final String groupId;
  final String title;
  final Map<String, dynamic>? imageJson;
  final int targetCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isJoined;
  final int memberCount;
  final int totalCount;
  final int totalTodayCount;
  final Map<String, dynamic>? userJson;
  final String? description;
  final List<GroupAccumulatorLinkModel> links;

  GroupAccumulatorModel({
    required this.id,
    required this.presetAccumulatorId,
    this.textId,
    this.mantraId,
    required this.groupId,
    required this.title,
    this.imageJson,
    this.targetCount = 0,
    this.startDate,
    this.endDate,
    this.isJoined,
    this.memberCount = 0,
    this.totalCount = 0,
    this.totalTodayCount = 0,
    this.userJson,
    this.description,
    this.links = const [],
  });

  factory GroupAccumulatorModel.fromJson(Map<String, dynamic> json) {
    return GroupAccumulatorModel(
      id: json['id'] as String? ?? '',
      presetAccumulatorId: json['preset_accumulator_id'] as String? ?? '',
      textId: json['text_id'] as String?,
      mantraId: json['mantra_id'] as String?,
      groupId: json['group_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageJson: json['image'] as Map<String, dynamic>?,
      targetCount: (json['target_count'] as num?)?.toInt() ?? 0,
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      isJoined: json['is_joined'] as bool?,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      totalTodayCount: (json['total_today_count'] as num?)?.toInt() ?? 0,
      userJson: json['user'] as Map<String, dynamic>?,
      description: json['description'] as String?,
      links:
          (json['links'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(GroupAccumulatorLinkModel.fromJson)
              .toList() ??
          const [],
    );
  }

  GroupAccumulator toEntity() {
    return GroupAccumulator(
      id: id,
      presetAccumulatorId: presetAccumulatorId,
      textId: textId,
      mantraId: mantraId,
      groupId: groupId,
      title: title,
      image: imageJson != null ? ResponsiveImage.fromJson(imageJson) : null,
      targetCount: targetCount,
      startDate: startDate,
      endDate: endDate,
      isJoined: isJoined,
      memberCount: memberCount,
      totalCount: totalCount,
    );
  }

  GroupAccumulatorDetail toDetailEntity() {
    return GroupAccumulatorDetail(
      id: id,
      presetAccumulatorId: presetAccumulatorId,
      textId: textId,
      mantraId: mantraId,
      groupId: groupId,
      title: title,
      image: imageJson != null ? ResponsiveImage.fromJson(imageJson) : null,
      targetCount: targetCount,
      startDate: startDate,
      endDate: endDate,
      isJoined: isJoined,
      memberCount: memberCount,
      totalCount: totalCount,
      totalTodayCount: totalTodayCount,
      user:
          userJson != null
              ? GroupAccumulatorUserContributionModel.fromJson(
                userJson!,
              ).toEntity()
              : null,
      description: description,
      links: links.map((link) => link.toEntity()).toList(),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class GroupAccumulatorLinkModel {
  final String id;
  final String url;
  final String linkType;
  final String? videoId;
  final String title;
  final int displayOrder;

  const GroupAccumulatorLinkModel({
    required this.id,
    required this.url,
    required this.linkType,
    this.videoId,
    this.title = '',
    this.displayOrder = 0,
  });

  factory GroupAccumulatorLinkModel.fromJson(Map<String, dynamic> json) {
    return GroupAccumulatorLinkModel(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      linkType: json['link_type'] as String? ?? '',
      videoId: json['video_id'] as String?,
      title: json['title'] as String? ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  GroupAccumulatorLink toEntity() {
    return GroupAccumulatorLink(
      id: id,
      url: url,
      linkType: linkType,
      videoId: videoId,
      title: title,
      displayOrder: displayOrder,
    );
  }
}

class GroupAccumulatorUserContributionModel {
  final int totalCount;
  final int todayCount;
  final String username;
  final String? imageUrl;
  final String fullname;

  GroupAccumulatorUserContributionModel({
    this.totalCount = 0,
    this.todayCount = 0,
    this.username = '',
    this.imageUrl,
    this.fullname = '',
  });

  factory GroupAccumulatorUserContributionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return GroupAccumulatorUserContributionModel(
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      todayCount: (json['today_count'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      imageUrl: json['image'] as String?,
      fullname: json['fullname'] as String? ?? '',
    );
  }

  GroupAccumulatorUserContribution toEntity() {
    return GroupAccumulatorUserContribution(
      totalCount: totalCount,
      todayCount: todayCount,
      username: username,
      imageUrl: imageUrl,
      fullname: fullname,
    );
  }
}

class GroupAccumulatorsPageModel {
  final List<GroupAccumulatorModel> accumulators;
  final int total;
  final int skip;
  final int limit;

  GroupAccumulatorsPageModel({
    required this.accumulators,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory GroupAccumulatorsPageModel.fromJson(Map<String, dynamic> json) {
    return GroupAccumulatorsPageModel(
      accumulators:
          (json['accumulators'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(GroupAccumulatorModel.fromJson)
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
    );
  }

  GroupAccumulatorsPage toEntity() {
    return GroupAccumulatorsPage(
      accumulators: accumulators.map((item) => item.toEntity()).toList(),
      total: total,
      skip: skip,
      limit: limit,
    );
  }
}

class GroupAccumulatorMemberModel {
  final String userId;
  final String username;
  final String fullname;
  final String? avatarUrl;
  final DateTime? joinedAt;
  final int totalCount;
  final int todayCount;

  GroupAccumulatorMemberModel({
    required this.userId,
    required this.username,
    required this.fullname,
    this.avatarUrl,
    this.joinedAt,
    this.totalCount = 0,
    this.todayCount = 0,
  });

  factory GroupAccumulatorMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupAccumulatorMemberModel(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullname: json['fullname'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      joinedAt: GroupAccumulatorModel._parseDate(json['joined_at']),
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      todayCount: (json['today_count'] as num?)?.toInt() ?? 0,
    );
  }

  GroupAccumulatorMember toEntity() {
    return GroupAccumulatorMember(
      userId: userId,
      username: username,
      fullname: fullname,
      avatarUrl: avatarUrl,
      joinedAt: joinedAt,
      totalCount: totalCount,
      todayCount: todayCount,
    );
  }
}

class GroupAccumulatorMembersPageModel {
  final List<GroupAccumulatorMemberModel> members;
  final int memberCount;
  final int total;
  final int skip;
  final int limit;

  GroupAccumulatorMembersPageModel({
    required this.members,
    required this.memberCount,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory GroupAccumulatorMembersPageModel.fromJson(Map<String, dynamic> json) {
    return GroupAccumulatorMembersPageModel(
      members:
          (json['members'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(GroupAccumulatorMemberModel.fromJson)
              .toList() ??
          const [],
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
    );
  }

  GroupAccumulatorMembersPage toEntity() {
    return GroupAccumulatorMembersPage(
      members: members.map((item) => item.toEntity()).toList(),
      memberCount: memberCount,
      total: total,
      skip: skip,
      limit: limit,
    );
  }
}
