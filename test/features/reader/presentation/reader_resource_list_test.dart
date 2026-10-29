import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_resource_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';

const _english = ReaderResourceEntry(
  content: 'This praise with the root mantra',
  language: 'en',
  title: 'Illuminating Rays',
  source: 'webuddhist.com',
  license: 'Public',
);
const _englishToo = ReaderResourceEntry(
  content: 'The twenty-one homages are the root mantra',
  language: 'en',
  title: 'A Commentary on the Twenty-One Praises',
);
const _tibetan = ReaderResourceEntry(
  content: 'ཕྱག་འཚལ་ཉེར་གཅིག',
  language: 'bo',
  title: 'གསལ་བའི་འོད་ཟེར།',
);

Future<void> _pump(
  WidgetTester tester,
  List<ReaderResourceEntry> entries, {
  Locale locale = const Locale('en'),
  String? firstLanguage,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReaderResourceList(
            entries: entries,
            textLanguage: 'bo',
            firstLanguage: firstLanguage,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group("a tab's languages", () {
    test("the interface's first, then the text's, then the rest A→Z", () {
      expect(
        readerResourceLanguages(
          languages: const ['hi', 'zh', 'bo', 'en'],
          interfaceLanguage: 'en',
          textLanguage: 'bo',
        ),
        ['en', 'bo', 'hi', 'zh'],
      );
      // A Tibetan interface leads with Tibetan (WF27).
      expect(
        readerResourceLanguages(
          languages: const ['en', 'bo'],
          interfaceLanguage: 'bo',
          textLanguage: 'bo',
        ),
        ['bo', 'en'],
      );
    });

    test('only languages with something; Chinese kept beside Classical', () {
      expect(
        readerResourceLanguages(
          languages: const ['zh', 'mn', 'lzh'],
          interfaceLanguage: 'en',
          textLanguage: 'bo',
        ),
        ['lzh', 'zh', 'mn'],
      );
      expect(
        readerResourceLanguages(
          languages: const [],
          interfaceLanguage: 'en',
          textLanguage: 'bo',
        ),
        isEmpty,
      );
    });
  });

  group('the list', () {
    testWidgets('one language at a time, picked by its chip', (tester) async {
      await _pump(tester, const [_tibetan, _english, _englishToo]);

      expect(find.text('English'), findsOneWidget);
      expect(find.text('བོད་ཡིག'), findsOneWidget);
      // The interface's language first: both English items, no Tibetan.
      expect(find.text('Illuminating Rays'), findsOneWidget);
      expect(find.text('A Commentary on the Twenty-One Praises'), findsOneWidget);
      expect(find.text('གསལ་བའི་འོད་ཟེར།'), findsNothing);

      await tester.tap(find.text('བོད་ཡིག'));
      await tester.pumpAndSettle();
      expect(find.text('གསལ་བའི་འོད་ཟེར།'), findsOneWidget);
      expect(find.text('Illuminating Rays'), findsNothing);
    });

    testWidgets("a plan task's pinned item's language comes first", (
      tester,
    ) async {
      await _pump(tester, const [_tibetan, _english], firstLanguage: 'bo');
      expect(find.text('གསལ་བའི་འོད་ཟེར།'), findsOneWidget);
      expect(find.text('Illuminating Rays'), findsNothing);
    });

    testWidgets("the source line opens the source's card", (tester) async {
      await _pump(tester, const [_english]);
      expect(find.text('Source: webuddhist.com'), findsNothing);

      await tester.tap(find.text('Illuminating Rays'));
      await tester.pumpAndSettle();
      // The title on the line and again on the card.
      expect(find.text('Illuminating Rays'), findsNWidgets(2));
      expect(find.text('Source: webuddhist.com'), findsOneWidget);
      expect(find.text('License: Public'), findsOneWidget);

      await tester.tap(find.text('Illuminating Rays').first);
      await tester.pumpAndSettle();
      expect(find.text('Source: webuddhist.com'), findsNothing);
    });

    testWidgets('a card leaves out what the source does not give', (
      tester,
    ) async {
      await _pump(tester, const [_englishToo]);
      await tester.tap(find.text('A Commentary on the Twenty-One Praises'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Source:'), findsNothing);
      expect(find.textContaining('License:'), findsNothing);
    });
  });
}
