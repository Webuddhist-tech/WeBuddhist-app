import 'package:flutter_pecha/features/home/domain/entities/verse_of_day_engagement.dart';
import 'package:flutter_pecha/features/home/presentation/utils/verse_comment_threading.dart';
import 'package:flutter_test/flutter_test.dart';

VerseOfDayComment _comment(String id, int minute, [String? parent]) =>
    VerseOfDayComment(
      id: id,
      verseId: 'v1',
      parentCommentId: parent,
      user: const VerseOfDayCommentUser(firstName: 'Pema'),
      text: id,
      createdAt: DateTime.utc(2026, 10, 6, 10, minute),
    );

void main() {
  test('replies sit under their parent, oldest first', () {
    // Server order: newest first, so replies come before their parent.
    final items = threadVerseComments([
      _comment('r2', 5, 'a'),
      _comment('b', 4),
      _comment('r1', 3, 'a'),
      _comment('a', 1),
    ]);

    expect(items.map((i) => i.comment.id), ['b', 'a', 'r1', 'r2']);
    expect(items.map((i) => i.isReply), [false, false, true, true]);
  });

  test('reply to a reply stays in the same thread', () {
    final items = threadVerseComments([
      _comment('r2', 3, 'r1'),
      _comment('r1', 2, 'a'),
      _comment('a', 1),
    ]);

    expect(items.map((i) => i.comment.id), ['a', 'r1', 'r2']);
  });

  test('reply whose parent is not loaded shows as a top-level comment', () {
    final items = threadVerseComments([_comment('r1', 2, 'gone')]);

    expect(items.single.comment.id, 'r1');
    expect(items.single.isReply, isFalse);
  });
}
