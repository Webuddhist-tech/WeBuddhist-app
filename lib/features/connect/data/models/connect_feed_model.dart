import 'package:flutter_pecha/features/connect/data/models/connect_post_model.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_practice_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';

class ConnectFeedItemModel {
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

  const ConnectFeedItemModel({
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

  factory ConnectFeedItemModel.fromJson(
    Map<String, dynamic> json, {
    required String language,
  }) {
    final typeRaw = (json['type'] as String? ?? '').toLowerCase();
    final type = switch (typeRaw) {
      'post' => ConnectFeedItemType.post,
      'practice' => ConnectFeedItemType.practice,
      _ => ConnectFeedItemType.event,
    };

    ConnectPost? post;
    if (json['post'] is Map<String, dynamic>) {
      final postJson = Map<String, dynamic>.from(
        json['post'] as Map<String, dynamic>,
      );
      final wrapperGroupName = json['group_name'] as String?;
      if ((postJson['group_name'] as String?)?.isEmpty ?? true) {
        if (wrapperGroupName != null && wrapperGroupName.isNotEmpty) {
          postJson['group_name'] = wrapperGroupName;
        }
      }
      if (postJson['group_avatar_url'] == null) {
        postJson['group_avatar_url'] = json['group_avatar_url'];
      }
      post = ConnectPostModel.fromJson(postJson).toEntity();
    }

    GroupEvent? event;
    if (json['event'] is Map<String, dynamic>) {
      final eventJson = Map<String, dynamic>.from(
        json['event'] as Map<String, dynamic>,
      );
      final wrapperGroupName = json['group_name'] as String?;
      if ((eventJson['group_name'] as String?)?.isEmpty ?? true) {
        if (wrapperGroupName != null && wrapperGroupName.isNotEmpty) {
          eventJson['group_name'] = wrapperGroupName;
        }
      }
      if (eventJson['group_avatar_url'] == null) {
        eventJson['group_avatar_url'] = json['group_avatar_url'];
      }
      event =
          GroupEventModel.fromJson(eventJson, language: language).toEntity();
    }

    GroupPractice? practice;
    if (json['practice'] is Map<String, dynamic> ||
        type == ConnectFeedItemType.practice) {
      practice = GroupPracticeModel.fromJson(json).toEntity();
    }

    return ConnectFeedItemModel(
      type: type,
      feedAt: _parseDateTime(json['feed_at'] ?? json['practice_at']),
      isJoined: json['is_joined'] as bool? ?? false,
      groupId: json['group_id'] as String? ?? '',
      groupName: json['group_name'] as String? ?? '',
      groupSlug: json['group_slug'] as String?,
      groupAvatarUrl: json['group_avatar_url'] as String?,
      post: post,
      event: event,
      practice: practice,
    );
  }

  ConnectFeedItem toEntity() {
    return ConnectFeedItem(
      type: type,
      feedAt: feedAt,
      isJoined: isJoined,
      groupId: groupId,
      groupName: groupName,
      groupSlug: groupSlug,
      groupAvatarUrl: groupAvatarUrl,
      post: post,
      event: event,
      practice: practice,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class ConnectFeedPageModel {
  final List<ConnectFeedItemModel> items;
  final int skip;
  final int limit;
  final int total;

  const ConnectFeedPageModel({
    required this.items,
    required this.skip,
    required this.limit,
    required this.total,
  });

  factory ConnectFeedPageModel.fromJson(
    Map<String, dynamic> json, {
    required String language,
  }) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    final items =
        itemsJson
            .whereType<Map<String, dynamic>>()
            .map(
              (item) => ConnectFeedItemModel.fromJson(item, language: language),
            )
            .where((item) {
              return switch (item.type) {
                ConnectFeedItemType.post => item.post != null,
                ConnectFeedItemType.event => item.event != null,
                ConnectFeedItemType.practice => item.practice != null,
              };
            })
            .toList();

    return ConnectFeedPageModel(
      items: items,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? items.length,
      total: (json['total'] as num?)?.toInt() ?? items.length,
    );
  }

  ConnectFeedPage toEntity() {
    return ConnectFeedPage(
      items: items.map((item) => item.toEntity()).toList(),
      skip: skip,
      limit: limit,
      total: total,
    );
  }
}
