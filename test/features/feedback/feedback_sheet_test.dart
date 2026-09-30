import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/feedback/presentation/widgets/feedback_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the sheet on a phone-sized screen with [keyboardHeight] of the
/// bottom covered by the on-screen keyboard.
Future<void> _openSheet(
  WidgetTester tester, {
  double screenHeight = 640,
  double keyboardHeight = 0,
}) async {
  tester.view.physicalSize = Size(360, screenHeight);
  tester.view.devicePixelRatio = 1.0;
  // Set on the view, not an injected MediaQuery: the sheet opens on the root
  // navigator and reads the inset from there.
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
  addTearDown(tester.view.reset);

  late BuildContext hostContext;
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    ),
  );

  // Not awaited: the sheet has to stay open so the test can inspect it.
  unawaited(FeedbackSheet.show(hostContext));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('composer and send button are both reachable', (tester) async {
    await _openSheet(tester);

    expect(find.text('Feedback'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('0 / 400'), findsOneWidget);
    expect(find.text('Images'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets('send stays disabled until the message has text', (tester) async {
    await _openSheet(tester);

    ElevatedButton button() => tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Send'),
        matching: find.byType(ElevatedButton),
      ),
    );

    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'The reader crashes');
    await tester.pumpAndSettle();

    expect(button().onPressed, isNotNull);
  });

  testWidgets('an open keyboard does not squeeze out the composer', (
    tester,
  ) async {
    // A compact phone with the keyboard up: a flat 60% of the space left
    // above it would leave the non-scrolling header and footer no room for
    // the text field in between.
    await _openSheet(tester, screenHeight: 640, keyboardHeight: 300);

    // The composer keeps its natural height inside the scroll view, so what
    // matters is how much of it the viewport can actually show.
    final viewport = tester.getRect(find.byType(ListView));
    final send = tester.getRect(
      find.ancestor(
        of: find.text('Send'),
        matching: find.byType(ElevatedButton),
      ),
    );

    expect(viewport.height, greaterThan(150));
    expect(send.height, greaterThanOrEqualTo(48));
    // Nothing is pushed under the keyboard.
    expect(send.bottom, lessThanOrEqualTo(640 - 300));
    expect(tester.takeException(), isNull);
  });
}
