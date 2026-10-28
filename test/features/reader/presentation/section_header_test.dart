import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_text_size_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_script.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/section_header.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';

Widget _app(Widget child) => ProviderScope(
  overrides: [
    readerTextSizeProvider.overrideWith(
      (ref) => ReaderTextSizeNotifier(localStorageService: FakeLocalStorage()),
    ),
  ],
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

Section _section({String? title, int number = 1}) => Section(
  id: 'S',
  title: title,
  sectionNumber: number,
  segments: const [],
  sections: const [],
);

void main() {
  // Tibetan uses a bundled font, so no Google Fonts lookup runs in tests.
  const language = 'bo';
  const title = 'བསྟོད་པ།';

  testWidgets('a counted heading has an overline with its place', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SectionHeader(
          section: _section(title: title, number: 3),
          depth: 0,
          language: language,
          place: (position: 5, total: 15),
          numeralLanguage: 'en',
        ),
      ),
    );

    expect(find.text('SECTION 5 / 15'), findsOneWidget);
    expect(find.text(title), findsOneWidget);
    // The old number above the title is gone.
    expect(find.text('3'), findsNothing);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('the overline\'s numbers follow the numeral language', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SectionHeader(
          section: _section(title: title),
          depth: 0,
          language: language,
          place: (position: 5, total: 15),
          numeralLanguage: 'bo',
          overlineTrailing: 'Round 2 / 3',
        ),
      ),
    );

    expect(find.text('SECTION ༥ / ༡༥ · ROUND ༢ / ༣'), findsOneWidget);
  });

  testWidgets('a heading the pill does not count has no overline', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SectionHeader(
          section: _section(title: 'Sub', number: 2),
          depth: 1,
          language: language,
          showDivider: true,
        ),
      ),
    );

    expect(find.text('Sub'), findsOneWidget);
    expect(find.textContaining('SECTION'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('the title is left-aligned with the page margin', (tester) async {
    await tester.pumpWidget(
      _app(
        SectionHeader(
          section: _section(title: title),
          depth: 0,
          language: language,
          subtitle: 'with the Praises ×3, ×7',
        ),
      ),
    );

    expect(tester.getTopLeft(find.text(title)).dx, 16);
    expect(tester.getTopLeft(find.text('with the Praises ×3, ×7')).dx, 16);
    expect(
      tester
          .widget<Text>(find.text('with the Praises ×3, ×7'))
          .style
          ?.fontStyle,
      FontStyle.italic,
    );
  });

  testWidgets('a section without a title renders nothing', (tester) async {
    await tester.pumpWidget(
      _app(SectionHeader(section: _section(), depth: 0, language: language)),
    );

    expect(find.byType(Text), findsNothing);
  });

  test('the overline is in capitals, its digits in the script', () {
    expect(
      readerSectionOverline('Section 1 / 4', script: ReaderScript.latin),
      'SECTION 1 / 4',
    );
    expect(
      readerSectionOverline(
        'Section 1 / 4',
        trailing: 'Round 1 / 3',
        script: ReaderScript.tibetan,
      ),
      'SECTION ༡ / ༤ · ROUND ༡ / ༣',
    );
  });
}
