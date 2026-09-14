import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/domain/services/navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A three-item collection whose middle chant has no stored language.
List<PlanTextItem> _items() => [
  PlanTextItem.sourceReference(
    textId: 'text-bo',
    title: 'Tibetan chant',
    language: 'bo',
    subtaskId: 'chant-1',
  ),
  PlanTextItem.sourceReference(
    textId: 'text-none',
    title: 'Chant without a language',
    subtaskId: 'chant-2',
  ),
  PlanTextItem.sourceReference(
    textId: 'text-en',
    title: 'English chant',
    language: 'en',
    subtaskId: 'chant-3',
  ),
];

NavigationContext _contextAt(int index, NavigationSource source) =>
    NavigationContext(
      source: source,
      planTextItems: _items(),
      currentTextIndex: index,
      collectionId: 'collection-1',
      groupId: source == NavigationSource.groupRecitationCollection
          ? 'group-1'
          : null,
      language: _items()[index].language,
    );

void main() {
  const service = NavigationService();

  group('createNavigationContextForAdjacent - recitation collections', () {
    for (final source in [
      NavigationSource.groupRecitationCollection,
      NavigationSource.myRecitationCollection,
    ]) {
      test('$source keeps its own source and collection id', () {
        final next = service.createNavigationContextForAdjacent(
          _contextAt(0, source),
          SwipeDirection.next,
        );

        expect(next, isNotNull);
        expect(next!.source, source);
        expect(next.collectionId, 'collection-1');
        expect(next.currentTextIndex, 1);
      });

      test('$source carries the destination item language', () {
        final previous = service.createNavigationContextForAdjacent(
          _contextAt(2, source),
          SwipeDirection.previous,
        );

        expect(previous!.currentTextIndex, 1);
        expect(previous.language, isNull);
      });

      test('$source never inherits the departing item language', () {
        // Leaving a Tibetan chant for one with no stored language must not
        // pin the destination to 'bo' — a null language lets the reader load
        // that text's default version.
        final next = service.createNavigationContextForAdjacent(
          _contextAt(0, source),
          SwipeDirection.next,
        );
        expect(next!.language, isNull);

        // ...and an explicit language on the destination still wins.
        final onward = service.createNavigationContextForAdjacent(
          _contextAt(1, source),
          SwipeDirection.next,
        );
        expect(onward!.language, 'en');
      });
    }

    test('returns null past the ends of the collection', () {
      const source = NavigationSource.myRecitationCollection;
      expect(
        service.createNavigationContextForAdjacent(
          _contextAt(0, source),
          SwipeDirection.previous,
        ),
        isNull,
      );
      expect(
        service.createNavigationContextForAdjacent(
          _contextAt(2, source),
          SwipeDirection.next,
        ),
        isNull,
      );
    });
  });

  group('plan navigation', () {
    test('still normalises to NavigationSource.plan', () {
      final next = service.createNavigationContextForAdjacent(
        NavigationContext(
          source: NavigationSource.plan,
          planId: 'plan-1',
          dayNumber: 2,
          planTextItems: _items(),
          currentTextIndex: 0,
        ),
        SwipeDirection.next,
      );

      expect(next!.source, NavigationSource.plan);
      expect(next.planId, 'plan-1');
      expect(next.dayNumber, 2);
      expect(next.currentTextIndex, 1);
    });
  });
}
