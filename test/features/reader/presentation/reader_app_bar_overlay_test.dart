import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_analytics.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_app_bar.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_languages_button.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_search_button.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/texts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/analytics/recording_analytics_service.dart';
import '../fakes/fake_local_storage.dart';

const _params = ReaderParams(
  textId: 't1',
  navigationContext: NavigationContext(
    source: NavigationSource.plan,
    eventId: 'event-1',
  ),
);

/// The bar only reads the reader notifier for its back button, so the text
/// behind it never needs to load; the notifier's first fetch fails fast on
/// the overridden provider.
Future<void> _pumpBar(
  WidgetTester tester, {
  VoidCallback? onSearchPressed,
  Widget? liveSyncToggle,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
        readerAnalyticsProvider.overrideWithValue(
          ReaderAnalytics(RecordingAnalyticsService()),
        ),
        textDetailsFutureProvider.overrideWith(
          (ref, params) => left(const NetworkFailure('test')),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: ReaderAppBarOverlay(
              params: _params,
              onSearchPressed: onSearchPressed,
              onLanguagesPressed: () {},
              liveSyncToggle: liveSyncToggle,
              onFontSizePressed: () {},
            ),
          ),
        ),
      ),
    ),
  );
  // The notifier schedules its first load on a zero-length timer; let it
  // fire and fail so no timer is left pending at the end of the test.
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('a reader with a search handler shows the search button', (
    tester,
  ) async {
    await _pumpBar(tester, onSearchPressed: () {});

    expect(find.byType(ReaderSearchButton), findsOneWidget);
    expect(find.byTooltip('Search'), findsOneWidget);
    expect(find.byType(ReaderLanguagesButton), findsOneWidget);
  });

  testWidgets('the live-sync reader has no search button', (tester) async {
    await _pumpBar(
      tester,
      onSearchPressed: null,
      liveSyncToggle: const Text('Live'),
    );

    expect(find.text('Live'), findsOneWidget);
    expect(find.byType(ReaderSearchButton), findsNothing);
    expect(find.byIcon(Icons.search), findsNothing);
    // The rest of the bar is untouched.
    expect(find.byType(ReaderLanguagesButton), findsOneWidget);
    expect(find.byTooltip('Font size'), findsOneWidget);
  });
}
