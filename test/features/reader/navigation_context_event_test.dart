import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an in-person attendee follows the live recitation', () {
    const ctx = NavigationContext(
      source: NavigationSource.plan,
      eventId: 'event-1',
    );
    expect(ctx.isFromEvent, isTrue);
    expect(ctx.isLiveRecitation, isTrue);
  });

  test('an online attendee keeps the event but stays off the live socket', () {
    const ctx = NavigationContext(
      source: NavigationSource.plan,
      eventId: 'event-1',
      isOnlineAttendee: true,
    );
    expect(ctx.isFromEvent, isTrue);
    expect(ctx.isLiveRecitation, isFalse);
  });

  test('no event means neither', () {
    const ctx = NavigationContext(source: NavigationSource.plan);
    expect(ctx.isFromEvent, isFalse);
    expect(ctx.isLiveRecitation, isFalse);
  });

  group('only the event\'s first text follows the recitation', () {
    final items = [
      PlanTextItem.inlineText(content: 'Intro', title: 'Intro'),
      PlanTextItem.sourceReference(textId: 'text-a', title: 'A'),
      PlanTextItem.sourceReference(textId: 'text-b', title: 'B'),
      PlanTextItem.sourceReference(textId: 'text-a', title: 'A again'),
    ];

    NavigationContext at(int index) => NavigationContext(
      source: NavigationSource.plan,
      eventId: 'event-1',
      planTextItems: items,
      currentTextIndex: index,
    );

    test('the first text follows', () {
      expect(at(1).isLiveRecitation, isTrue);
    });

    test('later texts are read independently', () {
      expect(at(2).isLiveRecitation, isFalse);
    });

    test('another subtask on the first text follows too', () {
      expect(at(3).isLiveRecitation, isTrue);
    });

    test('non-text items before it do not follow', () {
      expect(at(0).isLiveRecitation, isFalse);
    });

    test('the event is still known on every text', () {
      expect(at(2).isFromEvent, isTrue);
    });
  });

  test('copyWith carries the attendee flag', () {
    const ctx = NavigationContext(
      source: NavigationSource.plan,
      eventId: 'event-1',
      isOnlineAttendee: true,
    );
    expect(ctx.copyWith(currentTextIndex: 1).isOnlineAttendee, isTrue);
  });
}
