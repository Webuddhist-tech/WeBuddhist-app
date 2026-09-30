import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_context_layout_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_initial_layout_applier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_local_storage.dart';
import 'fakes/fake_reader_settings_datasource.dart';

/// A Tibetan root opened through its English edition from an event, as the
/// Tara event's plans link it.
const _eventParams = ReaderParams(
  textId: 'v-en',
  navigationContext: NavigationContext(
    source: NavigationSource.plan,
    eventId: 'event-1',
  ),
);

const _english = ReaderLanguageOption(
  code: 'en',
  label: 'English',
  versionCount: 2,
);
const _hindi = ReaderLanguageOption(code: 'hi', label: 'Hindi', versionCount: 1);
const _englishVersion = ReaderVersionDetail(
  id: 'v-en',
  title: 'English edition',
  language: 'en',
);
const _simpleEnglishVersion = ReaderVersionDetail(
  id: 'v-en-2',
  title: 'English (Simple)',
  language: 'en',
);
const _hindiVersion = ReaderVersionDetail(
  id: 'v-hi',
  title: 'Hindi edition',
  language: 'hi',
);

/// Keeps the reader's settings and its list of translations alive, as the
/// reader screen does; its element doubles as the [WidgetRef] and
/// [BuildContext] the applier takes.
class _ReaderHost extends ConsumerWidget {
  const _ReaderHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(readerDualSettingsProvider(_eventParams.settingsScope));
    ref.watch(readerLanguagesProvider(_eventParams.textId));
    return const SizedBox.shrink();
  }
}

/// Pumps the host, lets the list of translations load, and opens the
/// English edition under its root the way `ReaderNotifier` does.
Future<Element> _openEnglishUnderRoot(
  WidgetTester tester,
  FakeReaderSettingsDatasource datasource,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        readerSettingsRemoteDatasourceProvider.overrideWithValue(datasource),
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _ReaderHost(),
      ),
    ),
  );
  await tester.pump();
  final host = tester.element(find.byType(_ReaderHost));
  _dualOf(host).openAsTranslation(
    original: const ReaderSlotConfig(
      languageCode: 'bo',
      languageLabel: 'bo',
      versionId: 'bo-root',
    ),
    translation: const ReaderSlotConfig(
      languageCode: 'en',
      languageLabel: 'English',
      versionId: 'v-en',
    ),
  );
  return host;
}

ReaderDualSettingsNotifier _dualOf(Element host) => (host as WidgetRef).read(
  readerDualSettingsProvider(_eventParams.settingsScope).notifier,
);

ReaderDualLayoutSettings _settingsOf(Element host) =>
    (host as WidgetRef).read(readerDualSettingsProvider(_eventParams.settingsScope));

ReaderContextLayoutNotifier _eventStoreOf(Element host) => (host as WidgetRef)
    .read(readerContextLayoutProvider(ReaderLayoutContext.event).notifier);

/// Runs the applier once the root text is on screen.
Future<void> _apply(Element host) => ReaderInitialLayoutApplier().applyForText(
  ref: host as WidgetRef,
  context: host,
  params: _eventParams,
  textLanguage: 'bo',
  textVersionId: 'bo-root',
);

void main() {
  group('readerInitialLayoutStep', () {
    const loaded = AsyncData<List<ReaderLanguageOption>>([]);
    const loading = AsyncLoading<List<ReaderLanguageOption>>();
    const failed = AsyncError<List<ReaderLanguageOption>>(
      'offline',
      StackTrace.empty,
    );

    test('waits until the text and its list of translations are known', () {
      expect(
        readerInitialLayoutStep(applied: false, hasText: false, languages: loaded),
        ReaderInitialLayoutStep.wait,
      );
      expect(
        readerInitialLayoutStep(applied: false, hasText: true, languages: loading),
        ReaderInitialLayoutStep.wait,
      );
    });

    test('applies once both are known, and only once', () {
      expect(
        readerInitialLayoutStep(applied: false, hasText: true, languages: loaded),
        ReaderInitialLayoutStep.apply,
      );
      expect(
        readerInitialLayoutStep(applied: true, hasText: true, languages: loaded),
        ReaderInitialLayoutStep.wait,
      );
    });

    test('only seeds while the list failed to load, so a retry can still apply', () {
      expect(
        readerInitialLayoutStep(applied: false, hasText: true, languages: failed),
        ReaderInitialLayoutStep.seedOnly,
      );
      expect(
        readerInitialLayoutStep(applied: false, hasText: false, languages: failed),
        ReaderInitialLayoutStep.wait,
      );
    });
  });

  group('readerOpenedTranslationNeedsRefill', () {
    bool needsRefill({
      String? openedLanguage = 'en',
      String? openedVersionId = 'v-en',
      String? currentVersionId = 'v-en',
      String? rememberedLanguage,
      String? rememberedVersionId,
      bool pinnedByList = false,
    }) => readerOpenedTranslationNeedsRefill(
      openedLanguage: openedLanguage,
      openedVersionId: openedVersionId,
      currentVersionId: currentVersionId,
      rememberedLanguage: rememberedLanguage,
      rememberedVersionId: rememberedVersionId,
      pinnedByList: pinnedByList,
    );

    test('nothing remembered keeps the opened edition', () {
      expect(needsRefill(), isFalse);
    });

    test('another language picked in this context replaces it', () {
      expect(needsRefill(rememberedLanguage: 'zh'), isTrue);
      expect(
        needsRefill(rememberedLanguage: ' EN'),
        isFalse,
        reason: 'the same language, whatever the case',
      );
    });

    test('another edition picked for this text replaces it', () {
      expect(needsRefill(rememberedVersionId: 'v-en-2'), isTrue);
      expect(needsRefill(rememberedVersionId: 'v-en'), isFalse);
    });

    test('a slot written since opening is left alone', () {
      expect(
        needsRefill(currentVersionId: 'v-zh', rememberedLanguage: 'hi'),
        isFalse,
      );
    });

    test('a chant picked in the opened language keeps it', () {
      expect(
        needsRefill(rememberedLanguage: 'zh', pinnedByList: true),
        isFalse,
      );
    });

    test('a text that was not opened as a translation has nothing to swap', () {
      expect(
        needsRefill(
          openedLanguage: null,
          openedVersionId: null,
          rememberedLanguage: 'zh',
        ),
        isFalse,
      );
    });
  });

  group('applying over an opened translation', () {
    testWidgets('nothing remembered keeps the opened edition', (tester) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_english, _hindi],
        versions: {
          'en': [_englishVersion, _simpleEnglishVersion],
          'hi': [_hindiVersion],
        },
      );
      final host = await _openEnglishUnderRoot(tester, datasource);

      await _apply(host);

      final settings = _settingsOf(host);
      expect(settings.secondary.versionId, 'v-en');
      expect(settings.secondaryEnabled, isTrue);
      expect(settings.originalVisible, isTrue, reason: 'event keeps it on');
      expect(datasource.versionRequests, isEmpty);
    });

    testWidgets('the edition remembered for this text replaces it', (
      tester,
    ) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_english, _hindi],
        versions: {
          'en': [_englishVersion, _simpleEnglishVersion],
          'hi': [_hindiVersion],
        },
      );
      final host = await _openEnglishUnderRoot(tester, datasource);
      _eventStoreOf(host).setTranslationVersion('v-en', 'v-en-2');

      await _apply(host);

      final settings = _settingsOf(host);
      expect(settings.secondary.versionId, 'v-en-2');
      expect(settings.secondary.versionLabel, 'English (Simple)');
      expect(settings.secondaryEnabled, isTrue);
    });

    testWidgets('the language remembered for the event replaces it', (
      tester,
    ) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_english, _hindi],
        versions: {
          'en': [_englishVersion, _simpleEnglishVersion],
          'hi': [_hindiVersion],
        },
      );
      final host = await _openEnglishUnderRoot(tester, datasource);
      _eventStoreOf(host).setTranslationLanguage('hi');

      await _apply(host);

      final settings = _settingsOf(host);
      expect(settings.secondary.languageCode, 'hi');
      expect(settings.secondary.versionId, 'v-hi');
      expect(settings.secondaryEnabled, isTrue);
      expect(datasource.versionRequests, ['hi']);
    });

    testWidgets('a saved "translation off" stays off under the new pick', (
      tester,
    ) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_english, _hindi],
        versions: {
          'en': [_englishVersion, _simpleEnglishVersion],
          'hi': [_hindiVersion],
        },
      );
      final host = await _openEnglishUnderRoot(tester, datasource);
      _eventStoreOf(host)
        ..setTranslationLanguage('hi')
        ..setTranslationOn(false);

      await _apply(host);

      final settings = _settingsOf(host);
      expect(settings.secondary.versionId, 'v-hi', reason: 'shows when on');
      expect(settings.secondaryEnabled, isFalse);
      expect(settings.originalVisible, isTrue);
    });

    testWidgets('a remembered language with nothing to show puts the opened '
        'edition back', (tester) async {
      // Only Hindi is listed, and it has no version: every candidate fails.
      final datasource = FakeReaderSettingsDatasource(
        languages: [_hindi],
        versions: {'hi': []},
      );
      final host = await _openEnglishUnderRoot(tester, datasource);
      _eventStoreOf(host).setTranslationLanguage('hi');

      await _apply(host);

      final settings = _settingsOf(host);
      expect(datasource.versionRequests, ['hi']);
      expect(settings.secondary.languageCode, 'en');
      expect(settings.secondary.versionId, 'v-en');
      expect(settings.secondary.versionUnavailable, isFalse);
      expect(settings.secondaryEnabled, isTrue);
    });
  });
}
