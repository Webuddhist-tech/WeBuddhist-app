import 'package:flutter_pecha/features/plans/presentation/utils/live_tracked_plan_text.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final items = [
    PlanTextItem.sourceReference(textId: 'en-a', title: 'A'),
    PlanTextItem.sourceReference(textId: 'en-b', title: 'B'),
  ];

  test('uses the plan text when it is the live edition', () {
    expect(
      planItemIndexForLiveEditions(items: items, liveTextId: 'en-b'),
      1,
    );
  });

  test('uses the plan edition of the live text', () {
    expect(
      planItemIndexForLiveEditions(
        items: items,
        liveTextId: 'bo-b',
        editionIds: {'en-b'},
      ),
      1,
    );
  });

  test('prefers the exact plan text over another edition', () {
    expect(
      planItemIndexForLiveEditions(
        items: items,
        liveTextId: 'en-a',
        editionIds: {'en-b'},
      ),
      0,
    );
  });

  test('leaves the plan when the live text is not in the day', () {
    expect(
      planItemIndexForLiveEditions(
        items: items,
        liveTextId: 'bo-c',
        editionIds: {'en-c'},
      ),
      -1,
    );
  });
}
