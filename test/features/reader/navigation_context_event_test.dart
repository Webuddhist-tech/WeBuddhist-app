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

  test('copyWith carries the attendee flag', () {
    const ctx = NavigationContext(
      source: NavigationSource.plan,
      eventId: 'event-1',
      isOnlineAttendee: true,
    );
    expect(ctx.copyWith(currentTextIndex: 1).isOnlineAttendee, isTrue);
  });
}
