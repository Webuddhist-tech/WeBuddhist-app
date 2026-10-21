import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_add_practice_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

const _plan = GroupEventPracticePick(
  id: 'p1',
  kind: GroupEventPracticeKind.plan,
  title: '21 Days of the 21 Taras',
);
const _series = GroupEventPracticePick(
  id: 's1',
  kind: GroupEventPracticeKind.series,
  title: 'Lamrim teachings',
);
const _collection = GroupEventPracticePick(
  id: 'c1',
  kind: GroupEventPracticeKind.collection,
  title: 'Praises to Tara',
);
const _collection2 = GroupEventPracticePick(
  id: 'c2',
  kind: GroupEventPracticeKind.collection,
  title: 'Morning chants',
);
const _acc1 = GroupEventPracticePick(
  id: 'a1',
  kind: GroupEventPracticeKind.accumulator,
  title: 'Green Tara mantra',
);
const _acc2 = GroupEventPracticePick(
  id: 'a2',
  kind: GroupEventPracticeKind.accumulator,
  title: '21 Taras recitations',
);

void main() {
  test('a series replaces the plan slot and reports it', () {
    final (next, replaced) = addPracticePick([_plan, _collection], _series);

    expect(next.map((p) => p.id), ['c1', 's1']);
    expect(replaced?.id, 'p1');
  });

  test('only one chant collection is kept', () {
    final (next, replaced) = addPracticePick([
      _collection,
      _acc1,
    ], _collection2);

    expect(next.map((p) => p.id), ['a1', 'c2']);
    expect(replaced?.id, 'c1');
  });

  test('accumulations stack and keep their count mode', () {
    final (next, replaced) = addPracticePick([
      _acc1.copyWith(countMode: GroupEventCountMode.attendees),
    ], _acc2);

    expect(replaced, isNull);
    expect(next.map((p) => p.id), ['a1', 'a2']);
    expect(next.first.countMode, GroupEventCountMode.attendees);
    expect(next.last.countMode, GroupEventCountMode.admin);
  });

  test('re-adding the same practice does not duplicate it', () {
    final (next, replaced) = addPracticePick([_plan], _plan);

    expect(next.map((p) => p.id), ['p1']);
    expect(replaced, isNull);
  });
}
