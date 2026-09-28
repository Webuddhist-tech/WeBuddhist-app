import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedWithoutEvent = {
    NavigationSource.normal: ReaderLayoutContext.library,
    NavigationSource.search: ReaderLayoutContext.library,
    NavigationSource.deepLink: ReaderLayoutContext.library,
    NavigationSource.plan: ReaderLayoutContext.plan,
    NavigationSource.recitationList: ReaderLayoutContext.chant,
    NavigationSource.routine: ReaderLayoutContext.chant,
    NavigationSource.groupAccumulatorChant: ReaderLayoutContext.chant,
    NavigationSource.groupRecitationCollection: ReaderLayoutContext.chant,
    NavigationSource.myRecitationCollection: ReaderLayoutContext.chant,
  };

  test('every navigation source has a context', () {
    // A new source must be placed here on purpose, not fall into a default.
    expect(expectedWithoutEvent.keys, containsAll(NavigationSource.values));
  });

  test('no navigation context is the library', () {
    expect(readerLayoutContextOf(null), ReaderLayoutContext.library);
  });

  test('sources map to their context when there is no event', () {
    for (final entry in expectedWithoutEvent.entries) {
      expect(
        readerLayoutContextOf(NavigationContext(source: entry.key)),
        entry.value,
        reason: '${entry.key}',
      );
    }
  });

  test('an event id makes any source an event', () {
    for (final source in NavigationSource.values) {
      expect(
        readerLayoutContextOf(
          NavigationContext(source: source, eventId: 'event-1'),
        ),
        ReaderLayoutContext.event,
        reason: '$source',
      );
    }
  });

  test('an empty event id is not an event', () {
    expect(
      readerLayoutContextOf(
        const NavigationContext(source: NavigationSource.plan, eventId: ''),
      ),
      ReaderLayoutContext.plan,
    );
  });

  test('online attendees of an event are still in the event', () {
    expect(
      readerLayoutContextOf(
        const NavigationContext(
          source: NavigationSource.groupAccumulatorChant,
          eventId: 'event-1',
          isOnlineAttendee: true,
        ),
      ),
      ReaderLayoutContext.event,
    );
  });
}
