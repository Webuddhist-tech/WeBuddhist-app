import 'package:flutter_pecha/features/home/data/models/verse_of_day_engagement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VerseOfDayLikesModel', () {
    test('parses GET shape with liked_by_me', () {
      final likes =
          VerseOfDayLikesModel.fromJson({
            'verse_id': 'v1',
            'like_count': 3,
            'liked_by_me': true,
          }).toEntity();
      expect(likes.likeCount, 3);
      expect(likes.likedByMe, isTrue);
    });

    test('parses POST shape with liked', () {
      final likes =
          VerseOfDayLikesModel.fromJson({
            'verse_id': 'v1',
            'like_count': 1,
            'liked': true,
          }).toEntity();
      expect(likes.likedByMe, isTrue);
    });
  });

  group('VerseOfDayCommentsPageModel', () {
    test('parses comments and pagination', () {
      final page =
          VerseOfDayCommentsPageModel.fromJson({
            'comments': [
              {
                'id': 'c1',
                'verse_id': 'v1',
                'user_id': 'u1',
                'parent_comment_id': 'c0',
                'user': {'first_name': 'Pema', 'last_name': null},
                'text': 'ok',
                'created_at': '2026-10-01T10:00:00Z',
                'like_count': 2,
                'liked_by_me': true,
              },
            ],
            'skip': 0,
            'limit': 20,
            'total': 21,
          }).toEntity();
      expect(page.comments.single.user.displayName, 'Pema');
      expect(page.comments.single.createdAt, isNotNull);
      expect(page.comments.single.userId, 'u1');
      expect(page.comments.single.parentCommentId, 'c0');
      expect(page.comments.single.likeCount, 2);
      expect(page.comments.single.likedByMe, isTrue);
      expect(page.hasMore, isTrue);
    });
  });

  group('VerseOfDayLikersPageModel', () {
    test('parses likers and pagination', () {
      final page =
          VerseOfDayLikersPageModel.fromJson({
            'likes': [
              {
                'user_id': 'u1',
                'first_name': 'Tenzin',
                'last_name': 'Delek',
                'avatar_url': 'https://example.com/a.webp',
                'created_at': '2026-10-05T06:32:48.572677+00:00',
              },
            ],
            'skip': 0,
            'limit': 20,
            'total': 1,
          }).toEntity();
      expect(page.likers.single.userId, 'u1');
      expect(page.likers.single.user.displayName, 'Tenzin Delek');
      expect(page.hasMore, isFalse);
    });
  });
}
