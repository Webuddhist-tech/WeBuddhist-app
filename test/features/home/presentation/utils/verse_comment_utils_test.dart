import 'package:flutter_pecha/features/home/domain/entities/verse_of_day_engagement.dart';
import 'package:flutter_pecha/features/home/presentation/utils/verse_comment_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  VerseOfDayComment comment({String userId = ''}) => VerseOfDayComment(
    id: 'c1',
    verseId: 'v1',
    userId: userId,
    user: const VerseOfDayCommentUser(firstName: 'Pema'),
    text: 'Sadhu',
  );

  group('isVerseCommentOwned', () {
    test('matches the author id against the signed-in account', () {
      expect(
        isVerseCommentOwned(
          comment(userId: 'u1'),
          currentUserId: 'u1',
          ownCommentIds: const {},
        ),
        isTrue,
      );
      expect(
        isVerseCommentOwned(
          comment(userId: 'u1'),
          currentUserId: 'u2',
          ownCommentIds: const {},
        ),
        isFalse,
      );
    });

    test('an author id outranks the local posted-here mark', () {
      expect(
        isVerseCommentOwned(
          comment(userId: 'u1'),
          currentUserId: 'u2',
          ownCommentIds: const {'c1'},
        ),
        isFalse,
      );
    });

    test('falls back to the local mark when either id is missing', () {
      expect(
        isVerseCommentOwned(
          comment(),
          currentUserId: 'u1',
          ownCommentIds: const {'c1'},
        ),
        isTrue,
      );
      expect(
        isVerseCommentOwned(comment(), currentUserId: 'u1', ownCommentIds: {}),
        isFalse,
      );
      expect(
        isVerseCommentOwned(
          comment(userId: 'u1'),
          currentUserId: null,
          ownCommentIds: const {'c1'},
        ),
        isTrue,
      );
    });
  });
}
