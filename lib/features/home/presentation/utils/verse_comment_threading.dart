import 'package:flutter_pecha/features/home/domain/entities/verse_of_day_engagement.dart';

typedef VerseCommentThreadItem = ({VerseOfDayComment comment, bool isReply});

/// Newest top-level comments first, each followed by its replies oldest first.
List<VerseCommentThreadItem> threadVerseComments(
  List<VerseOfDayComment> comments,
) {
  final order = {
    for (var i = 0; i < comments.length; i++) comments[i].id: i,
  };
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  int byDate(VerseOfDayComment a, VerseOfDayComment b) {
    final byTime = (a.createdAt ?? epoch).compareTo(b.createdAt ?? epoch);
    return byTime != 0 ? byTime : order[b.id]!.compareTo(order[a.id]!);
  }

  final roots = <VerseOfDayComment>[];
  final replies = <String, List<VerseOfDayComment>>{};
  for (final comment in comments) {
    final parentId = comment.parentCommentId;
    // A reply whose parent isn't loaded stays visible as a top-level comment.
    if (parentId == null ||
        parentId == comment.id ||
        !order.containsKey(parentId)) {
      roots.add(comment);
    } else {
      replies.putIfAbsent(parentId, () => []).add(comment);
    }
  }

  final items = <VerseCommentThreadItem>[];
  void addReplies(String parentId) {
    final children = replies[parentId];
    if (children == null) return;
    for (final reply in children..sort(byDate)) {
      items.add((comment: reply, isReply: true));
      addReplies(reply.id);
    }
  }

  for (final root in roots..sort((a, b) => byDate(b, a))) {
    items.add((comment: root, isReply: false));
    addReplies(root.id);
  }
  return items;
}
