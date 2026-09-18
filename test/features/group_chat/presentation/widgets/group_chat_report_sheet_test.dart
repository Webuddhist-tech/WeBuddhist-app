import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_report_reason.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_report_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the sheet. [onDone] receives whatever it resolves to.
Future<void> _openSheet(
  WidgetTester tester, {
  ValueChanged<ChatReportSubmission?>? onDone,
}) async {
  late BuildContext hostContext;

  await tester.pumpWidget(
    MaterialApp(
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

  // Not awaited: the sheet has to stay open so the test can drive it.
  unawaited(showChatReportSheet(hostContext).then((v) => onDone?.call(v)));
  await tester.pumpAndSettle();
}

bool _submitEnabled(WidgetTester tester) {
  final button = tester.widget<ElevatedButton>(
    find.ancestor(
      of: find.text('Submit report'),
      matching: find.byType(ElevatedButton),
    ),
  );
  return button.onPressed != null;
}

void main() {
  group('showChatReportSheet', () {
    testWidgets('submit stays disabled until a reason is chosen', (
      tester,
    ) async {
      await _openSheet(tester);

      expect(find.text('Why are you reporting this?'), findsOneWidget);
      expect(_submitEnabled(tester), isFalse);

      await tester.tap(find.text('Spam or scams'));
      await tester.pumpAndSettle();

      expect(_submitEnabled(tester), isTrue);
    });

    testWidgets('something else reveals the note inline', (tester) async {
      await _openSheet(tester);

      // Nothing to write in until the reason that needs one is chosen.
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();

      // Same sheet, no second step: the reasons stay on screen beside it.
      expect(find.text('Add a note'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Why are you reporting this?'), findsOneWidget);
      expect(find.text('Spam or scams'), findsOneWidget);
    });

    testWidgets('changing to another reason takes the note away', (
      tester,
    ) async {
      await _openSheet(tester);

      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'typed something');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spam or scams'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      // And the abandoned note is not sent with the new reason.
      expect(_submitEnabled(tester), isTrue);
    });

    testWidgets('something else will not submit while the note is empty', (
      tester,
    ) async {
      await _openSheet(tester);
      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();

      expect(_submitEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField), 'they keep insulting');
      await tester.pumpAndSettle();

      expect(_submitEnabled(tester), isTrue);
    });

    testWidgets('whitespace alone is not a note', (tester) async {
      await _openSheet(tester);
      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '    ');
      await tester.pumpAndSettle();

      expect(_submitEnabled(tester), isFalse);
    });

    testWidgets('a plain reason submits outright, with no note', (
      tester,
    ) async {
      ChatReportSubmission? submitted;
      await _openSheet(tester, onDone: (v) => submitted = v);

      await tester.tap(find.text('Harassment or bullying'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      // No note asked for, and nothing invented to fill one.
      expect(find.text('Add a note'), findsNothing);
      expect(submitted?.reason, ChatReportReason.harassment);
      expect(submitted?.note, isNull);
    });

    testWidgets('the note field stops at the cap', (tester) async {
      await _openSheet(tester);
      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'a' * (kChatReportNoteLimit + 40),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, hasLength(kChatReportNoteLimit));
    });
  });
}
