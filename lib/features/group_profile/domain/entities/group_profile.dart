import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

enum GroupType {
  community,
  page;

  static GroupType fromApi(String? value) {
    return switch (value?.toUpperCase()) {
      'PAGE' => GroupType.page,
      _ => GroupType.community,
    };
  }

  bool get isPage => this == GroupType.page;
}

enum GroupJoinRequestStatus {
  pending,
  approved,
  rejected;

  static GroupJoinRequestStatus? fromApi(String? value) {
    return switch (value?.toUpperCase()) {
      'PENDING' => GroupJoinRequestStatus.pending,
      'APPROVED' => GroupJoinRequestStatus.approved,
      'REJECTED' => GroupJoinRequestStatus.rejected,
      _ => null,
    };
  }
}

class GroupProfileSocialLink {
  final String id;
  final String platform;
  final String url;

  const GroupProfileSocialLink({
    required this.id,
    required this.platform,
    required this.url,
  });
}

class GroupProfileSeries {
  final String id;
  final String title;
  final String? subTitle;
  final String? description;
  final ResponsiveImage? image;
  final bool featured;
  final int planCount;
  final int totalDays;
  final DateTime? startDate;
  final DateTime? endDate;
  final int enrolledCount;

  /// Whether the current user is group-enrolled for this series.
  /// - `true`: enrolled with this group
  /// - `false`: enrolled with a different group
  /// - `null`: not group-enrolled
  final bool? isGroupEnrolled;

  const GroupProfileSeries({
    required this.id,
    required this.title,
    this.subTitle,
    this.description,
    this.image,
    this.featured = false,
    this.planCount = 0,
    this.totalDays = 0,
    this.startDate,
    this.endDate,
    this.enrolledCount = 0,
    this.isGroupEnrolled,
  });
}

class GroupProfile {
  final String id;
  final String slug;
  final GroupType groupType;
  final bool isPublic;
  final String title;
  final String? subTitle;
  final String? description;
  final String? descriptionLong;
  final String? avatarUrl;
  final String? bannerUrl;
  final bool isFollowing;
  final List<String> tags;
  final List<GroupProfileSocialLink> socialLinks;
  final List<GroupProfileSeries> series;
  final int joinerCount;
  final int followerCount;
  final int memberCount;
  final GroupJoinRequestStatus? myJoinRequestStatus;

  const GroupProfile({
    required this.id,
    this.slug = '',
    this.groupType = GroupType.community,
    this.isPublic = false,
    this.title = '',
    this.subTitle,
    this.description,
    this.descriptionLong,
    this.avatarUrl,
    this.bannerUrl,
    this.isFollowing = false,
    this.tags = const [],
    this.socialLinks = const [],
    this.series = const [],
    this.joinerCount = 0,
    this.followerCount = 0,
    this.memberCount = 0,
    this.myJoinRequestStatus,
  });

  bool get isPrivateCommunity => groupType == GroupType.community && !isPublic;

  int get memberOrFollowerCount =>
      groupType.isPage ? followerCount : joinerCount;

  GroupProfile copyWith({
    bool? isFollowing,
    int? joinerCount,
    int? followerCount,
    int? memberCount,
    GroupJoinRequestStatus? myJoinRequestStatus,
  }) {
    return GroupProfile(
      id: id,
      slug: slug,
      groupType: groupType,
      isPublic: isPublic,
      title: title,
      subTitle: subTitle,
      description: description,
      descriptionLong: descriptionLong,
      avatarUrl: avatarUrl,
      bannerUrl: bannerUrl,
      isFollowing: isFollowing ?? this.isFollowing,
      tags: tags,
      socialLinks: socialLinks,
      series: series,
      joinerCount: joinerCount ?? this.joinerCount,
      followerCount: followerCount ?? this.followerCount,
      memberCount: memberCount ?? this.memberCount,
      myJoinRequestStatus: myJoinRequestStatus ?? this.myJoinRequestStatus,
    );
  }

  GroupProfile withMemberCountDelta(int delta) {
    if (delta == 0) return this;

    if (groupType.isPage) {
      return copyWith(followerCount: (followerCount + delta).clamp(0, 1 << 31));
    }

    return copyWith(
      joinerCount: (joinerCount + delta).clamp(0, 1 << 31),
      memberCount: (memberCount + delta).clamp(0, 1 << 31),
    );
  }
}
