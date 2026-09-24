import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/section_header.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';

Widget _app(Widget child) => ProviderScope(
  overrides: [
    fontSizeProvider.overrideWith(
      (ref) => FontSizeNotifier(localStorageService: FakeLocalStorage()),
    ),
  ],
  child: MaterialApp(home: Scaffold(body: child)),
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

  testWidgets('a top-level heading shows its number and title', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SectionHeader(
          section: _section(title: 'བསྟོད་པ།', number: 3),
          depth: 0,
          language: language,
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('བསྟོད་པ།'), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('a nested heading after lines draws a rule, no number', (
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
    expect(find.text('2'), findsNothing);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('a section without a title renders nothing', (tester) async {
    await tester.pumpWidget(
      _app(SectionHeader(section: _section(), depth: 0, language: language)),
    );

    expect(find.byType(Text), findsNothing);
  });
}
