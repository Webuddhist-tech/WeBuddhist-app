import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// The entry of the verse at the top of the text, among the entries
/// [isVerse] accepts: the first one on screen, or the one cut off above it
/// while at least half of it still shows. Null when none is on screen.
///
/// With a verse's sheet open this is the verse the sheet follows as the
/// person scrolls; a tapped verse is brought to the top, so it is also the
/// tapped one.
int? readerTopVerseEntry(
  Iterable<ItemPosition> positions,
  bool Function(int index) isVerse,
) {
  final onScreen =
      positions
          .where(
            (p) =>
                p.itemTrailingEdge > 0 &&
                p.itemLeadingEdge < 1 &&
                isVerse(p.index),
          )
          .toList()
        ..sort((a, b) => a.index.compareTo(b.index));
  if (onScreen.isEmpty) return null;
  final first = onScreen.first;
  if (first.itemLeadingEdge >= 0 || onScreen.length == 1) return first.index;
  // Cut off at the top: still the current verse while half of it shows.
  return first.itemTrailingEdge >= -first.itemLeadingEdge
      ? first.index
      : onScreen[1].index;
}

/// Where the entry at [index] of [before] is in [after], the list rebuilt,
/// matched by [keyOf]. Null when it is still at [index], or gone.
///
/// The list keeps its place by index, so rows added above the entry at the
/// top of the screen push it down the page; it is put back by this index.
int? movedTopEntry<E>(
  List<E> before,
  List<E> after,
  int index,
  Object? Function(E entry) keyOf,
) {
  if (index < 0 || index >= before.length) return null;
  final key = keyOf(before[index]);
  if (index < after.length && keyOf(after[index]) == key) return null;
  final moved = after.indexWhere((entry) => keyOf(entry) == key);
  return moved < 0 ? null : moved;
}
