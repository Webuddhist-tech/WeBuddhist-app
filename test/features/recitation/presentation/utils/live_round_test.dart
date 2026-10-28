import 'package:flutter_pecha/features/recitation/data/models/edition_live_settings.dart';
import 'package:flutter_pecha/features/recitation/presentation/utils/live_round.dart';
import 'package:flutter_test/flutter_test.dart';

ReturnJump _jump(String key, int from, int until, int times) => ReturnJump(
  key: key,
  toSegmentId: 'v$from',
  afterSegmentId: 'v$until',
  times: times,
);

/// Verses v1..v100 are on the page, numbered as their ids say.
int? _onPage(String segmentId) => int.tryParse(segmentId.substring(1));

void main() {
  test('the jump whose part holds the live verse gives the total', () {
    expect(
      liveRound(
        roundNumber: 2,
        jumps: [_jump('a', 10, 20, 3), _jump('b', 40, 50, 7)],
        liveVerse: 45,
        verseNumberOf: _onPage,
      ),
      (current: 2, total: 7),
    );
  });

  test('of nested parts the innermost counts', () {
    expect(
      liveRound(
        roundNumber: 1,
        jumps: [_jump('outer', 1, 60, 2), _jump('inner', 20, 30, 21)],
        liveVerse: 25,
        verseNumberOf: _onPage,
      ),
      (current: 1, total: 21),
    );
  });

  test('without a part holding the verse, the total is unknown', () {
    // Outside every part.
    expect(
      liveRound(
        roundNumber: 2,
        jumps: [_jump('a', 10, 20, 3)],
        liveVerse: 30,
        verseNumberOf: _onPage,
      ),
      (current: 2, total: null),
    );
    // A bound that is not on the page.
    expect(
      liveRound(
        roundNumber: 2,
        jumps: [_jump('a', 10, 20, 3)],
        liveVerse: 15,
        verseNumberOf: (id) => id == 'v10' ? null : _onPage(id),
      ),
      (current: 2, total: null),
    );
    // No jumps fetched.
    expect(
      liveRound(
        roundNumber: 3,
        jumps: const [],
        liveVerse: 15,
        verseNumberOf: _onPage,
      ),
      (current: 3, total: null),
    );
  });

  test('a jump without rounds gives no total', () {
    expect(
      liveRound(
        roundNumber: 1,
        jumps: [_jump('a', 10, 20, 0)],
        liveVerse: 15,
        verseNumberOf: _onPage,
      ),
      (current: 1, total: null),
    );
  });

  test('outside a round there is nothing to show', () {
    for (final round in [null, 0]) {
      expect(
        liveRound(
          roundNumber: round,
          jumps: [_jump('a', 10, 20, 3)],
          liveVerse: 15,
          verseNumberOf: _onPage,
        ),
        isNull,
      );
    }
  });
}
