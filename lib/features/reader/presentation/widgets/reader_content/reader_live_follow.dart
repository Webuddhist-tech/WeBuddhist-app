/// Where the live verse is held in the text area, as a fraction of its
/// height from the top: the verse's middle sits here.
const double liveHoldFraction = 2 / 3;

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
