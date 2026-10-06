import 'package:flutter_pecha/features/home/domain/entities/verse_of_day_engagement.dart';

/// Whether [comment] is the signed-in user's: by author id when the API
/// sent one, so their comments stay theirs across visits and restarts;
/// else only when it was posted from this device while the list was open.
bool isVerseCommentOwned(
  VerseOfDayComment comment, {
  required String? currentUserId,
  required Set<String> ownCommentIds,
}) {
  final authorId = comment.userId.trim();
  final userId = currentUserId?.trim() ?? '';
  if (authorId.isNotEmpty && userId.isNotEmpty) return authorId == userId;
  return ownCommentIds.contains(comment.id);
}
