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
  late MaterialLocalizations materialL10n;

  Future<void> pumpScreen(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
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
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BookmarksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final element = tester.element(find.byType(BookmarksScreen));
    l10n = AppLocalizations.of(element)!;
    materialL10n = MaterialLocalizations.of(element);
  }

  List<String> pillLabels() => [
    l10n.search_all,
    l10n.home_shortcut_plans,
    l10n.home_chants,
    l10n.bookmark_mala,
    l10n.bookmark_group_accumulation,
    l10n.bookmark_timers,
    l10n.bookmark_texts,
  ];

  /// A pill reads as a button in the selected state, with its position in the
  /// group as the hint ("Tab 2 of 7").
  Matcher pill(String label, {required bool selected}) => containsSemantics(
    label: label,
    hint: materialL10n.tabLabel(
      tabIndex: pillLabels().indexOf(label) + 1,
      tabCount: pillLabels().length,
    ),
    isButton: true,
    isSelected: selected,
  );

  /// The drawn pill, without the padding that pads its tap area.
  Rect pillRect(WidgetTester tester, String label) => tester.getRect(
    find.ancestor(of: find.text(label), matching: find.byType(Material)).first,
  );

  /// Pumps at a narrow phone size in Mongolian, which has the longest labels.
  Future<void> pumpNarrowMongolian(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpScreen(tester, locale: const Locale('mn'));
  }

  /// Every pill sits inside the 16px gutters, and they need more than one row.
  void expectPillsWrapInside(WidgetTester tester) {
    final rects = [for (final label in pillLabels()) pillRect(tester, label)];
    for (final rect in rects) {
      expect(rect.left, greaterThanOrEqualTo(16));
      expect(rect.right, lessThanOrEqualTo(320 - 16));
    }
    expect(rects.map((rect) => rect.top).toSet().length, greaterThan(1));
    expect(tester.takeException(), isNull);
  }

  testWidgets('shows every filter as a pill with All selected', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester);

    for (final label in pillLabels()) {
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

    await tester.fling(find.byType(TabBarView), const Offset(-400, 0), 1000);
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

  testWidgets('pills meet the minimum tap target size', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('a tap just above the drawn pill selects it', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester);

    final rect = pillRect(tester, l10n.bookmark_timers);
    expect(rect.height, lessThan(kMinInteractiveDimension));
    await tester.tapAt(Offset(rect.center.dx, rect.top - 2));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text(l10n.bookmark_timers)),
      pill(l10n.bookmark_timers, selected: true),
    );
    semantics.dispose();
  });

  testWidgets('long labels wrap on a narrow phone', (tester) async {
    await pumpNarrowMongolian(tester);

    expectPillsWrapInside(tester);
  });

  testWidgets('long labels wrap on a narrow phone with large text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpNarrowMongolian(tester);

    expectPillsWrapInside(tester);
  });

  testWidgets('on a short screen the pills scroll instead of hiding the list', (
    tester,
  ) async {
    // Landscape phone with the largest text in the longest-label locale: the
    // pill rows are taller than the body.
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpScreen(tester, locale: const Locale('mn'));

    expect(tester.takeException(), isNull);
    final list = tester.getRect(find.byType(TabBarView));
    expect(list.height, greaterThanOrEqualTo(list.bottom / 2 - 56));
    expect(find.text(l10n.bookmarks_empty_all_title), findsOneWidget);

    // The last pill starts out below the pill area and scrolls into it.
    final lastPill = find.text(l10n.bookmark_texts);
    expect(tester.getRect(lastPill).top, greaterThan(list.top));
    await tester.dragUntilVisible(
      lastPill,
      find.ancestor(
        of: find.text(l10n.search_all),
        matching: find.byType(Scrollable),
      ),
      const Offset(0, -50),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(lastPill).bottom, lessThanOrEqualTo(list.top));
  });
}
