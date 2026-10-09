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

final _params = ReaderParams(
  textId: 'bo-root',
  navigationContext: NavigationContext(
    source: NavigationSource.plan,
    planTextItems: [
      PlanTextItem.sourceReference(
        textId: 'bo-root',
        title: 'Root',
        translationTextId: 'text-en',
        autoOpenTranslation: true,
      ),
    ],
    currentTextIndex: 0,
  ),
);

const _english = ReaderLanguageOption(
  code: 'en',
  label: 'English',
  versionCount: 1,
);
const _planEdition = ReaderVersionDetail(
  id: 'ed-en',
  title: 'English edition',
  language: 'en',
);

class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(readerDualSettingsProvider(_params.settingsScope));
    ref.watch(readerLanguagesProvider(_params.textId));
    return const SizedBox.shrink();
  }
}

void main() {
  testWidgets(
    'a plan translation id shows under the original ahead of a saved pick',
    (tester) async {
      final datasource = FakeReaderSettingsDatasource(
        languages: const [_english],
        versions: const {
          'en': [_planEdition],
        },
        versionInfo: const {'text-en': _planEdition},
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readerSettingsRemoteDatasourceProvider.overrideWithValue(
              datasource,
            ),
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
      await tester.pump();
      final host = tester.element(find.byType(_Host));
      final ref = host as WidgetRef;
      ref
          .read(readerContextLayoutProvider(ReaderLayoutContext.plan).notifier)
          .setTranslationOn(false);

      await ReaderInitialLayoutApplier().applyForText(
        ref: ref,
        context: host,
        params: _params,
        textLanguage: 'bo',
        textVersionId: 'bo-root',
      );

      final settings = ref.read(readerDualSettingsProvider(_params.settingsScope));
      expect(settings.secondary.versionId, 'ed-en');
      expect(settings.secondaryEnabled, isTrue);
      expect(settings.originalVisible, isTrue);
      expect(
        ref.read(readerContextLayoutProvider(ReaderLayoutContext.plan)).translationOn,
        isFalse,
        reason: 'the saved switch is left alone',
      );

      ref
          .read(readerDualSettingsProvider(_params.settingsScope).notifier)
          .replaceSecondary(
            const ReaderSlotConfig(
              languageCode: 'en',
              languageLabel: 'English',
              versionId: 'ed-other',
              versionLabel: 'Other edition',
            ),
          );
      final picked = ref.read(readerDualSettingsProvider(_params.settingsScope));
      expect(picked.secondary.versionId, 'ed-other');
      expect(picked.secondaryEnabled, isTrue);
      expect(picked.originalVisible, isTrue);
    },
  );
}
