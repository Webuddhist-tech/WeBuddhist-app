import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_page_toc.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_sections_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';

ReaderSheetSection _row(
  String id,
  String title, {
  String language = 'en',
  String numeralLanguage = 'en',
  String? group,
  int source = 0,
  String? text,
  bool isText = false,
}) => ReaderSheetSection(
  section: ReaderPageSection(
    source: source,
    id: id,
    title: title,
    language: language,
    entryIndex: 0,
  ),
  numeralLanguage: numeralLanguage,
  group: group,
  groupLanguage: group == null ? null : language,
  text: text,
  textLanguage: text == null ? null : language,
  isText: isText,
);

/// Opens the sheet over a page whose section on screen is [current], and
/// returns what it pops with.
Future<ValueNotifier<ReaderPageSection?>> _open(
  WidgetTester tester,
  ReaderSectionsSnapshot snapshot, {
  required String current,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final picked = ValueNotifier<ReaderPageSection?>(null);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed: () async {
                    picked.value = await showReaderSheet<ReaderPageSection>(
                      context,
                      dim: ReaderSheetDim.sections,
                      builder:
                          (_) => ReaderSectionsSheet(
                            snapshot: ValueNotifier(snapshot),
                            current: ValueNotifier('0:$current'),
                          ),
                    );
                  },
                  child: const Text('open'),
                ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  // A text still loading spins: pump the sheet in rather than settle.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return picked;
}

void main() {
  final puja = ReaderSectionsSnapshot(
    sections: [
      _row('a', 'Prayer to the Buddha'),
      _row('b', 'Lineage Prayer'),
      _row('c', 'Praises to the 21 Tārās'),
      _row('d', 'The Tambura of Devotion', group: 'After the puja'),
      _row('e', 'The Melodious Tune', group: 'After the puja'),
    ],
    pendingSources: 0,
    liveKey: '0:c',
  );

  testWidgets('read sections ticked, the rest numbered, groups headed', (
    tester,
  ) async {
    await _open(tester, puja, current: 'c');

    expect(find.text('Sections'), findsOneWidget);
    expect(find.text('Section 3 / 5'), findsOneWidget);
    // The two before the one on screen are ticked; it and those after are
    // numbered.
    expect(find.byIcon(AppAssets.check), findsNWidgets(2));
    expect(find.text('1'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    // One heading over its run of sections, in capitals.
    expect(find.text('AFTER THE PUJA'), findsOneWidget);
    // The live section carries the pill.
    expect(find.text('Live'), findsOneWidget);
  });

  testWidgets('no Live pill unless the reader follows a live recitation', (
    tester,
  ) async {
    await _open(
      tester,
      ReaderSectionsSnapshot(sections: puja.sections, pendingSources: 0),
      current: 'a',
    );
    expect(find.text('Live'), findsNothing);
    expect(find.byIcon(AppAssets.check), findsNothing);
    expect(find.text('Section 1 / 5'), findsOneWidget);
  });

  testWidgets('a Tibetan page counts in Tibetan digits', (tester) async {
    await _open(
      tester,
      ReaderSectionsSnapshot(
        sections: [
          for (final id in ['a', 'b'])
            _row(id, 'བསྟོད་པ། $id', language: 'bo', numeralLanguage: 'bo'),
        ],
        pendingSources: 1,
      ),
      current: 'a',
    );
    // The text still loading counts towards the total.
    expect(find.text('Section ༡ / ༣'), findsOneWidget);
    expect(find.text('༡'), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
  });

  testWidgets('opens on the section on screen, even far down a long list', (
    tester,
  ) async {
    await _open(
      tester,
      ReaderSectionsSnapshot(
        sections: [for (var i = 1; i <= 40; i++) _row('s$i', 'Section $i')],
        pendingSources: 0,
      ),
      current: 's38',
    );
    final row = find.text('Section 38');
    expect(row, findsOneWidget);
    final sheet = tester.getRect(find.byType(ReaderSectionsSheet));
    final at = tester.getRect(row);
    expect(at.top, greaterThanOrEqualTo(sheet.top));
    expect(at.bottom, lessThanOrEqualTo(sheet.bottom));
  });

  testWidgets('several texts are ruled apart, each under its title', (
    tester,
  ) async {
    const mirror = 'The Clear Mirror';
    await _open(
      tester,
      ReaderSectionsSnapshot(
        sections: [
          _row('summary', 'The brief summary', text: mirror),
          _row(
            'p1',
            'Prostration',
            group: 'The detailed explanation',
            text: mirror,
          ),
          _row(
            'p2',
            'Praise',
            group: 'The detailed explanation',
            text: mirror,
          ),
          // Texts with no sections of their own are their one row.
          _row('t1', 'Prayer for the Future', source: 1, isText: true),
          _row('t2', 'Prayer to Guru Rinpoche', source: 2, isText: true),
        ],
        pendingSources: 1,
        severalTexts: true,
      ),
      current: 'summary',
    );

    expect(find.text(mirror), findsOneWidget);
    expect(find.text('THE DETAILED EXPLANATION'), findsOneWidget);
    expect(find.text('Prayer for the Future'), findsOneWidget);
    // Those texts are titles, unnumbered; the sections are numbered.
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);
    final title = tester.widget<Text>(find.text('Prayer for the Future'));
    expect(title.style?.fontWeight, FontWeight.w600);
    // Between the four texts, the last still loading.
    expect(find.byType(Divider), findsNWidgets(3));
    expect(find.text('Section 1 / 6'), findsOneWidget);
  });

  testWidgets('one text is not ruled', (tester) async {
    await _open(tester, puja, current: 'a');
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('a tap goes to that section', (tester) async {
    final picked = await _open(tester, puja, current: 'c');
    await tester.tap(find.text('The Melodious Tune'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ReaderSectionsSheet), findsNothing);
    expect(picked.value?.id, 'e');
  });
}
