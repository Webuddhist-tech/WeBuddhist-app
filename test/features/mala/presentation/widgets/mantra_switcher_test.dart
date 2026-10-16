import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mantra_marquee.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mantra_switcher.dart';
import 'package:flutter_test/flutter_test.dart';

const _mantras = [
  Mantra(
    presetId: 'p1',
    mantra: MantraText(
      id: 'm1',
      text: 'ༀ་མ་ཎི་པདྨེ་ཧཱུྃ།',
      title: 'Avalokiteshvara',
      pronunciation: 'Om Mani Padme Hum',
    ),
  ),
  Mantra(
    presetId: 'p2',
    mantra: MantraText(
      id: 'm2',
      text: 'ༀ་ཏཱ་རེ་ཏུཏྟཱ་རེ་ཏུ་རེ་སྭཱ་ཧཱ།',
      title: 'Green Tara',
      pronunciation: 'Om Tare Tuttare Ture Soha',
    ),
  ),
];

class _Host extends StatefulWidget {
  const _Host();
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
                mantras: _mantras,
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

void main() {
  // The marquee ticks forever, so these tests pump fixed frames and never
  // call pumpAndSettle.
  testWidgets('band shows both lines of the current mantra as marquees', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    await tester.pump();

    expect(find.byType(MantraMarquee), findsNWidgets(2));
    expect(find.bySemanticsLabel('Om Mani Padme Hum'), findsOneWidget);
  });

  testWidgets('tapping a line opens the full text and close restores the band',
      (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pump();

    await tester.tap(find.byType(MantraMarquee).last);
    await tester.pump();

    expect(find.byType(MantraMarquee), findsNothing);
    expect(find.text('Om Mani Padme Hum'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();

    expect(find.byType(MantraMarquee), findsNWidgets(2));
    expect(find.text('Om Mani Padme Hum'), findsNothing);
  });

  testWidgets('the right chevron advances to the next mantra', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pump();

    await tester.tap(find.byType(IconButton).last);
    await tester.pump(); // start the page animation
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(); // rebuild with the settled index

    expect(find.text('index:1'), findsOneWidget);
    expect(find.bySemanticsLabel('Om Tare Tuttare Ture Soha'), findsOneWidget);
  });
}
