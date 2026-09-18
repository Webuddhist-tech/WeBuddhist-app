class ConnectPostMedia {
  final String id;
  final String mediaType;
  final String url;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final int? durationMs;
  final int displayOrder;

  /// Storage key, resent when a post's media list is edited.
  final String? mediaKey;

  const ConnectPostMedia({
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

  bool get isImage => mediaType.toUpperCase() == 'IMAGE';
}

class ConnectPostLink {
  final String id;
  final String type;
  final String url;
  final String? label;
  final int displayOrder;

  const ConnectPostLink({
    required this.id,
    required this.type,
    required this.url,
    this.label,
    this.displayOrder = 0,
  });
}

class ConnectPost {
  final String id;
  final String groupId;
  final String groupName;
  final String? groupAvatarUrl;
  final String caption;
  final String status;
  final DateTime? publishedAt;
  final List<ConnectPostMedia> media;
  final List<ConnectPostLink> links;
  final String creatorName;
  final String? creatorImageUrl;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool likedByMe;

  const ConnectPost({
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

  ConnectPost copyWith({
    String? caption,
    List<ConnectPostMedia>? media,
    List<ConnectPostLink>? links,
    int? likeCount,
    int? commentCount,
    DateTime? updatedAt,
    bool? likedByMe,
  }) {
    return ConnectPost(
      id: id,
      groupId: groupId,
      groupName: groupName,
      groupAvatarUrl: groupAvatarUrl,
      caption: caption ?? this.caption,
      status: status,
      publishedAt: publishedAt,
      media: media ?? this.media,
      links: links ?? this.links,
      creatorName: creatorName,
      creatorImageUrl: creatorImageUrl,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}

class ConnectPostsPage {
  final List<ConnectPost> posts;
  final int skip;
  final int limit;
  final int total;

  const ConnectPostsPage({
    required this.posts,
    required this.skip,
    required this.limit,
    required this.total,
  });

  bool get hasMore => skip + posts.length < total;
}
