import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_initial_layout.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_context_layout_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_secondary_version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';
import '../fakes/fake_reader_settings_datasource.dart';

const _scope = ReaderSettingsScope(
  textId: 'text-1',
  context: ReaderLayoutContext.event,
);

const _hindi = ReaderLanguageOption(code: 'hi', label: 'Hindi', versionCount: 1);
const _english = ReaderLanguageOption(
  code: 'en',
  label: 'English',
  versionCount: 1,
);
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

/// The event default for a Tibetan text: Roman + English.
const _romanAndEnglish = ReaderInitialLayout(
  originalVisible: true,
  originalScriptId: 'phonetic',
  translationOn: true,
  translationLanguage: 'en',
);

/// Keeps the scope's settings alive; its element doubles as the [WidgetRef]
/// and [BuildContext] the fill helpers take.
class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(readerDualSettingsProvider(_scope));
    return const SizedBox.shrink();
  }
}

Future<Element> _pumpHost(
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
        home: const _Host(),
      ),
    ),
  );
  return tester.element(find.byType(_Host));
}

Future<SecondaryFillOutcome> _fill(Element host, List<String> candidates) =>
    fillSecondaryWithLanguages(
      ref: host as WidgetRef,
      context: host,
      scope: _scope,
      sourceLanguage: 'bo',
      sourceVersionId: 'text-1',
      candidates: candidates,
    );

Future<bool> _fillPreferred(Element host) => fillPreferredSecondary(
  ref: host as WidgetRef,
  context: host,
  scope: _scope,
  sourceLanguage: 'bo',
  sourceVersionId: 'text-1',
);

ReaderSlotConfig _secondaryOf(Element host) =>
    (host as WidgetRef).read(readerDualSettingsProvider(_scope)).secondary;

ReaderDualSettingsNotifier _notifierOf(Element host) =>
    (host as WidgetRef).read(readerDualSettingsProvider(_scope).notifier);

ReaderContextLayoutNotifier _eventStoreOf(Element host) => (host as WidgetRef)
    .read(readerContextLayoutProvider(ReaderLayoutContext.event).notifier);

void main() {
  group('fillSecondaryWithLanguages', () {
    testWidgets('moves on to the next candidate when the first has no version', (
      tester,
    ) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_hindi, _english],
        versions: {'hi': [], 'en': [_englishVersion]},
      );
      final host = await _pumpHost(tester, datasource);

      expect(await _fill(host, ['hi', 'en']), SecondaryFillOutcome.filled);
      expect(datasource.versionRequests, ['hi', 'en']);
      final secondary = _secondaryOf(host);
      expect(secondary.languageCode, 'en');
      expect(secondary.versionId, 'v-en');
      expect(secondary.versionUnavailable, isFalse);
    });

    testWidgets('a failed versions request is passed over the same way', (
      tester,
    ) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_hindi, _english],
        versions: {'en': [_englishVersion]},
      );
      final host = await _pumpHost(tester, datasource);

      expect(await _fill(host, ['hi', 'en']), SecondaryFillOutcome.filled);
      expect(_secondaryOf(host).versionId, 'v-en');
    });

    testWidgets('a failed request with nothing filled is failed, not '
        'unavailable', (tester) async {
      // Hindi has no version; English's request fails. English may exist,
      // so a stored "on" must not be held off.
      final datasource = FakeReaderSettingsDatasource(
        languages: [_hindi, _english],
        versions: {'hi': []},
      );
      final host = await _pumpHost(tester, datasource);

      expect(await _fill(host, ['en', 'hi']), SecondaryFillOutcome.failed);
      expect(datasource.versionRequests, ['en', 'hi']);
      expect(_secondaryOf(host).versionUnavailable, isTrue);
    });

    testWidgets('an automatic fill is not the person\'s pick', (tester) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_english],
        versions: {'en': [_englishVersion]},
      );
      final host = await _pumpHost(tester, datasource);

      expect(await _fill(host, ['en']), SecondaryFillOutcome.filled);
      expect(_notifierOf(host).isSecondaryEdited, isFalse);

      _notifierOf(host).replaceSecondary(
        const ReaderSlotConfig(languageCode: 'hi', languageLabel: 'Hindi'),
      );
      expect(_notifierOf(host).isSecondaryEdited, isTrue);
    });

    testWidgets('the last candidate stays marked unavailable', (tester) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_hindi, _english],
        versions: {'hi': [], 'en': []},
      );
      final host = await _pumpHost(tester, datasource);

      expect(
        await _fill(host, ['hi', 'en']),
        SecondaryFillOutcome.unavailable,
      );
      expect(datasource.versionRequests, ['hi', 'en']);
      final secondary = _secondaryOf(host);
      expect(secondary.languageCode, 'en');
      expect(secondary.versionId, isNull);
      expect(secondary.versionUnavailable, isTrue);
    });

    testWidgets('skips the source language and languages the text lacks', (
      tester,
    ) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_hindi, _english],
        versions: {'en': [_englishVersion]},
      );
      final host = await _pumpHost(tester, datasource);

      expect(await _fill(host, ['bo', 'zh', 'en']), SecondaryFillOutcome.filled);
      expect(datasource.versionRequests, ['en']);
      expect(_secondaryOf(host).languageCode, 'en');
    });

    testWidgets('nothing offered is unavailable and leaves the slot alone', (
      tester,
    ) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_hindi, _english],
        versions: {'en': [_englishVersion]},
      );
      final host = await _pumpHost(tester, datasource);

      expect(await _fill(host, ['bo', 'zh']), SecondaryFillOutcome.unavailable);
      expect(datasource.versionRequests, isEmpty);
      expect(_secondaryOf(host).isUnset, isTrue);
    });

    testWidgets('a pick made meanwhile is left alone', (tester) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_hindi, _english],
        versions: {'hi': [], 'en': [_englishVersion]},
      );
      datasource.gates['hi'] = Completer<void>();
      final host = await _pumpHost(tester, datasource);

      final result = _fill(host, ['hi', 'en']);
      // Languages arrive and the fill starts resolving Hindi.
      await tester.pump();
      expect(datasource.versionRequests, ['hi']);

      const manual = ReaderSlotConfig(
        languageCode: 'zh',
        languageLabel: 'Chinese',
        versionId: 'v-zh',
      );
      (host as WidgetRef)
          .read(readerDualSettingsProvider(_scope).notifier)
          .replaceSecondary(manual);
      datasource.gates['hi']!.complete();
      await tester.pump();

      expect(await result, SecondaryFillOutcome.superseded);
      expect(_secondaryOf(host), manual);
      expect(datasource.versionRequests, ['hi'], reason: 'English never tried');
    });

    testWidgets(
      'a pick made while the last lookup finds nothing is superseded, '
      'not unavailable',
      (tester) async {
        final datasource = FakeReaderSettingsDatasource(
          languages: [_hindi, _english],
          versions: {'hi': []},
        );
        datasource.gates['hi'] = Completer<void>();
        final host = await _pumpHost(tester, datasource);

        final result = _fill(host, ['hi']);
        await tester.pump();

        // The reader picks English in the sheet and its version loads.
        const manual = ReaderSlotConfig(
          languageCode: 'en',
          languageLabel: 'English',
          versionId: 'v-en',
        );
        (host as WidgetRef)
            .read(readerDualSettingsProvider(_scope).notifier)
            .replaceSecondary(manual);
        datasource.gates['hi']!.complete();
        await tester.pump();

        // Unavailable would let a stored "on" be held off over this pick.
        expect(await result, SecondaryFillOutcome.superseded);
        expect(_secondaryOf(host), manual);
      },
    );
  });

  group('remembered translation edition', () {
    testWidgets('the edition picked for this text comes back', (tester) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_english],
        versions: {
          'en': [_englishVersion, _simpleEnglishVersion],
        },
      );
      final host = await _pumpHost(tester, datasource);
      _eventStoreOf(host).setTranslationVersion('text-1', 'v-en-2');

      expect(await _fill(host, ['en']), SecondaryFillOutcome.filled);
      expect(_secondaryOf(host).versionId, 'v-en-2');
      expect(_secondaryOf(host).versionLabel, 'English (Simple)');
    });

    testWidgets('an edition the language no longer offers falls back to the '
        'first', (tester) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_english],
        versions: {
          'en': [_englishVersion, _simpleEnglishVersion],
        },
      );
      final host = await _pumpHost(tester, datasource);
      _eventStoreOf(host).setTranslationVersion('text-1', 'v-gone');

      expect(await _fill(host, ['en']), SecondaryFillOutcome.filled);
      expect(_secondaryOf(host).versionId, 'v-en');
    });

    testWidgets('replaces the opened edition when it is in the same language', (
      tester,
    ) async {
      // The Tara plan links v-en; the person picked the Simple English here.
      final datasource = FakeReaderSettingsDatasource(
        languages: [_english],
        versions: {
          'en': [_englishVersion, _simpleEnglishVersion],
        },
      );
      final host = await _pumpHost(tester, datasource);
      _notifierOf(host).openAsTranslation(
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
      _eventStoreOf(host).setTranslationVersion('text-1', 'v-en-2');

      expect(await _fill(host, ['en']), SecondaryFillOutcome.filled);
      expect(_secondaryOf(host).versionId, 'v-en-2');
    });

    testWidgets('the opened edition comes back before the first one', (
      tester,
    ) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_english],
        versions: {
          'en': [_englishVersion, _simpleEnglishVersion],
        },
      );
      final host = await _pumpHost(tester, datasource);
      _notifierOf(host).openAsTranslation(
        original: const ReaderSlotConfig(
          languageCode: 'bo',
          languageLabel: 'bo',
          versionId: 'bo-root',
        ),
        translation: const ReaderSlotConfig(
          languageCode: 'en',
          languageLabel: 'English',
          versionId: 'v-en-2',
        ),
      );
      // Remembered, but no longer offered.
      _eventStoreOf(host).setTranslationVersion('text-1', 'v-gone');

      expect(await _fill(host, ['en']), SecondaryFillOutcome.filled);
      expect(_secondaryOf(host).versionId, 'v-en-2');
      expect(datasource.versionRequests, ['en']);
    });

    testWidgets('a slot already holding the remembered edition is done', (
      tester,
    ) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_english],
        versions: {
          'en': [_englishVersion, _simpleEnglishVersion],
        },
      );
      final host = await _pumpHost(tester, datasource);
      _notifierOf(host).fillSecondary(
        const ReaderSlotConfig(
          languageCode: 'en',
          languageLabel: 'English',
          versionId: 'v-en-2',
        ),
      );
      _eventStoreOf(host).setTranslationVersion('text-1', 'v-en-2');

      expect(await _fill(host, ['en']), SecondaryFillOutcome.filled);
      expect(datasource.versionRequests, isEmpty);
    });

    testWidgets('another text keeps its own pick', (tester) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_english],
        versions: {
          'en': [_englishVersion, _simpleEnglishVersion],
        },
      );
      final host = await _pumpHost(tester, datasource);
      _eventStoreOf(host).setTranslationVersion('text-2', 'v-en-2');

      expect(await _fill(host, ['en']), SecondaryFillOutcome.filled);
      expect(_secondaryOf(host).versionId, 'v-en');
    });
  });

  group('fillPreferredSecondary', () {
    testWidgets(
      "switching on again keeps the event's English when the app language "
      'is missing',
      (tester) async {
        // Chinese UI on the Tara praise, whose only translation is English.
        final datasource = FakeReaderSettingsDatasource(
          languages: [_english],
          versions: {'en': [_englishVersion]},
        );
        final host = await _pumpHost(tester, datasource);
        final ref = host as WidgetRef;
        await ref.read(contentLanguageProvider.notifier).setContentLanguage('zh');
        _notifierOf(host).seed(_romanAndEnglish, language: 'bo');

        expect(await _fillPreferred(host), isTrue);
        expect(_secondaryOf(host).versionId, 'v-en');
        expect(
          ref.read(readerDualSettingsProvider(_scope)).secondaryEnabled,
          isTrue,
        );
      },
    );

    testWidgets('the language picked last time in this context wins', (
      tester,
    ) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_hindi, _english],
        versions: {
          'hi': [_hindiVersion],
          'en': [_englishVersion],
        },
      );
      final host = await _pumpHost(tester, datasource);
      _eventStoreOf(host).setTranslationLanguage('hi');
      _notifierOf(host).seed(_romanAndEnglish, language: 'bo');

      expect(await _fillPreferred(host), isTrue);
      expect(_secondaryOf(host).versionId, 'v-hi');
      expect(datasource.versionRequests, ['hi']);
    });

    testWidgets('after a failed lookup is held off, switching on again '
        'requests the versions afresh', (tester) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_english],
        versions: {},
      );
      final host = await _pumpHost(tester, datasource);
      _eventStoreOf(host).setTranslationOn(true);
      final notifier = _notifierOf(host);
      notifier.seed(_romanAndEnglish, language: 'bo');

      expect(await _fill(host, ['en']), SecondaryFillOutcome.failed);
      notifier.markTranslationUnavailable();
      final settings = (host as WidgetRef).read(
        readerDualSettingsProvider(_scope),
      );
      expect(settings.secondaryEnabled, isFalse, reason: 'sheet reads off');

      // The failed request is disposed (autoDispose) before anyone can tap.
      await tester.pump();
      // The network is back; the person switches the translation on.
      datasource.versions['en'] = [_englishVersion];
      notifier.setSecondaryEnabled(true);
      expect(await _fillPreferred(host), isTrue);
      expect(_secondaryOf(host).versionId, 'v-en');
      expect(datasource.versionRequests, ['en', 'en']);
    });

    testWidgets('nothing offered leaves the translation off', (tester) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: [_hindi],
        versions: {'hi': [_hindiVersion]},
      );
      final host = await _pumpHost(tester, datasource);
      _notifierOf(host).seed(_romanAndEnglish, language: 'bo');

      expect(await _fillPreferred(host), isFalse);
      expect(
        (host as WidgetRef)
            .read(readerDualSettingsProvider(_scope))
            .secondaryEnabled,
        isFalse,
      );
    });
  });
}
