import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';

class ConnectPostMediaModel {
  final String id;
  final String mediaType;
  final String url;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final int? durationMs;
  final int displayOrder;
  final String? mediaKey;

  const ConnectPostMediaModel({
    required this.id,
    required this.mediaType,
    required this.url,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.durationMs,
    this.displayOrder = 0,
    this.mediaKey,
  });

  factory ConnectPostMediaModel.fromJson(Map<String, dynamic> json) {
    return ConnectPostMediaModel(
      id: json['id'] as String? ?? '',
      mediaType: json['media_type'] as String? ?? '',
      url: json['url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      durationMs: (json['duration_ms'] as num?)?.toInt(),
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      mediaKey: json['media_key'] as String?,
    );
  }

  ConnectPostMedia toEntity() {
    return ConnectPostMedia(
      id: id,
      mediaType: mediaType,
      url: url,
      thumbnailUrl: thumbnailUrl,
      width: width,
      height: height,
      durationMs: durationMs,
      displayOrder: displayOrder,
      mediaKey: mediaKey,
    );
  }
}

class ConnectPostLinkModel {
  final String id;
  final String type;
  final String url;
  final String? label;
  final int displayOrder;

  const ConnectPostLinkModel({
    required this.id,
    required this.type,
    required this.url,
    this.label,
    this.displayOrder = 0,
  });

  factory ConnectPostLinkModel.fromJson(Map<String, dynamic> json) {
    return ConnectPostLinkModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
      label: json['label'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  ConnectPostLink toEntity() {
    return ConnectPostLink(
      id: id,
      type: type,
      url: url,
      label: label,
      displayOrder: displayOrder,
    );
  }
}

class ConnectPostModel {
  final String id;
  final String groupId;
  final String groupName;
  final String? groupAvatarUrl;
  final String caption;
  final String status;
  final DateTime? publishedAt;
  final List<ConnectPostMediaModel> media;
  final List<ConnectPostLinkModel> links;
  final String creatorName;
  final String? creatorImageUrl;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool likedByMe;

  const ConnectPostModel({
    required this.id,
    required this.groupId,
    this.groupName = '',
    this.groupAvatarUrl,
    required this.caption,
    required this.status,
    this.publishedAt,
    this.media = const [],
    this.links = const [],
    required this.creatorName,
    this.creatorImageUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.createdAt,
    this.updatedAt,
    this.likedByMe = false,
  });

  factory ConnectPostModel.fromJson(Map<String, dynamic> json) {
    final mediaJson = json['media'] as List<dynamic>? ?? const [];
    final linksJson = json['links'] as List<dynamic>? ?? const [];

    return ConnectPostModel(
      id: json['id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? '',
      groupName: json['group_name'] as String? ?? '',
      groupAvatarUrl: json['group_avatar_url'] as String?,
      caption: json['caption'] as String? ?? '',
      status: json['status'] as String? ?? '',
      publishedAt: _parseDateTime(json['published_at']),
      media:
          mediaJson
              .whereType<Map<String, dynamic>>()
              .map(ConnectPostMediaModel.fromJson)
              .toList()
            ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
      links:
          linksJson
              .whereType<Map<String, dynamic>>()
              .map(ConnectPostLinkModel.fromJson)
              .toList()
            ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
      creatorName: json['creator_name'] as String? ?? '',
      creatorImageUrl: json['creator_image_url'] as String?,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      likedByMe: json['liked_by_me'] as bool? ?? false,
    );
  }

  ConnectPost toEntity() {
    return ConnectPost(
      id: id,
      groupId: groupId,
      groupName: groupName,
      groupAvatarUrl: groupAvatarUrl,
      caption: caption,
      status: status,
      publishedAt: publishedAt,
      media: media.map((item) => item.toEntity()).toList(),
      links: links.map((item) => item.toEntity()).toList(),
      creatorName: creatorName,
      creatorImageUrl: creatorImageUrl,
      likeCount: likeCount,
      commentCount: commentCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likedByMe: likedByMe,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class ConnectPostsPageModel {
  final List<ConnectPostModel> posts;
  final int skip;
  final int limit;
  final int total;

  const ConnectPostsPageModel({
    required this.posts,
    required this.skip,
    required this.limit,
    required this.total,
  });

  factory ConnectPostsPageModel.fromJson(Map<String, dynamic> json) {
    final postsJson = json['posts'] as List<dynamic>? ?? const [];
    final posts =
        postsJson
            .whereType<Map<String, dynamic>>()
            .map(ConnectPostModel.fromJson)
            .toList();

    return ConnectPostsPageModel(
      posts: posts,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? posts.length,
      total: (json['total'] as num?)?.toInt() ?? posts.length,
    );
  }

  ConnectPostsPage toEntity() {
    return ConnectPostsPage(
      posts: posts.map((post) => post.toEntity()).toList(),
      skip: skip,
      limit: limit,
      total: total,
    );
  }
}
