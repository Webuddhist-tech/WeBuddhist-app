import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/today_event_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const one = TodayEventBadgeItem(id: 'e1', name: 'tara puja', isLive: true);
  const two = TodayEventBadgeItem(id: 'e2', name: 'medicine buddha puja');
  const three = TodayEventBadgeItem(id: 'e3', name: 'morning meditation');

  Future<void> pump(
    WidgetTester tester, {
    required List<TodayEventBadgeItem> events,
    ValueChanged<String>? onSelect,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayEventBadge(
            events: events,
            onSelect: onSelect,
          ),
        ),
      ),
    );
  }

  testWidgets('a single event opens directly on tap', (tester) async {
    final selected = <String>[];
    await pump(tester, events: [one], onSelect: selected.add);

    expect(find.text('Tara Puja'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.text('Tara Puja'));
    await tester.pump();

    expect(selected, ['e1']);
  });

  testWidgets('several events show a count and drop down the list', (
    tester,
  ) async {
    final selected = <String>[];
    await pump(tester, events: [one, two, three], onSelect: selected.add);

    expect(find.text('Tara Puja'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Medicine Buddha Puja'), findsNothing);
    // Collapsed pill stacks one avatar per event.
    expect(find.byIcon(AppAssets.usersThree), findsNWidgets(3));

    await tester.tap(find.text('Tara Puja'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(selected, isEmpty);
    expect(find.text('Tara Puja'), findsNWidgets(2));
    expect(find.text('Medicine Buddha Puja'), findsOneWidget);
    expect(find.text('Morning Meditation'), findsOneWidget);

    await tester.tap(find.text('Morning Meditation'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(selected, ['e3']);
    expect(find.text('Morning Meditation'), findsNothing);
  });
}
