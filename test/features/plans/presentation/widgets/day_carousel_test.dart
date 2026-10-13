import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/day_carousel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/skip_layout.dart';

final _days = [
  for (var n = 1; n <= 30; n++) PlanDaysModel(id: 'day-$n', dayNumber: n),
];

Widget _harness({required bool skip, required int selectedDay}) {
  return MaterialApp(
    home: Scaffold(
      body: SkipLayout(
        skip: skip,
        child: DayCarousel(
          language: 'en',
          days: _days,
          startDate: DateTime(2026, 1, 1),
          selectedDay: selectedDay,
          onDaySelected: (_) {},
        ),
      ),
    ),
  );
}

double _carouselOffset(WidgetTester tester) {
  return tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(DayCarousel),
          matching: find.byType(Scrollable),
        ),
      )
      .position
      .pixels;
}

void main() {
  testWidgets('scrolls to the selected day on open', (tester) async {
    await tester.pumpWidget(_harness(skip: false, selectedDay: 20));
    await tester.pumpAndSettle();

    expect(_carouselOffset(tester), greaterThan(0));
  });

  // Crashlytics a30f692b: the post-frame scroll read maxScrollExtent from a
  // list that had been built but not yet laid out.
  testWidgets('a carousel built before its first layout does not crash, and '
      'scrolls to the selected day once laid out', (tester) async {
    await tester.pumpWidget(_harness(skip: true, selectedDay: 20));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_harness(skip: false, selectedDay: 20));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_carouselOffset(tester), greaterThan(0));
  });

  testWidgets('changing the day before the first layout does not crash', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(skip: true, selectedDay: 2));
    await tester.pump();
    await tester.pumpWidget(_harness(skip: true, selectedDay: 25));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_harness(skip: false, selectedDay: 25));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_carouselOffset(tester), greaterThan(0));
  });
}
