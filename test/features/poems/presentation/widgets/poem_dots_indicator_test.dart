import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/poems/presentation/widgets/poem_dots_indicator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/skip_layout.dart';

Widget _indicator({required int count, required int currentIndex}) {
  return PoemDotsIndicator(
    count: count,
    currentIndex: currentIndex,
    activeColor: AppColors.textPrimary,
    inactiveColor: AppColors.grey300,
  );
}

double _dotsScrollOffset(WidgetTester tester) {
  final scrollable = tester.state<ScrollableState>(
    find.descendant(
      of: find.byType(PoemDotsIndicator),
      matching: find.byType(Scrollable),
    ),
  );
  return scrollable.position.pixels;
}

void main() {
  testWidgets('does not overflow when many poems are loaded', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: _indicator(count: 40, currentIndex: 20)),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolls to the current dot when many poems are loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: _indicator(count: 200, currentIndex: 150)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_dotsScrollOffset(tester), greaterThan(0));
  });

  Widget harness({required bool skip, required int count}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SkipLayout(
            skip: skip,
            child: _indicator(count: count, currentIndex: 150),
          ),
        ),
      ),
    );
  }

  testWidgets('dots built before their first layout do not crash, and scroll '
      'to the current dot once laid out', (tester) async {
    await tester.pumpWidget(harness(skip: true, count: 200));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(harness(skip: false, count: 200));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_dotsScrollOffset(tester), greaterThan(0));
  });

  testWidgets('dots that appear while not laid out do not crash', (
    tester,
  ) async {
    await tester.pumpWidget(harness(skip: true, count: 0));
    await tester.pump();

    // Poems finish loading while the dots are still not laid out. This is
    // the didUpdateWidget path from the Crashlytics stack trace.
    await tester.pumpWidget(harness(skip: true, count: 200));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(harness(skip: false, count: 200));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_dotsScrollOffset(tester), greaterThan(0));
  });
}
