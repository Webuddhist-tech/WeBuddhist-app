import 'package:flutter_pecha/features/recitation/data/models/edition_live_settings.dart';

/// The round a live room is on, and how many there are when known.
typedef LiveRound = ({int current, int? total});

/// The live room's round: [roundNumber] from its position, out of the
/// rounds of the jump whose part holds the live verse ([liveVerse], by verse
/// number). [verseNumberOf] gives a jump bound's verse number when it is on
/// the page. Of several jumps holding the verse the innermost counts; when
/// none can be placed the total is unknown. Null outside a round.
LiveRound? liveRound({
  required int? roundNumber,
  required List<ReturnJump> jumps,
  required int? liveVerse,
  required int? Function(String segmentId) verseNumberOf,
}) {
  if (roundNumber == null || roundNumber < 1) return null;
  ReturnJump? holding;
  int? holdingSpan;
  if (liveVerse != null) {
    for (final jump in jumps) {
      final from = verseNumberOf(jump.toSegmentId);
      final until = verseNumberOf(jump.afterSegmentId);
      if (from == null || until == null) continue;
      if (liveVerse < from || liveVerse > until) continue;
      final span = until - from;
      if (holdingSpan == null || span < holdingSpan) {
        holding = jump;
        holdingSpan = span;
      }
    }
  }
  final times = holding?.times;
  return (
    current: roundNumber,
    total: times != null && times > 0 ? times : null,
  );
}
