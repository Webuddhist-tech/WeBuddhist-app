import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';

enum ConnectFeedItemType { post, event, practice }

class ConnectFeedItem {
  final ConnectFeedItemType type;
  final DateTime? feedAt;
  final bool isJoined;
  final String groupId;
  final String groupName;
  final String? groupSlug;
  final String? groupAvatarUrl;
  final ConnectPost? post;
  final GroupEvent? event;
  final GroupPractice? practice;

  const ConnectFeedItem({
    required this.type,
    this.feedAt,
    this.isJoined = false,
    required this.groupId,
    required this.groupName,
    this.groupSlug,
    this.groupAvatarUrl,
    this.post,
    this.event,
    this.practice,
  });

  factory ConnectFeedItem.fromPractice(GroupPractice practice) {
    return ConnectFeedItem(
      type: ConnectFeedItemType.practice,
      feedAt: practice.practiceAt,
      isJoined: practice.isJoined,
      groupId: practice.groupId ?? '',
      groupName: practice.groupName ?? '',
      groupAvatarUrl: practice.groupAvatarUrl,
      practice: practice,
    );
  }

  DateTime? get sortDate {
    return switch (type) {
      ConnectFeedItemType.post =>
        feedAt ?? post?.publishedAt ?? post?.createdAt,
      ConnectFeedItemType.event => feedAt ?? event?.startDate,
      ConnectFeedItemType.practice => feedAt ?? practice?.practiceAt,
    };
  }

  String get dedupeKey => switch (type) {
    ConnectFeedItemType.post => 'post:${post?.id}',
    ConnectFeedItemType.event => 'event:${event?.id}',
    ConnectFeedItemType.practice => 'practice:$_practiceId',
  };

  String get _practiceId {
    final item = practice;
    if (item == null) return '';
    return switch (item.type) {
      GroupPracticeType.series => item.series?.id ?? '',
      GroupPracticeType.accumulator => item.accumulator?.id ?? '',
      GroupPracticeType.collection => item.collection?.id ?? '',
      GroupPracticeType.plan => item.plan?.id ?? '',
    };
  }

  ConnectFeedItem copyWithPost(ConnectPost updatedPost) {
    return ConnectFeedItem(
      type: type,
      feedAt: feedAt,
      isJoined: isJoined,
      groupId: groupId,
      groupName: groupName,
      groupSlug: groupSlug,
      groupAvatarUrl: groupAvatarUrl,
      post: updatedPost,
      event: event,
      practice: practice,
    );
  }
}

class ConnectFeedPage {
  final List<ConnectFeedItem> items;
  final int skip;
  final int limit;
  final int total;

  const ConnectFeedPage({
    required this.items,
    required this.skip,
    required this.limit,
    required this.total,
  });

  bool get hasMore => skip + items.length < total;
}
