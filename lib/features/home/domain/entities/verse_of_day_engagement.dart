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
  final VerseOfDayCommentUser user;
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VerseOfDayComment({
    required this.id,
    required this.verseId,
    required this.user,
    required this.text,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, verseId, user, text, createdAt, updatedAt];
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
