import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/practice/data/repositories/bookmark_repository.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/bookmarks_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBookmarkRepository extends Fake implements BookmarkRepository {}

void main() {
  late AppLocalizations l10n;

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Signed out: the notifier settles on an empty list without calling
          // the repository, so each filter shows its own empty-state title.
          bookmarksProvider.overrideWith(
            (ref) => BookmarksNotifier(
              _FakeBookmarkRepository(),
              'en',
              isAuthenticated: false,
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BookmarksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    l10n = AppLocalizations.of(tester.element(find.byType(BookmarksScreen)))!;
  }

  Matcher pill(String label, {required bool selected}) =>
      isSemantics(label: label, isButton: true, isSelected: selected);

  testWidgets('shows every filter as a pill with All selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester);

    final labels = [
      l10n.search_all,
      l10n.home_shortcut_plans,
      l10n.home_chants,
      l10n.bookmark_mala,
      l10n.bookmark_group_accumulation,
      l10n.bookmark_timers,
      l10n.bookmark_texts,
    ];
    for (final label in labels) {
      expect(
        tester.getSemantics(find.text(label)),
        pill(label, selected: label == l10n.search_all),
      );
    }
    expect(find.byType(TabBar), findsNothing);
    expect(find.text(l10n.bookmarks_empty_all_title), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('tapping a pill selects it and pages to that filter', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.bookmark_timers));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text(l10n.bookmark_timers)),
      pill(l10n.bookmark_timers, selected: true),
    );
    expect(
      tester.getSemantics(find.text(l10n.search_all)),
      pill(l10n.search_all, selected: false),
    );
    expect(find.text(l10n.bookmarks_empty_timers_title), findsOneWidget);
    expect(find.text(l10n.bookmarks_empty_all_title), findsNothing);
    semantics.dispose();
  });

  testWidgets('swiping the list moves the selected pill', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester);

    await tester.fling(
      find.byType(TabBarView),
      const Offset(-400, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text(l10n.home_shortcut_plans)),
      pill(l10n.home_shortcut_plans, selected: true),
    );
    expect(
      tester.getSemantics(find.text(l10n.search_all)),
      pill(l10n.search_all, selected: false),
    );
    expect(find.text(l10n.bookmarks_empty_plans_title), findsOneWidget);
    semantics.dispose();
  });
}
