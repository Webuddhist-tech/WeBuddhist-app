import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_more_bottom_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';

/// Opens the More sheet the way the reader does, on a 390 x 844 phone.
Future<void> _open(
  WidgetTester tester, {
  bool showAddToPractices = false,
  VoidCallback? onAddToPractices,
  VoidCallback? onAudioVersions,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
        isBookmarkedProvider.overrideWith((ref, target) => false),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => showReaderMoreBottomSheet(
                        context,
                        textId: 'T',
                        showAddToPractices: showAddToPractices,
                        onAddToPractices: onAddToPractices,
                        onAudioVersions: onAudioVersions,
                      ),
                  child: const Text('open'),
                ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('More: add to practices, bookmark, share, and no sizes', (
    tester,
  ) async {
    await _open(tester, showAddToPractices: true, onAddToPractices: () {});

    expect(find.text('More'), findsOneWidget);
    expect(find.text('Add to my practices'), findsOneWidget);
    expect(find.text('Bookmark'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    // Three actions, two rules between them.
    expect(find.byType(ReaderSheetRow), findsNWidgets(3));
    expect(find.byType(ReaderSheetDivider), findsNWidgets(2));
    // The size buttons moved to Display.
    expect(find.text('A'), findsNothing);
    expect(find.byTooltip('Larger text'), findsNothing);
  });

  testWidgets('a row the reader cannot offer is left out', (tester) async {
    await _open(tester);
    expect(find.text('Add to my practices'), findsNothing);
    expect(find.byType(ReaderSheetRow), findsNWidgets(2));
  });

  testWidgets('an action closes the sheet, then runs', (tester) async {
    var added = 0;
    var audio = 0;
    await _open(
      tester,
      showAddToPractices: true,
      onAddToPractices: () => added++,
      onAudioVersions: () => audio++,
    );
    // Audio versions shows where the chant has recordings.
    expect(find.byType(ReaderSheetRow), findsNWidgets(4));

    await tester.tap(find.text('Add to my practices'));
    await tester.pumpAndSettle();
    expect(added, 1);
    expect(find.byType(ReaderMoreBottomSheet), findsNothing);
  });
}
