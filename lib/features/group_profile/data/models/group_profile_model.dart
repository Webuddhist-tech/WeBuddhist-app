import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class GroupProfileModel {
  final String id;
  final String slug;
  final GroupType groupType;
  final bool isPublic;
  final String? avatarUrl;
  final String? bannerUrl;
  final bool isFollowing;
  final Map<String, dynamic>? metadata;
  final List<String> tags;
  final List<Map<String, dynamic>> socialLinksJson;
  final List<Map<String, dynamic>> seriesJson;
  final int joinerCount;
  final int followerCount;
  final int memberCount;
  final GroupJoinRequestStatus? myJoinRequestStatus;

  GroupProfileModel({
    required this.id,
    this.slug = '',
    this.groupType = GroupType.community,
    this.isPublic = false,
    this.avatarUrl,
    this.bannerUrl,
    this.isFollowing = false,
    this.metadata,
    this.tags = const [],
    this.socialLinksJson = const [],
    this.seriesJson = const [],
    this.joinerCount = 0,
    this.followerCount = 0,
    this.memberCount = 0,
    this.myJoinRequestStatus,
  });

  factory GroupProfileModel.fromJson(Map<String, dynamic> json) {
    return GroupProfileModel(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      groupType: GroupType.fromApi(json['group_type'] as String?),
      isPublic: json['is_public'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      isFollowing: json['is_following'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
          const [],
      socialLinksJson:
          (json['social_links'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          const [],
      seriesJson:
          (json['series'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          const [],
      joinerCount: (json['joiner_count'] as num?)?.toInt() ?? 0,
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      myJoinRequestStatus: GroupJoinRequestStatus.fromApi(
        json['my_join_request_status'] as String?,
      ),
    );
  }

  GroupProfile toEntity() {
    return GroupProfile(
      id: id,
      slug: slug,
      groupType: groupType,
      isPublic: isPublic,
      title: metadata?['title'] as String? ?? '',
      subTitle: metadata?['sub_title'] as String?,
      description: metadata?['description'] as String?,
      descriptionLong: metadata?['description_long'] as String?,
      avatarUrl: avatarUrl,
      bannerUrl: bannerUrl,
      isFollowing: isFollowing,
      tags: tags,
      socialLinks: socialLinksJson.map(_parseSocialLink).toList(),
      series: seriesJson.map(_parseSeries).toList(),
      joinerCount: joinerCount,
      followerCount: followerCount,
      memberCount: memberCount,
      myJoinRequestStatus: myJoinRequestStatus,
    );
  }

  GroupProfileSocialLink _parseSocialLink(Map<String, dynamic> json) {
    return GroupProfileSocialLink(
      id: json['id'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      url: json['url'] as String? ?? '',
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
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      enrolledCount: (json['enrolled_count'] as num?)?.toInt() ?? 0,
      isGroupEnrolled: parseNullableBool(json['is_group_enrolled']),
    );
  }

  static DateTime? parseDate(Object? value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static bool? parseNullableBool(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }
}
