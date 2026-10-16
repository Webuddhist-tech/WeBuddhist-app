import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/datasource/reader_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_script_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_languages_sheet.dart';
import 'package:flutter_pecha/shared/widgets/app_toggle_switch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';

const _refuge = ReaderSettingsScope(
  textId: 'refuge',
  context: ReaderLayoutContext.plan,
);
const _aspiration = ReaderSettingsScope(
  textId: 'aspiration',
  context: ReaderLayoutContext.plan,
);

ReaderSlotConfig _tibetan(String id) => ReaderSlotConfig(
  languageCode: 'bo',
  languageLabel: 'Tibetan',
  versionId: id,
  versionLabel: 'Text $id',
);

const _chinese = ReaderLanguageOption(code: 'zh', label: 'Chinese', versionCount: 1);
const _mongolian = ReaderLanguageOption(
  code: 'mn',
  label: 'Mongolian',
  versionCount: 1,
);

/// Languages and editions per text: the refuge prayer is translated into
/// Chinese only; the aspiration prayer into Chinese and Mongolian.
class _FakeSettings implements ReaderSettingsRemoteDatasource {
  final languages = <String, List<ReaderLanguageOption>>{
    'refuge': const [_chinese],
    'aspiration': const [_chinese, _mongolian],
  };
  final versions = <String, Map<String, List<ReaderVersionDetail>>>{
    'refuge': const {
      'zh': [ReaderVersionDetail(id: 'refuge-zh', title: 'Refuge Chinese', language: 'zh')],
    },
    'aspiration': const {
      'zh': [
        ReaderVersionDetail(
          id: 'aspiration-zh',
          title: 'Aspiration Chinese',
          language: 'zh',
        ),
      ],
      'mn': [
        ReaderVersionDetail(
          id: 'aspiration-mn',
          title: 'Aspiration Mongolian',
          language: 'mn',
        ),
      ],
    },
  };

  @override
  Future<ReaderLanguagesResponse> fetchLanguages({required String textId}) async =>
      ReaderLanguagesResponse(
        textId: textId,
        title: null,
        availableLanguages: languages[textId] ?? const [],
      );

  @override
  Future<ReaderVersionsResponse> fetchVersions({
    required String textId,
    required String language,
  }) async => ReaderVersionsResponse(
    textId: textId,
    language: language,
    availableVersions: versions[textId]?[language] ?? const [],
  );

  @override
  Future<ReaderScriptsResponse> fetchScripts({
    required String textId,
    required String language,
  }) => throw UnimplementedError();

  @override
  Future<ReaderVersionDetail> fetchVersionInfo({required String versionId}) =>
      throw StateError('version $versionId missing');
}

/// Keeps both texts' settings alive, as their readers do on the page.
class _KeepAlive extends ConsumerWidget {
  const _KeepAlive();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(readerDualSettingsProvider(_refuge));
    ref.watch(readerDualSettingsProvider(_aspiration));
    return const SizedBox.shrink();
  }
}

Future<WidgetRef> _pump(
  WidgetTester tester, {
  required List<ReaderLanguagesText> others,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
        readerSettingsRemoteDatasourceProvider.overrideWithValue(
          _FakeSettings(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              const _KeepAlive(),
              Expanded(
                child: ReaderLanguagesSheet(
                  scope: _refuge,
                  primaryDisplay: _tibetan('refuge'),
                  others: others,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
  return tester.element(find.byType(_KeepAlive)) as WidgetRef;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// The Translation switch is the second one; the Original switch is first.
Future<void> _switchTranslationOn(WidgetTester tester) async {
  await tester.tap(find.byType(AppToggleSwitch).at(1));
  await _settle(tester);
}

Future<void> _tapLanguage(WidgetTester tester, String code) async {
  await tester.tap(find.text(getNativeLanguageName(code)!).last);
  await _settle(tester);
}

ReaderSlotConfig _secondaryOf(WidgetRef ref, ReaderSettingsScope scope) =>
    ref.read(readerDualSettingsProvider(scope)).secondary;

void main() {
  testWidgets(
    'a language picked for one text of a task is picked for the others too',
    (tester) async {
      final ref = await _pump(
        tester,
        others: [
          ReaderLanguagesText(
            scope: _aspiration,
            primaryDisplay: _tibetan('aspiration'),
          ),
        ],
      );

      await _switchTranslationOn(tester);
      expect(
        ref.read(readerDualSettingsProvider(_aspiration)).secondaryEnabled,
        isTrue,
      );
      // Every language either text is translated into is offered.
      expect(find.text(getNativeLanguageName('mn')!), findsOneWidget);

      await _tapLanguage(tester, 'zh');
      expect(_secondaryOf(ref, _refuge).versionId, 'refuge-zh');
      expect(_secondaryOf(ref, _aspiration).versionId, 'aspiration-zh');
      // No edition is named: the field shows the language alone, and the
      // editions of the shown text do not open under it.
      expect(find.text(getNativeLanguageName('zh')!), findsNWidgets(2));
      expect(find.text('Refuge Chinese'), findsNothing);

      // A language only the other text has: that text shows it, this one
      // shows no translation.
      await _tapLanguage(tester, 'mn');
      expect(_secondaryOf(ref, _refuge).languageCode, 'mn');
      expect(_secondaryOf(ref, _refuge).versionId, isNull);
      expect(_secondaryOf(ref, _refuge).versionUnavailable, isTrue);
      expect(_secondaryOf(ref, _aspiration).versionId, 'aspiration-mn');
      expect(find.textContaining('${getNativeLanguageName('mn')!} ('), findsNothing);
    },
  );

  testWidgets('one text alone still names and offers its editions', (
    tester,
  ) async {
    final ref = await _pump(tester, others: const []);

    await _switchTranslationOn(tester);
    expect(find.text(getNativeLanguageName('mn')!), findsNothing);

    await _tapLanguage(tester, 'zh');
    expect(_secondaryOf(ref, _refuge).versionId, 'refuge-zh');
    expect(
      find.text('${getNativeLanguageName('zh')!} (Refuge Chinese)'),
      findsOneWidget,
    );
    expect(find.text('Refuge Chinese'), findsOneWidget);
  });
}
