import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/domain/services/navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';

List<PlanTextItem> _items() => [
  PlanTextItem.sourceReference(textId: 't1', title: 'One', subtaskId: 'a'),
  PlanTextItem.sourceReference(textId: 't2', title: 'Two', subtaskId: 'b'),
  PlanTextItem.sourceReference(textId: 't3', title: 'Three', subtaskId: 'c'),
];

NavigationContext _plan(int index) => NavigationContext(
  source: NavigationSource.plan,
  planId: 'plan',
  dayNumber: 2,
  planTextItems: _items(),
  currentTextIndex: index,
  dayAudioUrl: 'https://audio',
  eventId: 'ev1',
);

void main() {
  const service = NavigationService();

  test('jumps forward to any index and keeps the event', () {
    final next = service.createNavigationContextForIndex(_plan(0), 2)!;
    expect(next.currentTextIndex, 2);
    expect(next.navigationDirection, SwipeDirection.next);
    expect(next.targetSegmentId, isNull);
    expect(next.planId, 'plan');
    expect(next.dayNumber, 2);
    expect(next.dayAudioUrl, 'https://audio');
    expect(next.eventId, 'ev1');
    expect(next.isLiveRecitation, isTrue);
  });

  test('jumps backward with the previous direction', () {
    final next = service.createNavigationContextForIndex(_plan(2), 0)!;
    expect(next.currentTextIndex, 0);
    expect(next.navigationDirection, SwipeDirection.previous);
  });

  test('rejects the current index and anything out of range', () {
    expect(service.createNavigationContextForIndex(_plan(1), 1), isNull);
    expect(service.createNavigationContextForIndex(_plan(1), -1), isNull);
    expect(service.createNavigationContextForIndex(_plan(1), 3), isNull);
  });

  test('adjacent navigation still carries the event through', () {
    final next = service.createNavigationContextForAdjacent(
      _plan(0),
      SwipeDirection.next,
    )!;
    expect(next.currentTextIndex, 1);
    expect(next.eventId, 'ev1');
  });

  test('collection navigation keeps its own fields and the event', () {
    final current = NavigationContext(
      source: NavigationSource.groupRecitationCollection,
      planTextItems: _items(),
      currentTextIndex: 0,
      groupId: 'g',
      collectionId: 'c',
      eventId: 'ev1',
    );
    final next = service.createNavigationContextForIndex(current, 2)!;
    expect(next.source, NavigationSource.groupRecitationCollection);
    expect(next.groupId, 'g');
    expect(next.collectionId, 'c');
    expect(next.eventId, 'ev1');
  });
}
