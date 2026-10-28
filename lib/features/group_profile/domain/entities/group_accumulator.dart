import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class GroupAccumulator extends Equatable {
  final String id;
  final String presetAccumulatorId;
  final String? textId;
  final String? mantraId;
  final String groupId;
  final String title;
  final ResponsiveImage? image;
  final int targetCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isJoined;
  final int memberCount;
  final int totalCount;

  const GroupAccumulator({
    required this.id,
    required this.presetAccumulatorId,
    this.textId,
    this.mantraId,
    required this.groupId,
    required this.title,
    this.image,
    this.targetCount = 0,
    this.startDate,
    this.endDate,
    this.isJoined,
    this.memberCount = 0,
    this.totalCount = 0,
  });

  bool get hasTextContent => textId != null && textId!.isNotEmpty;

  bool get hasMantraContent => mantraId != null && mantraId!.isNotEmpty;

  bool get hasJoined => isJoined == true;

  double get progressFraction {
    if (targetCount <= 0) return 0;
    return (totalCount / targetCount).clamp(0.0, 1.0);
  }

  int get progressPercent => (progressFraction * 100).round();

  @override
  List<Object?> get props => [
    id,
    presetAccumulatorId,
    textId,
    mantraId,
    groupId,
    title,
    image,
    targetCount,
    startDate,
    endDate,
    isJoined,
    memberCount,
    totalCount,
  ];
}

class GroupAccumulatorLink extends Equatable {
  final String id;
  final String url;
  final String linkType;
  final String? videoId;
  final String title;
  final int displayOrder;

  const GroupAccumulatorLink({
    required this.id,
    required this.url,
    required this.linkType,
    this.videoId,
    this.title = '',
    this.displayOrder = 0,
  });

  bool get isYoutube => linkType.toUpperCase() == 'YOUTUBE';

  @override
  List<Object?> get props => [id, url, linkType, videoId, title, displayOrder];
}

class GroupAccumulatorDetail extends GroupAccumulator {
  final int totalTodayCount;
  final GroupAccumulatorUserContribution? user;
  final String? description;
  final List<GroupAccumulatorLink> links;

  const GroupAccumulatorDetail({
    required super.id,
    required super.presetAccumulatorId,
    super.textId,
    super.mantraId,
    required super.groupId,
    required super.title,
    super.image,
    super.targetCount = 0,
    super.startDate,
    super.endDate,
    super.isJoined,
    super.memberCount = 0,
    super.totalCount = 0,
    this.totalTodayCount = 0,
    this.user,
    this.description,
    this.links = const [],
  });

  List<GroupAccumulatorLink> get youtubeLinks {
    final videos = [
      for (final link in links)
        if (link.isYoutube && link.url.trim().isNotEmpty) link,
    ]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return videos;
  }

  @override
  List<Object?> get props => [
    ...super.props,
    totalTodayCount,
    user,
    description,
    links,
  ];
}

class GroupAccumulatorUserContribution extends Equatable {
  final int totalCount;
  final int todayCount;
  final String username;
  final String? imageUrl;
  final String fullname;

  const GroupAccumulatorUserContribution({
    this.totalCount = 0,
    this.todayCount = 0,
    this.username = '',
    this.imageUrl,
    this.fullname = '',
  });

  String get displayName =>
      fullname.trim().isNotEmpty ? fullname.trim() : username;

  @override
  List<Object?> get props => [
    totalCount,
    todayCount,
    username,
    imageUrl,
    fullname,
  ];
}

class GroupAccumulatorMember extends Equatable {
  final String userId;
  final String username;
  final String fullname;
  final String? avatarUrl;
  final DateTime? joinedAt;
  final int totalCount;
  final int todayCount;

  const GroupAccumulatorMember({
    required this.userId,
    required this.username,
    required this.fullname,
    this.avatarUrl,
    this.joinedAt,
    this.totalCount = 0,
    this.todayCount = 0,
  });

  String get displayName =>
      fullname.trim().isNotEmpty ? fullname.trim() : username;

  @override
  List<Object?> get props => [
    userId,
    username,
    fullname,
    avatarUrl,
    joinedAt,
    totalCount,
    todayCount,
  ];
}

enum GroupAccumulatorMemberSort { today, total }

class GroupAccumulatorsPage extends Equatable {
  final List<GroupAccumulator> accumulators;
  final int total;
  final int skip;
  final int limit;

  const GroupAccumulatorsPage({
    required this.accumulators,
    required this.total,
    required this.skip,
    required this.limit,
  });

  @override
  List<Object?> get props => [accumulators, total, skip, limit];
}

class GroupAccumulatorMembersPage extends Equatable {
  final List<GroupAccumulatorMember> members;
  final int memberCount;
  final int total;
  final int skip;
  final int limit;

  const GroupAccumulatorMembersPage({
    required this.members,
    required this.memberCount,
    required this.total,
    required this.skip,
    required this.limit,
  });

  @override
  List<Object?> get props => [members, memberCount, total, skip, limit];
}
