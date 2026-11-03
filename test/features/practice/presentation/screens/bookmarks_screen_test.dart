import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';
import 'package:flutter_pecha/features/practice/data/repositories/bookmark_repository.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/bookmarks_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Deletes always succeed and the server list comes back empty, so a removal
/// stays removed.
class _FakeBookmarkRepository extends Fake implements BookmarkRepository {
  @override
  Future<Either<Failure, Unit>> deleteBookmark(String bookmarkId) async =>
      const Right(unit);

  @override
  Future<Either<Failure, List<BookmarkDTO>>> refreshBookmarks({
    String? language,
  }) async => const Right([]);
}

/// Signed out, so it never fetches; the screen sees [bookmarks] as if loaded.
class _SeededBookmarksNotifier extends BookmarksNotifier {
  _SeededBookmarksNotifier(List<BookmarkDTO> bookmarks)
    : super(_FakeBookmarkRepository(), 'en', isAuthenticated: false) {
    state = BookmarksState(bookmarks: bookmarks);
  }
}

BookmarkDTO _bookmark(String id, BookmarkItemType type, String name) =>
    BookmarkDTO(
      id: id,
      type: type,
      sourceId: 'source-$id',
      name: name,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      timerDurationMs: type == BookmarkItemType.timer ? 600000 : null,
    );

final _plan = _bookmark('1', BookmarkItemType.plan, 'Plan bookmark');
final _chant = _bookmark(
  '2',
  BookmarkItemType.recitationCollection,
  'Chant bookmark',
);
final _mala = _bookmark('3', BookmarkItemType.accumulator, 'Mala bookmark');
final _groupAccumulation = _bookmark(
  '4',
  BookmarkItemType.groupAccumulator,
  'Group bookmark',
);
final _timer = _bookmark('5', BookmarkItemType.timer, 'Timer bookmark');
final _text = _bookmark('6', BookmarkItemType.text, 'Text bookmark');

/// One bookmark per type, so every filter pill is shown.
final _oneOfEach = [
  _plan,
  _chant,
  _mala,
  _groupAccumulation,
  _timer,
  _text,
];

void main() {
  late AppLocalizations l10n;
  late MaterialLocalizations materialL10n;

  Future<void> pumpScreen(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    List<BookmarkDTO>? bookmarks,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarksProvider.overrideWith(
            (ref) => _SeededBookmarksNotifier(bookmarks ?? _oneOfEach),
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
  /// group as the hint ("Tab 2 of 7"). [shown] is the pills on screen, in
  /// order; every pill by default.
  Matcher pill(String label, {required bool selected, List<String>? shown}) {
    final labels = shown ?? pillLabels();
    return containsSemantics(
      label: label,
      hint: materialL10n.tabLabel(
        tabIndex: labels.indexOf(label) + 1,
        tabCount: labels.length,
      ),
      isButton: true,
      isSelected: selected,
    );
  }

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
    expect(find.text(_plan.name!).hitTestable(), findsOneWidget);
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
    expect(find.text(_timer.name!).hitTestable(), findsOneWidget);
    expect(find.text(_text.name!).hitTestable(), findsNothing);
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
    expect(find.text(_plan.name!).hitTestable(), findsOneWidget);
    expect(find.text(_text.name!).hitTestable(), findsNothing);
    semantics.dispose();
  });

  testWidgets('with no bookmarks only the All pill is shown', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester, bookmarks: const []);

    expect(
      tester.getSemantics(find.text(l10n.search_all)),
      pill(l10n.search_all, selected: true, shown: [l10n.search_all]),
    );
    for (final label in pillLabels().skip(1)) {
      expect(find.text(label), findsNothing);
    }
    expect(find.text(l10n.bookmarks_empty_all_title), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('hides the pills of types without bookmarks', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester, bookmarks: [_timer, _text]);

    final shown = [l10n.search_all, l10n.bookmark_timers, l10n.bookmark_texts];
    for (final label in shown) {
      expect(
        tester.getSemantics(find.text(label)),
        pill(label, selected: label == l10n.search_all, shown: shown),
      );
    }
    for (final label in pillLabels().where((l) => !shown.contains(l))) {
      expect(find.text(label), findsNothing);
    }

    // Pages follow the shown pills: the second page is Timers, not Plans.
    await tester.fling(find.byType(TabBarView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text(l10n.bookmark_timers)),
      pill(l10n.bookmark_timers, selected: true, shown: shown),
    );
    expect(find.text(_timer.name!).hitTestable(), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('removing the last bookmark of the open filter hides its pill '
      'and returns to All', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester, bookmarks: [_timer, _text]);

    await tester.tap(find.text(l10n.bookmark_timers));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BookmarksScreen)),
    );
    await container.read(bookmarksProvider.notifier).remove(_timer);
    await tester.pumpAndSettle();

    expect(find.text(l10n.bookmark_timers), findsNothing);
    final shown = [l10n.search_all, l10n.bookmark_texts];
    expect(
      tester.getSemantics(find.text(l10n.search_all)),
      pill(l10n.search_all, selected: true, shown: shown),
    );
    expect(find.text(_text.name!).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('removing a bookmark keeps the open filter when it still has '
      'some', (tester) async {
    final semantics = tester.ensureSemantics();
    final secondText = _bookmark('7', BookmarkItemType.text, 'Second text');
    await pumpScreen(tester, bookmarks: [_timer, _text, secondText]);

    await tester.tap(find.text(l10n.bookmark_texts));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BookmarksScreen)),
    );
    await container.read(bookmarksProvider.notifier).remove(_text);
    await tester.pumpAndSettle();

    final shown = [l10n.search_all, l10n.bookmark_timers, l10n.bookmark_texts];
    expect(
      tester.getSemantics(find.text(l10n.bookmark_texts)),
      pill(l10n.bookmark_texts, selected: true, shown: shown),
    );
    expect(find.text(secondText.name!).hitTestable(), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('pills meet the minimum tap target size', (tester) async {
    final semantics = tester.ensureSemantics();
    // No bookmarks: the guidelines check every tappable on screen, and only
    // the pills are under test here, not the cards.
    await pumpScreen(tester, bookmarks: const []);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    // The other pills only show with bookmarks, so measure them directly.
    // Unmount first so the next pump gets a fresh ProviderScope and notifier.
    await tester.pumpWidget(const SizedBox());
    await pumpScreen(tester);
    for (final label in pillLabels()) {
      final size = tester.getSemantics(find.text(label)).rect.size;
      expect(size.width, greaterThanOrEqualTo(kMinInteractiveDimension));
      expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));
    }
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
