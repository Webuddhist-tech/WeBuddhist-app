import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mantra_marquee.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mantra_switcher.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';
import 'package:flutter_test/flutter_test.dart';

const _art = ResponsiveImage.uniform('https://example.com/deity.webp');

Mantra _mantra(String id, String pronunciation, {ResponsiveImage? art}) =>
    Mantra(
      presetId: 'p$id',
      mantra: MantraText(
        id: 'm$id',
        text: 'ༀ་$id',
        title: 'Mantra $id',
        pronunciation: pronunciation,
        deityImage: art,
      ),
    );

final _plain = [
  _mantra('1', 'Om Mani Padme Hum'),
  _mantra('2', 'Om Tare Tuttare Ture Soha'),
];

final _withArt = [
  _mantra('1', 'Alpha', art: _art),
  _mantra('2', 'Beta', art: _art),
  _mantra('3', 'Gamma', art: _art),
];

/// Artwork, no artwork, artwork.
final _mixed = [
  _mantra('1', 'Alpha', art: _art),
  _mantra('2', 'Beta'),
  _mantra('3', 'Gamma', art: _art),
];

class _Host extends StatefulWidget {
  const _Host(this.mantras);
  final List<Mantra> mantras;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Column(
          children: [
            Text('index:$_index'),
            Expanded(
              child: MantraSwitcher(
                mantras: widget.mantras,
                language: 'en',
                index: _index,
                onIndexChanged: (next) => setState(() => _index = next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logical mantra the carousel is showing right now.
int _shownMantra(WidgetTester tester, int length) {
  final pageView = tester.widget<PageView>(find.byType(PageView));
  return pageView.controller!.page!.round() % length;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(); // start the page animation
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(); // rebuild with the settled index
}

Future<void> _swipeLeft(WidgetTester tester) async {
  await tester.drag(find.byType(PageView), const Offset(-500, 0));
  await _settle(tester);
}

void main() {
  testWidgets('band shows both lines of the current mantra as marquees', (
    tester,
  ) async {
    await tester.pumpWidget(_Host(_plain));
    await tester.pump();

    expect(find.byType(MantraMarquee), findsNWidgets(2));
    expect(find.bySemanticsLabel('Om Mani Padme Hum'), findsOneWidget);
  });

  testWidgets(
    'tapping a line opens the full text and close restores the band',
    (tester) async {
      await tester.pumpWidget(_Host(_plain));
      await tester.pump();

      await tester.tap(find.byType(MantraMarquee).last);
      await tester.pump();

      expect(find.byType(MantraMarquee), findsNothing);
      expect(find.text('Om Mani Padme Hum'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pump();

      expect(find.byType(MantraMarquee), findsNWidgets(2));
      expect(find.text('Om Mani Padme Hum'), findsNothing);
    },
  );

  testWidgets('the right chevron advances to the next mantra', (tester) async {
    await tester.pumpWidget(_Host(_plain));
    await tester.pump();

    await tester.tap(find.byType(IconButton).last);
    await _settle(tester);

    expect(find.text('index:1'), findsOneWidget);
    expect(find.bySemanticsLabel('Om Tare Tuttare Ture Soha'), findsOneWidget);
  });

  testWidgets('mantras without artwork can be swiped', (tester) async {
    await tester.pumpWidget(_Host(_plain));
    await tester.pump();

    await _swipeLeft(tester);

    expect(find.text('index:1'), findsOneWidget);
    expect(find.bySemanticsLabel('Om Tare Tuttare Ture Soha'), findsOneWidget);
  });

  testWidgets('a mixed list swipes through artwork and no-artwork pages', (
    tester,
  ) async {
    await tester.pumpWidget(_Host(_mixed));
    await tester.pump();

    await _swipeLeft(tester);
    expect(find.text('index:1'), findsOneWidget);
    expect(find.bySemanticsLabel('Beta'), findsOneWidget);

    await _swipeLeft(tester);
    expect(find.text('index:2'), findsOneWidget);
    expect(find.bySemanticsLabel('Gamma'), findsOneWidget);
  });

  testWidgets(
    'artwork stays on the current mantra after opening and closing full text',
    (tester) async {
      await tester.pumpWidget(_Host(_withArt));
      await tester.pump();

      await tester.tap(find.byType(IconButton).last);
      await _settle(tester);
      expect(find.text('index:1'), findsOneWidget);
      expect(_shownMantra(tester, _withArt.length), 1);

      await tester.tap(find.byType(MantraMarquee).last);
      await tester.pump();
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();

      expect(find.text('index:1'), findsOneWidget);
      expect(_shownMantra(tester, _withArt.length), 1);

      // The next swipe continues from the current mantra, not the first one.
      await _swipeLeft(tester);
      expect(find.text('index:2'), findsOneWidget);
    },
  );
}
