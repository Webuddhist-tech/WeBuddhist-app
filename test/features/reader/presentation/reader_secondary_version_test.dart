import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/datasource/reader_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_script_option.dart';
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

/// Languages and versions served from memory. A language missing from
/// [versions] fails the way a network error would.
class _FakeSettingsDatasource implements ReaderSettingsRemoteDatasource {
  _FakeSettingsDatasource({required this.languages, required this.versions});

  final List<ReaderLanguageOption> languages;
  final Map<String, List<ReaderVersionDetail>> versions;

  /// Languages whose versions were asked for, in order.
  final List<String> versionRequests = [];

  /// A language listed here answers only once its completer completes.
  final Map<String, Completer<void>> gates = {};

  @override
  Future<ReaderLanguagesResponse> fetchLanguages({
    required String textId,
  }) async => ReaderLanguagesResponse(
    textId: textId,
    title: null,
    availableLanguages: languages,
  );

  @override
  Future<ReaderVersionsResponse> fetchVersions({
    required String textId,
    required String language,
  }) async {
    versionRequests.add(language);
    await gates[language]?.future;
    final found = versions[language];
    if (found == null) throw StateError('versions for $language failed');
    return ReaderVersionsResponse(
      textId: textId,
      language: language,
      availableVersions: found,
    );
  }

  @override
  Future<ReaderScriptsResponse> fetchScripts({
    required String textId,
    required String language,
  }) => throw UnimplementedError();

  @override
  Future<ReaderVersionDetail> fetchVersionInfo({required String versionId}) =>
      throw UnimplementedError();
}

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
  _FakeSettingsDatasource datasource,
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
      final datasource = _FakeSettingsDatasource(
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
      final datasource = _FakeSettingsDatasource(
        languages: [_hindi, _english],
        versions: {'en': [_englishVersion]},
      );
      final host = await _pumpHost(tester, datasource);

      expect(await _fill(host, ['hi', 'en']), SecondaryFillOutcome.filled);
      expect(_secondaryOf(host).versionId, 'v-en');
    });

    testWidgets('the last candidate stays marked unavailable', (tester) async {
      final datasource = _FakeSettingsDatasource(
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
      final datasource = _FakeSettingsDatasource(
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
      final datasource = _FakeSettingsDatasource(
        languages: [_hindi, _english],
        versions: {'en': [_englishVersion]},
      );
      final host = await _pumpHost(tester, datasource);

      expect(await _fill(host, ['bo', 'zh']), SecondaryFillOutcome.unavailable);
      expect(datasource.versionRequests, isEmpty);
      expect(_secondaryOf(host).isUnset, isTrue);
    });

    testWidgets('a pick made meanwhile is left alone', (tester) async {
      final datasource = _FakeSettingsDatasource(
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
        final datasource = _FakeSettingsDatasource(
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
      final datasource = _FakeSettingsDatasource(
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
      final datasource = _FakeSettingsDatasource(
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

    testWidgets('another text keeps its own pick', (tester) async {
      final datasource = _FakeSettingsDatasource(
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
        final datasource = _FakeSettingsDatasource(
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
      final datasource = _FakeSettingsDatasource(
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

    testWidgets('nothing offered leaves the translation off', (tester) async {
      final datasource = _FakeSettingsDatasource(
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
