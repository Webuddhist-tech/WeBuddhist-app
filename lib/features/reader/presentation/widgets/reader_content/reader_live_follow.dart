/// Where the live verse is held in the text area, as a fraction of its
/// height from the top: the verse's middle sits here.
const double liveHoldFraction = 2 / 3;

/// How long a page opened following live waits for the live verse before
/// it shows as it is.
const Duration liveOpenHoldLimit = Duration(seconds: 5);

/// How long such a page, its live verse found, waits for that verse's
/// translation before it shows without it: one landing later grows the
/// verse and moves the page.
const Duration liveOpenTranslationLimit = Duration(seconds: 8);

/// Where to scroll for the live verse: the list row and the fraction of the
/// text area its top edge lands at.
typedef LiveScrollTarget = ({int index, double alignment});

/// Holds the live verse at row [index] with its middle [liveHoldFraction]
/// down the text area. Null when the page should stay where it is.
///
/// [heightFraction] is the verse's height as a fraction of the text area,
/// when it is laid out; a verse taller than the text area is aligned by its
/// top to the top. [distanceFromStart] is how far below the top of the list
/// the verse starts, as a fraction of the text area, when the start of the
/// list is laid out too: near the start, where the verse cannot reach its
/// place, the list stays at its top and the verse sits as low as it can.
///
/// After a jump brought a section heading to the top ([afterSectionJump]),
/// the verses under it are the same kind of start: the page waits while the
/// verse is above its place ([currentTop], its top edge now) rather than
/// scroll back up past the heading.
LiveScrollTarget? liveScrollTarget({
  required int index,
  double? heightFraction,
  double? distanceFromStart,
  double? currentTop,
  bool afterSectionJump = false,
}) {
  final height = heightFraction ?? 0;
  if (height >= 1) return (index: index, alignment: 0);
  final alignment = (liveHoldFraction - height / 2).clamp(0.0, 1 - height);
  if (afterSectionJump && currentTop != null && currentTop <= alignment) {
    return null;
  }
  if (distanceFromStart != null && distanceFromStart < alignment) {
    return (index: 0, alignment: 0);
  }
  return (index: index, alignment: alignment);
}

/// Whether the live verse, its edges at [top] and [bottom] as fractions of
/// the text area, shows where [liveScrollTarget] would leave it: all of it
/// on screen, or, taller than the screen, filling it from the top.
bool liveVerseInView({required double top, required double bottom}) {
  const slack = 0.01;
  if (bottom - top >= 1) return top <= slack && bottom >= 1 - slack;
  return top >= -slack && bottom <= 1 + slack;
}

/// The section the live verse was last placed in, to tell a jump by. While
/// that verse is on the page ([verseOnPage]) its section is read from the
/// page as it is now ([current]): a section's id changes as the text's
/// table of contents and translation load. Once it has left, as when a
/// jump in a whole text replaced the loaded pages, the id kept when it was
/// placed ([kept]) stands in.
String? livePreviousSection({
  required bool verseOnPage,
  String? current,
  String? kept,
}) => verseOnPage ? current : kept;

/// Whether the live position moved to a new section or a new round, so the
/// page should bring that section's heading to the top rather than hold the
/// verse. The first position after joining or rejoining is never a jump.
bool isLiveSectionJump({
  required String? previousSection,
  required String? section,
  required int? previousRound,
  required int? round,
}) {
  if (previousSection == null || section == null) return false;
  if (section != previousSection) return true;
  return previousRound != null && round != null && round != previousRound;
}
