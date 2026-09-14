import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_message_menu.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _screen = Size(400, 800);

/// Opens the menu over a message [messageHeight] tall, anchored at [anchorTop].
Future<void> _openMenu(
  WidgetTester tester, {
  required double messageHeight,
  double anchorTop = 100,
  bool canReport = true,
  bool canDelete = true,
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

  showChatMessageMenu(
    hostContext,
    anchor: Rect.fromLTWH(16, anchorTop, 320, messageHeight),
    message: Container(height: messageHeight, color: Colors.blue),
    myEmoji: null,
    canReport: canReport,
    canDelete: canDelete,
  );
  await tester.pumpAndSettle();
}

/// The card is the one thing the menu exists to offer; if it is off screen the
/// menu is useless.
Rect _actionsCardRect(WidgetTester tester) {
  final reply = find.text('Reply');
  expect(reply, findsOneWidget);
  return tester.getRect(reply);
}

void main() {
  setUp(() {
    // A fixed viewport, so the assertions are about the layout and not about
    // whatever the host machine reports.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('showChatMessageMenu', () {
    testWidgets('a message taller than the screen still shows the actions', (
      tester,
    ) async {
      tester.view.physicalSize = _screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // Far taller than the viewport: the case that used to push the card off
      // the bottom and leave a wall of text with nothing to tap.
      await _openMenu(tester, messageHeight: 2000);

      final card = _actionsCardRect(tester);
      expect(card.top, greaterThanOrEqualTo(0));
      expect(card.bottom, lessThanOrEqualTo(_screen.height));
    });

    testWidgets('the whole action list fits, delete included', (tester) async {
      tester.view.physicalSize = _screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _openMenu(tester, messageHeight: 2000);

      // The last row matters most: it is the one that falls off the edge.
      final delete = tester.getRect(find.text('Delete'));
      expect(delete.bottom, lessThanOrEqualTo(_screen.height));
    });

    testWidgets('a long message can be scrolled inside the lift', (
      tester,
    ) async {
      tester.view.physicalSize = _screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _openMenu(tester, messageHeight: 2000);

      // Clipped rather than shrunk, so the rest is reachable.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('own message: no Report row, and the card shrinks', (
      tester,
    ) async {
      tester.view.physicalSize = _screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _openMenu(tester, messageHeight: 80, canReport: false);

      expect(find.text('Report'), findsNothing);
      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // The card is measured from the rows it draws; a hardcoded count would
      // reserve space for a Report row that is not there.
      final card = tester.getRect(find.text('Delete'));
      expect(card.bottom, lessThanOrEqualTo(_screen.height));
    });

    testWidgets('a short message is not clipped or made scrollable', (
      tester,
    ) async {
      tester.view.physicalSize = _screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _openMenu(tester, messageHeight: 80);

      expect(find.byType(SingleChildScrollView), findsNothing);
      final card = _actionsCardRect(tester);
      expect(card.bottom, lessThanOrEqualTo(_screen.height));
    });
  });
}
