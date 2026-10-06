import 'package:equatable/equatable.dart';

class VerseOfDayLikes extends Equatable {
  final String verseId;
  final int likeCount;
  final bool likedByMe;

  const VerseOfDayLikes({
    required this.verseId,
    required this.likeCount,
    required this.likedByMe,
  });

  @override
  List<Object?> get props => [verseId, likeCount, likedByMe];
}

class VerseOfDayCommentUser extends Equatable {
  final String firstName;
  final String? lastName;
  final String? avatarUrl;

  const VerseOfDayCommentUser({
    required this.firstName,
    this.lastName,
    this.avatarUrl,
  });

  String get displayName {
    final parts = [firstName, lastName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim());
    final name = parts.join(' ');
    return name.isEmpty ? 'User' : name;
  }

  @override
  List<Object?> get props => [firstName, lastName, avatarUrl];
}

class VerseOfDayComment extends Equatable {
  final String id;
  final String verseId;
  final String userId;
  final String? parentCommentId;
  final VerseOfDayCommentUser user;
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final bool likedByMe;

  const VerseOfDayComment({
    required this.id,
    required this.verseId,
    this.userId = '',
    this.parentCommentId,
    required this.user,
    required this.text,
    this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  VerseOfDayComment copyWith({int? likeCount, bool? likedByMe}) {
    return VerseOfDayComment(
      id: id,
      verseId: verseId,
      userId: userId,
      parentCommentId: parentCommentId,
      user: user,
      text: text,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  @override
  List<Object?> get props => [
    id,
    verseId,
    userId,
    parentCommentId,
    user,
    text,
    createdAt,
    updatedAt,
    likeCount,
    likedByMe,
  ];
}

class VerseOfDayCommentsPage extends Equatable {
  final List<VerseOfDayComment> comments;
  final int skip;
  final int limit;
  final int total;

  const VerseOfDayCommentsPage({
    required this.comments,
    required this.skip,
    required this.limit,
    required this.total,
  });

  bool get hasMore => skip + comments.length < total;

  @override
  List<Object?> get props => [comments, skip, limit, total];
}

class VerseOfDayLiker extends Equatable {
  final String userId;
  final VerseOfDayCommentUser user;
  final DateTime? createdAt;

  const VerseOfDayLiker({
    required this.userId,
    required this.user,
    this.createdAt,
  });

  @override
  List<Object?> get props => [userId, user, createdAt];
}

class VerseOfDayLikersPage extends Equatable {
  final List<VerseOfDayLiker> likers;
  final int skip;
  final int limit;
  final int total;

  const VerseOfDayLikersPage({
    required this.likers,
    required this.skip,
    required this.limit,
    required this.total,
  });

  bool get hasMore => skip + likers.length < total;

  @override
  List<Object?> get props => [likers, skip, limit, total];
}
