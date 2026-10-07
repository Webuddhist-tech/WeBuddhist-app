import 'package:flutter_pecha/features/home/data/models/verse_of_day_engagement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VerseOfDayCommentModel', () {
    test('carries the author id through to the entity', () {
      final model = VerseOfDayCommentModel.fromJson({
        'id': 'c1',
        'verse_id': 'v1',
        'user_id': 'u1',
        'user': {'first_name': 'Pema', 'last_name': null, 'avatar_url': null},
        'text': 'Sadhu',
        'created_at': '2026-10-06T10:00:00Z',
        'like_count': 2,
        'liked_by_me': true,
      });

      expect(model.userId, 'u1');
      final entity = model.toEntity();
      expect(entity.id, 'c1');
      expect(entity.userId, 'u1');
      expect(entity.user.displayName, 'Pema');
      expect(entity.likeCount, 2);
      expect(entity.likedByMe, isTrue);
    });

    test('a missing author id parses as empty', () {
      final model = VerseOfDayCommentModel.fromJson({'id': 'c1', 'text': 'x'});

      expect(model.userId, '');
      expect(model.toEntity().userId, '');
    });
  });
}
