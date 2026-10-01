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
                'user': {'first_name': 'Pema', 'last_name': null},
                'text': 'ok',
                'created_at': '2026-10-01T10:00:00Z',
              },
            ],
            'skip': 0,
            'limit': 20,
            'total': 21,
          }).toEntity();
      expect(page.comments.single.user.displayName, 'Pema');
      expect(page.comments.single.createdAt, isNotNull);
      expect(page.hasMore, isTrue);
    });
  });
}
