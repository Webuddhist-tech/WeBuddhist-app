import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_participation_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Future<GroupEventParticipationType?>> _open(WidgetTester tester) async {
  late Future<GroupEventParticipationType?> result;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder:
            (context) => TextButton(
              onPressed:
                  () => result = GroupEventParticipationDialog.show(context),
              child: const Text('open'),
            ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('asks how the user attends and returns the choice', (
    tester,
  ) async {
    final result = await _open(tester);
    expect(find.text('How are you attending?'), findsOneWidget);

    await tester.tap(find.text('In person'));
    await tester.pumpAndSettle();

    expect(await result, GroupEventParticipationType.offline);
    expect(find.text('How are you attending?'), findsNothing);
  });

  testWidgets('online is the other option', (tester) async {
    final result = await _open(tester);

    await tester.tap(find.text('Online'));
    await tester.pumpAndSettle();

    expect(await result, GroupEventParticipationType.online);
  });

  testWidgets('dismissing it returns nothing', (tester) async {
    final result = await _open(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });
}
