import 'package:flutter_pecha/features/plans/presentation/utils/plan_live_pill.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a live plan task keeps the follow control while a recitation runs', () {
    expect(
      planLivePill(taskIsLive: true, followsRecitation: true),
      PlanLivePill.syncToggle,
    );
  });

  test('a live plan task shows a label when nothing is being followed', () {
    expect(
      planLivePill(taskIsLive: true, followsRecitation: false),
      PlanLivePill.staticLabel,
    );
  });

  test('a plan task that is not live hides the pill', () {
    expect(
      planLivePill(taskIsLive: false, followsRecitation: true),
      PlanLivePill.hidden,
    );
    expect(
      planLivePill(taskIsLive: false, followsRecitation: false),
      PlanLivePill.hidden,
    );
  });

  test('a screen that is not a plan task keeps the event pill', () {
    expect(
      planLivePill(taskIsLive: null, followsRecitation: true),
      PlanLivePill.syncToggle,
    );
    expect(
      planLivePill(taskIsLive: null, followsRecitation: false),
      PlanLivePill.hidden,
    );
  });

  test('plan items report their own live flag', () {
    final context = NavigationContext(
      source: NavigationSource.plan,
      planTextItems: [
        PlanTextItem.sourceReference(textId: 'a', title: 'Quiet'),
        PlanTextItem.sourceReference(textId: 'b', title: 'Live', isLive: true),
      ],
      currentTextIndex: 0,
      eventId: 'event-1',
    );

    expect(context.planTaskIsLive, isFalse);
    expect(context.isLiveRecitation, isTrue);
    expect(
      context.copyWith(currentTextIndex: 1).planTaskIsLive,
      isTrue,
    );
  });

  test('a chant opened from a plan task uses that task flag', () {
    final context = NavigationContext(
      source: NavigationSource.groupAccumulatorChant,
      groupAccumulatorId: 'acc',
      presetAccumulatorId: 'preset',
      eventId: 'event-1',
      taskIsLive: false,
    );

    expect(context.planTaskIsLive, isFalse);
    expect(context.isLiveRecitation, isTrue);
  });
}
