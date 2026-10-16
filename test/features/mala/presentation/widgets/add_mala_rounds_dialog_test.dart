import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/add_mala_rounds_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheel_picker/wheel_picker.dart';

void main() {
  Future<int?> Function() pumpHost(WidgetTester tester) {
    late Future<int?> result;
    return () async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Builder(
            builder:
                (context) => TextButton(
                  onPressed: () => result = showAddMalaRoundsDialog(context),
                  child: const Text('open'),
                ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    };
  }

  FilledButton confirmButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('confirm stays disabled at zero rounds', (tester) async {
    await pumpHost(tester)();
    expect(find.byType(WheelPicker), findsOneWidget);
    expect(find.text('rounds'), findsOneWidget);
    expect(confirmButton(tester).onPressed, isNull);
  });

  testWidgets('scrolling the wheel picks the count and confirm returns it', (
    tester,
  ) async {
    final result = await pumpHost(tester)();

    // Three item extents upward lands on 3.
    await tester.drag(find.byType(WheelPicker), const Offset(0, -108));
    await tester.pumpAndSettle();
    expect(confirmButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(await result, 3);
  });

  testWidgets('dismissing the dialog returns null', (tester) async {
    final result = await pumpHost(tester)();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });
}
