class ConnectPostCommentUser {
  final String? firstName;
  final String? lastName;
  final String email;
  final String? avatarUrl;

  const ConnectPostCommentUser({
    this.firstName,
    this.lastName,
    required this.email,
    this.avatarUrl,
  });

  String get displayName {
    final nameParts =
        [firstName, lastName]
            .where((part) => part != null && part.trim().isNotEmpty)
            .map((part) => _titleCase(part!.trim()))
            .toList();
    if (nameParts.isNotEmpty) return nameParts.join(' ');

    final emailLocal = email.split('@').first.trim();
    if (emailLocal.isNotEmpty) return _titleCase(emailLocal);

    return 'User';
  }

  String get mentionHandle {
    final localPart = email.split('@').first.trim().toLowerCase();
    return localPart.isEmpty ? 'user' : localPart;
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    if (value.length == 1) return value.toUpperCase();
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }
}

class ConnectPostComment {
  final String id;
  final String postId;
  final String? parentCommentId;
  final ConnectPostCommentUser user;
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final bool likedByMe;

  const ConnectPostComment({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.user,
    required this.text,
    this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  bool get isReply =>
      parentCommentId != null && parentCommentId!.trim().isNotEmpty;

  ConnectPostComment copyWith({int? likeCount, bool? likedByMe}) {
    return ConnectPostComment(
      id: id,
      postId: postId,
      parentCommentId: parentCommentId,
      user: user,
      text: text,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}

class ConnectPostCommentsPage {
  final List<ConnectPostComment> comments;
  final int skip;
  final int limit;
  final int total;

  const ConnectPostCommentsPage({
    required this.comments,
    required this.skip,
    required this.limit,
    required this.total,
  });

  bool get hasMore => skip + comments.length < total;
}
