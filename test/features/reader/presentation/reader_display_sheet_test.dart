import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_background_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_fonts_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_text_size_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_verse_numbers_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_bottom_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';
import '../fakes/fake_reader_settings_datasource.dart';

const _scope = ReaderSettingsScope(
  textId: 'T',
  context: ReaderLayoutContext.library,
);

const _original = ReaderSlotConfig(
  languageCode: 'bo',
  languageLabel: 'Tibetan',
  versionId: 'T',
);

const _english = ReaderSlotConfig(
  languageCode: 'en',
  languageLabel: 'English',
  versionId: 'E',
);

ReaderDualLayoutSettings _settings({
  bool enabled = false,
  bool originalVisible = true,
  String? versionId,
}) => ReaderDualLayoutSettings(
  secondaryEnabled: enabled,
  originalVisible: originalVisible,
  primary: _original,
  secondary: ReaderSlotConfig(
    languageCode: 'en',
    languageLabel: 'English',
    versionId: versionId,
  ),
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  ReaderSettingsScope? scope = _scope,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
        readerSettingsRemoteDatasourceProvider.overrideWithValue(
          FakeReaderSettingsDatasource(languages: const [], versions: const {}),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ReaderDisplaySheet(scope: scope, originalLanguage: 'bo'),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return ProviderScope.containerOf(
    tester.element(find.byType(ReaderDisplaySheet)),
  );
}

void main() {
  group('the lines a reader shows', () {
    test('no translation: the original alone', () {
      expect(readerShownLines(_settings()), (
        original: true,
        translation: false,
      ));
    });

    test('a translation on: both, or the translation alone', () {
      expect(readerShownLines(_settings(enabled: true, versionId: 'E')), (
        original: true,
        translation: true,
      ));
      expect(
        readerShownLines(
          _settings(enabled: true, originalVisible: false, versionId: 'E'),
        ),
        (original: false, translation: true),
      );
    });

    test('a translation switched on with no edition yet keeps the original', () {
      expect(
        readerShownLines(_settings(enabled: true, originalVisible: false)),
        (original: true, translation: false),
      );
    });
  });

  group('the Display sheet', () {
    testWidgets('a group per line on screen, each with its fonts', (
      tester,
    ) async {
      final container = await _pump(tester);
      final settings = container.read(readerDualSettingsProvider(_scope).notifier);

      // The original alone, as written: Tibetan, with the Tibetan fonts.
      expect(find.text('Original · Tibetan'), findsOneWidget);
      expect(find.textContaining('Translation ·'), findsNothing);
      expect(find.text('Noto Serif Tibetan'), findsOneWidget);
      expect(find.text('Literata'), findsNothing);

      // The translation alone: its group only, with the Latin fonts.
      settings.openAsTranslation(original: _original, translation: _english);
      await tester.pump();
      expect(find.textContaining('Original ·'), findsNothing);
      expect(find.text('Translation · English'), findsOneWidget);
      expect(find.text('Literata'), findsOneWidget);
      expect(find.text('Noto Serif Tibetan'), findsNothing);

      // A pill is as wide as its name, not the sheet.
      final pill = find.ancestor(
        of: find.text('Literata'),
        matching: find.byType(Container),
      );
      expect(tester.getSize(pill.first).width, lessThan(200));

      // Both lines.
      settings.setOriginalVisible(true);
      await tester.pump();
      expect(find.text('Original · Tibetan'), findsOneWidget);
      expect(find.text('Translation · English'), findsOneWidget);
    });

    testWidgets('the original in Roman phonetics takes the Latin fonts', (
      tester,
    ) async {
      final container = await _pump(tester);
      container.read(readerScriptPreferenceProvider.notifier).setScript(
        'bo',
        'phonetic',
      );
      await tester.pump();
      expect(find.text('Original · Roman'), findsOneWidget);
      expect(find.text('Literata'), findsOneWidget);
      expect(find.text('Noto Serif Tibetan'), findsNothing);
    });

    testWidgets('a pill picks that line\'s font, A | A its size', (
      tester,
    ) async {
      final container = await _pump(tester);
      await tester.tap(find.text('Noto Serif Tibetan'));
      await tester.pump();
      expect(
        container
            .read(readerFontsProvider)
            .fontFor(ReaderFontLine.original, ReaderScript.tibetan)
            .id,
        ReaderFonts.notoSerifTibetan.id,
      );
      // The translation's pick for Tibetan stays the default.
      expect(
        container
            .read(readerFontsProvider)
            .fontFor(ReaderFontLine.translation, ReaderScript.tibetan),
        ReaderFonts.defaultFor(ReaderScript.tibetan),
      );

      await tester.tap(find.byTooltip('Larger text'));
      await tester.pump();
      expect(container.read(readerTextSizeProvider).originalStep, 4);
      expect(container.read(readerTextSizeProvider).translationStep, 3);
    });

    testWidgets('a swatch picks the background', (tester) async {
      final container = await _pump(tester);
      await tester.tap(find.byTooltip('Gold'));
      await tester.pump();
      expect(container.read(readerBackgroundProvider), ReaderBackground.gold);
    });

    testWidgets('plan text: one size group and the background', (
      tester,
    ) async {
      final container = await _pump(tester, scope: null);
      expect(find.text('Text size'), findsOneWidget);
      expect(find.textContaining('Original ·'), findsNothing);
      expect(find.text('Source Serif 4'), findsNothing);
      expect(find.text('Background'), findsOneWidget);

      await tester.tap(find.byTooltip('Smaller text'));
      await tester.pump();
      expect(container.read(readerTextSizeProvider).originalStep, 2);
      // Nothing more to set for plan text.
      expect(find.text('More settings'), findsNothing);
    });
  });

  group('More settings', () {
    testWidgets('spacing and verse numbers, and back to Display', (
      tester,
    ) async {
      final container = await _open(tester);
      await tester.tap(find.text('More settings'));
      await tester.pumpAndSettle();
      expect(find.text('Line spacing'), findsOneWidget);
      expect(find.text('Background'), findsNothing);
      // Ritual instructions wait for texts that mark their directions.
      expect(find.text('Ritual instructions'), findsNothing);

      await tester.tap(find.text('Relaxed'));
      await tester.pump();
      expect(
        container.read(readerTextSizeProvider).spacing,
        ReaderSpacing.relaxed,
      );

      expect(container.read(readerVerseNumbersProvider), isTrue);
      await tester.tap(find.byType(ReaderSheetSwitch));
      await tester.pump();
      expect(container.read(readerVerseNumbersProvider), isFalse);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Background'), findsOneWidget);
      expect(find.text('Line spacing'), findsNothing);
    });

    testWidgets('Change languages closes the sheet, then opens Languages', (
      tester,
    ) async {
      var opened = 0;
      await _open(tester, onChangeLanguages: () => opened++);
      await tester.tap(find.text('More settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change languages'));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(find.byType(ReaderDisplaySheet), findsNothing);
    });
  });
}

/// Opens the Display sheet the way the reader does, on a 390 x 844 phone.
Future<ProviderContainer> _open(
  WidgetTester tester, {
  VoidCallback? onChangeLanguages,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
        readerSettingsRemoteDatasourceProvider.overrideWithValue(
          FakeReaderSettingsDatasource(languages: const [], versions: const {}),
        ),
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
                      () => showReaderDisplaySheet(
                        context,
                        scope: _scope,
                        originalLanguage: 'bo',
                        onChangeLanguages: onChangeLanguages,
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
  return ProviderScope.containerOf(
    tester.element(find.byType(ReaderDisplaySheet)),
  );
}
