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
