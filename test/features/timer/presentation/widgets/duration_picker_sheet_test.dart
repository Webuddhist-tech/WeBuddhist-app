import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/duration_picker_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext hostContext;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          hostContext = context;
          return const Scaffold(body: SizedBox.expand());
        },
      ),
    ),
  );
  return hostContext;
}

void main() {
  testWidgets('closing the sheet keeps the time on the wheels', (tester) async {
    final context = await _pumpHost(tester);
    final result = DurationPickerSheet.show(
      context,
      initialDuration: const Duration(minutes: 10),
    );
    await tester.pumpAndSettle();

    // Seconds wheel: drag up by two items.
    await tester.drag(
      find.byType(ListWheelScrollView).at(2),
      const Offset(0, -88),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10)); // barrier
    await tester.pumpAndSettle();

    expect(await result, const Duration(minutes: 10, seconds: 2));
  });

  testWidgets('a wheel still spinning while the sheet closes does not throw', (
    tester,
  ) async {
    final context = await _pumpHost(tester);
    final result = DurationPickerSheet.show(
      context,
      initialDuration: const Duration(minutes: 10),
    );
    await tester.pumpAndSettle();

    // Fling, then dismiss before the wheel settles. The wheel keeps
    // reporting during the close animation, after show() has returned.
    await tester.fling(
      find.byType(ListWheelScrollView).at(2),
      const Offset(0, -300),
      3000,
    );
    await tester.tapAt(const Offset(10, 10)); // barrier
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(await result, isNotNull);
  });

  testWidgets('0:00:00 returns null so the caller keeps its duration', (
    tester,
  ) async {
    final context = await _pumpHost(tester);
    final result = DurationPickerSheet.show(
      context,
      initialDuration: Duration.zero,
    );
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });
}
