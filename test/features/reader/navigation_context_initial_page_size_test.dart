import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _ids(int count) => List.generate(count, (i) => 'seg-$i');

NavigationContext _planContext(List<String>? segmentIds) => NavigationContext(
  source: NavigationSource.plan,
  planTextItems: [
    PlanTextItem.sourceReference(
      textId: 'text-1',
      title: 'Subtask',
      segmentIds: segmentIds,
    ),
  ],
  currentTextIndex: 0,
);

void main() {
  group('NavigationContext.initialPageSizeFor', () {
    test('returns null for a missing or empty range', () {
      expect(NavigationContext.initialPageSizeFor(null), isNull);
      expect(NavigationContext.initialPageSizeFor(const []), isNull);
    });

    test('returns null when the range fits in a default page', () {
      expect(
        NavigationContext.initialPageSizeFor(_ids(ReaderConstants.pageSize)),
        isNull,
      );
      expect(NavigationContext.initialPageSizeFor(_ids(1)), isNull);
    });

    test('returns the range length once it outgrows a page', () {
      final oneOver = ReaderConstants.pageSize + 1;
      expect(NavigationContext.initialPageSizeFor(_ids(oneOver)), oneOver);
      expect(NavigationContext.initialPageSizeFor(_ids(120)), 120);
    });
  });

  group('NavigationContext.initialPageSize', () {
    test('reads the current plan item\'s segment range', () {
      expect(_planContext(_ids(45)).initialPageSize, 45);
      expect(_planContext(_ids(5)).initialPageSize, isNull);
      expect(_planContext(null).initialPageSize, isNull);
    });

    test('is null when there is no current plan item', () {
      const ctx = NavigationContext(source: NavigationSource.deepLink);
      expect(ctx.initialPageSize, isNull);
    });
  });
}
