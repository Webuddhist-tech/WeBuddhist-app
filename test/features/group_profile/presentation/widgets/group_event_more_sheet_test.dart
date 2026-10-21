import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_more_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onManage,
  VoidCallback? onLeave,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder:
              (context) => TextButton(
                onPressed:
                    () => showGroupEventMoreSheet(
                      context,
                      onManage: onManage,
                      onLeave: onLeave,
                    ),
                child: const Text('open'),
              ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an attending member only sees leave', (tester) async {
    await _pump(tester, onLeave: () {});

    expect(find.text('Leave event'), findsOneWidget);
    expect(find.text('Manage event'), findsNothing);
  });

  testWidgets('an admin who is not attending only sees manage', (tester) async {
    var managed = false;
    await _pump(tester, onManage: () => managed = true);

    expect(find.text('Leave event'), findsNothing);
    await tester.tap(find.text('Manage event'));
    await tester.pumpAndSettle();

    expect(managed, isTrue);
    expect(find.text('Manage event'), findsNothing);
  });

  testWidgets('an attending admin sees manage above leave', (tester) async {
    await _pump(tester, onManage: () {}, onLeave: () {});

    final manage = tester.getTopLeft(find.text('Manage event'));
    final leave = tester.getTopLeft(find.text('Leave event'));
    expect(manage.dy, lessThan(leave.dy));
  });
}
