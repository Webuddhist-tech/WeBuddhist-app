import 'package:flutter_pecha/features/home/domain/entities/verse_of_day_engagement.dart';

class VerseOfDayLikesModel {
  final String verseId;
  final int likeCount;
  final bool likedByMe;

  const VerseOfDayLikesModel({
    required this.verseId,
    required this.likeCount,
    required this.likedByMe,
  });

  factory VerseOfDayLikesModel.fromJson(Map<String, dynamic> json) {
    return VerseOfDayLikesModel(
      verseId: json['verse_id'] as String? ?? '',
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      // POST returns `liked`; GET returns `liked_by_me`.
      likedByMe:
          json['liked_by_me'] as bool? ?? json['liked'] as bool? ?? false,
    );
  }

  VerseOfDayLikes toEntity() {
    return VerseOfDayLikes(
      verseId: verseId,
      likeCount: likeCount,
      likedByMe: likedByMe,
    );
  }
}

class VerseOfDayCommentModel {
  final String id;
  final String verseId;
  final String firstName;
  final String? lastName;
  final String? avatarUrl;
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final bool likedByMe;

  const VerseOfDayCommentModel({
    required this.id,
    required this.verseId,
    required this.firstName,
    this.lastName,
    this.avatarUrl,
    required this.text,
    this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  factory VerseOfDayCommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userJson =
        user is Map<String, dynamic> ? user : const <String, dynamic>{};

    return VerseOfDayCommentModel(
      id: json['id'] as String? ?? '',
      verseId: json['verse_id'] as String? ?? '',
      firstName: userJson['first_name'] as String? ?? '',
      lastName: userJson['last_name'] as String?,
      avatarUrl: userJson['avatar_url'] as String?,
      text: json['text'] as String? ?? '',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
    );
  }

  VerseOfDayComment toEntity() {
    return VerseOfDayComment(
      id: id,
      verseId: verseId,
      user: VerseOfDayCommentUser(
        firstName: firstName,
        lastName: lastName,
        avatarUrl: avatarUrl,
      ),
      text: text,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likeCount: likeCount,
      likedByMe: likedByMe,
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

class VerseOfDayCommentsPageModel {
  final List<VerseOfDayCommentModel> comments;
  final int skip;
  final int limit;
  final int total;

  const VerseOfDayCommentsPageModel({
    required this.comments,
    required this.skip,
    required this.limit,
    required this.total,
  });

  factory VerseOfDayCommentsPageModel.fromJson(Map<String, dynamic> json) {
    final commentsJson = json['comments'] as List<dynamic>? ?? const [];
    final comments =
        commentsJson
            .whereType<Map<String, dynamic>>()
            .map(VerseOfDayCommentModel.fromJson)
            .toList();

    return VerseOfDayCommentsPageModel(
      comments: comments,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? comments.length,
      total: (json['total'] as num?)?.toInt() ?? comments.length,
    );
  }

  VerseOfDayCommentsPage toEntity() {
    return VerseOfDayCommentsPage(
      comments: comments.map((comment) => comment.toEntity()).toList(),
      skip: skip,
      limit: limit,
      total: total,
    );
  }
}

class VerseOfDayLikerModel {
  final String userId;
  final String firstName;
  final String? lastName;
  final String? avatarUrl;
  final DateTime? createdAt;

  const VerseOfDayLikerModel({
    required this.userId,
    required this.firstName,
    this.lastName,
    this.avatarUrl,
    this.createdAt,
  });

  factory VerseOfDayLikerModel.fromJson(Map<String, dynamic> json) {
    return VerseOfDayLikerModel(
      userId: json['user_id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  VerseOfDayLiker toEntity() {
    return VerseOfDayLiker(
      userId: userId,
      user: VerseOfDayCommentUser(
        firstName: firstName,
        lastName: lastName,
        avatarUrl: avatarUrl,
      ),
      createdAt: createdAt,
    );
  }
}

class VerseOfDayLikersPageModel {
  final List<VerseOfDayLikerModel> likers;
  final int skip;
  final int limit;
  final int total;

  const VerseOfDayLikersPageModel({
    required this.likers,
    required this.skip,
    required this.limit,
    required this.total,
  });

  factory VerseOfDayLikersPageModel.fromJson(Map<String, dynamic> json) {
    final likesJson = json['likes'] as List<dynamic>? ?? const [];
    final likers =
        likesJson
            .whereType<Map<String, dynamic>>()
            .map(VerseOfDayLikerModel.fromJson)
            .toList();

    return VerseOfDayLikersPageModel(
      likers: likers,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? likers.length,
      total: (json['total'] as num?)?.toInt() ?? likers.length,
    );
  }

  VerseOfDayLikersPage toEntity() {
    return VerseOfDayLikersPage(
      likers: likers.map((liker) => liker.toEntity()).toList(),
      skip: skip,
      limit: limit,
      total: total,
    );
  }
}
