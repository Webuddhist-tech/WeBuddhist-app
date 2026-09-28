import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_option_list.dart';
import 'package:flutter_test/flutter_test.dart';

// An 18 pt label at line height 1.5 is 27 px. With 14 px above and below and
// the 1 px divider, a row is 56 px, and the list stops at three and a half.
const _rowHeight = 56.0;
const _cap = _rowHeight * 3.5;

Widget _list({
  required int rows,
  int? revealIndex,
  Map<int, double> heights = const {},
  Map<int, Widget> blocks = const {},
  GlobalKey? revealKey,
}) {
  return MaterialApp(
    theme: ThemeData(
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 18, height: 1.5),
      ),
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 300,
          child: ReaderOptionList(
            revealIndex: revealIndex,
            revealKey: revealKey,
            children: [
              for (var i = 0; i < rows; i++)
                blocks[i] ??
                    SizedBox(
                      key: ValueKey(i),
                      height: heights[i] ?? _rowHeight,
                    ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// An open language: its row, [versions] rows, the last one checked and
/// carrying [checked].
Widget _openLanguage(int index, {required int versions, required Key checked}) {
  return Column(
    key: ValueKey(index),
    children: [
      const SizedBox(height: _rowHeight),
      for (var v = 0; v < versions; v++)
        SizedBox(key: v == versions - 1 ? checked : null, height: _rowHeight),
    ],
  );
}

ScrollPosition _position(WidgetTester tester) =>
    tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(ReaderOptionList),
            matching: find.byType(Scrollable),
          ),
        )
        .position;

bool _inView(WidgetTester tester, int row) {
  final list = tester.getRect(find.byType(ReaderOptionList));
  final rect = tester.getRect(find.byKey(ValueKey(row)));
  return rect.top >= list.top && rect.bottom <= list.bottom;
}

void main() {
  group('readerOptionRowHeight', () {
    test('is one label line plus the padding and the divider', () {
      const style = TextStyle(fontSize: 18, height: 1.5);
      expect(readerOptionRowHeight(style, TextScaler.noScaling), _rowHeight);
    });

    test('large text grows the line, not the padding', () {
      const style = TextStyle(fontSize: 18, height: 1.5);
      expect(readerOptionRowHeight(style, const TextScaler.linear(2)), 83);
    });
  });

  group('readerOptionRevealOffset', () {
    // A 100 px list over 400 px of rows, so offsets run from 0 to 300. The
    // block runs from [from] to [to] in the rows.
    double? reveal(double current, {required double from, required double to}) =>
        readerOptionRevealOffset(
          current: current,
          top: from,
          bottom: to - 100,
          min: 0,
          max: 300,
        );

    test('a block below the list scrolls just far enough to show it', () {
      expect(reveal(0, from: 150, to: 200), 100);
    });

    test('a block above the list scrolls back to its top', () {
      expect(reveal(200, from: 20, to: 70), 20);
    });

    test('a block already in view stays put', () {
      expect(reveal(0, from: 20, to: 70), isNull);
    });

    test('a block taller than the list shows its top', () {
      expect(reveal(0, from: 150, to: 300), 150);
    });

    test('a taller block the list is already inside stays put', () {
      expect(reveal(180, from: 150, to: 300), isNull);
    });

    test('never scrolls past the end', () {
      expect(reveal(0, from: 350, to: 400), 300);
    });
  });

  group('ReaderOptionList', () {
    testWidgets('caps a long list at three and a half rows', (tester) async {
      await tester.pumpWidget(_list(rows: 8));

      expect(tester.getSize(find.byType(ReaderOptionList)).height, _cap);
      expect(_position(tester).maxScrollExtent, 8 * _rowHeight - _cap);
    });

    testWidgets('a short list keeps its own height', (tester) async {
      await tester.pumpWidget(_list(rows: 2));

      expect(
        tester.getSize(find.byType(ReaderOptionList)).height,
        2 * _rowHeight,
      );
      expect(_position(tester).maxScrollExtent, 0);
    });

    testWidgets('opens with the reveal row in view', (tester) async {
      await tester.pumpWidget(_list(rows: 8, revealIndex: 6));
      await tester.pump();

      expect(_inView(tester, 6), isTrue);
    });

    testWidgets('follows a new reveal row', (tester) async {
      await tester.pumpWidget(_list(rows: 8, revealIndex: 6));
      await tester.pump();
      await tester.pumpWidget(_list(rows: 8, revealIndex: 0));
      await tester.pumpAndSettle();

      expect(_position(tester).pixels, 0);
    });

    testWidgets('shows the top of a row that opens taller than the list', (
      tester,
    ) async {
      await tester.pumpWidget(_list(rows: 8, revealIndex: 2));
      await tester.pump();
      expect(_position(tester).pixels, 0);

      // Row 2 opens to four rows' height, say a language and its versions.
      await tester.pumpWidget(
        _list(rows: 8, revealIndex: 2, heights: {2: 4 * _rowHeight}),
      );
      await tester.pumpAndSettle();

      expect(_position(tester).pixels, 2 * _rowHeight);
    });

    testWidgets('shows a language and its checked version together when they '
        'fit', (tester) async {
      final checked = GlobalKey();
      await tester.pumpWidget(
        _list(
          rows: 8,
          revealIndex: 2,
          revealKey: checked,
          blocks: {2: _openLanguage(2, versions: 2, checked: checked)},
        ),
      );
      await tester.pump();

      // Rows 2 through 4: the language and both versions, three rows in all.
      expect(_position(tester).pixels, 5 * _rowHeight - _cap);
      expect(_inView(tester, 2), isTrue);
      final list = tester.getRect(find.byType(ReaderOptionList));
      expect(tester.getRect(find.byKey(checked)).bottom, list.bottom);
    });

    testWidgets('scrolls to the checked version when its language opens '
        'taller than the list', (tester) async {
      final checked = GlobalKey();
      await tester.pumpWidget(
        _list(
          rows: 8,
          revealIndex: 2,
          revealKey: checked,
          blocks: {2: _openLanguage(2, versions: 5, checked: checked)},
        ),
      );
      await tester.pump();

      // The language row is off the top; its last version is at the bottom.
      final list = tester.getRect(find.byType(ReaderOptionList));
      expect(tester.getRect(find.byKey(checked)).bottom, list.bottom);
      expect(_inView(tester, 2), isFalse);
    });

    testWidgets('follows the checked version once versions arrive', (
      tester,
    ) async {
      final checked = GlobalKey();
      await tester.pumpWidget(
        _list(rows: 8, revealIndex: 2, revealKey: checked),
      );
      await tester.pump();
      expect(_position(tester).pixels, 0);

      await tester.pumpWidget(
        _list(
          rows: 8,
          revealIndex: 2,
          revealKey: checked,
          blocks: {2: _openLanguage(2, versions: 5, checked: checked)},
        ),
      );
      await tester.pumpAndSettle();

      final list = tester.getRect(find.byType(ReaderOptionList));
      expect(tester.getRect(find.byKey(checked)).bottom, list.bottom);
    });
  });
}
