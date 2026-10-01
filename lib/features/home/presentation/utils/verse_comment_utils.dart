import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day_engagement.dart';

/// The API returns only the author's name, so ownership is the comments
/// posted from this device plus a name match with the signed-in user.
bool isVerseCommentOwnedBy({
  required VerseOfDayComment comment,
  required User? currentUser,
  required Set<String> ownCommentIds,
}) {
  if (ownCommentIds.contains(comment.id)) return true;
  if (currentUser == null) return false;

  final first = _normalize(currentUser.firstName);
  if (first.isEmpty || first != _normalize(comment.user.firstName)) {
    return false;
  }
  return _normalize(currentUser.lastName) == _normalize(comment.user.lastName);
}

String _normalize(String? value) => (value ?? '').trim().toLowerCase();
