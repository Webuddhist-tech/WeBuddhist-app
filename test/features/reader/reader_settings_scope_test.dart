import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_context_layout_prefs.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_initial_layout.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_context_layout_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_local_storage.dart';

const _library = ReaderSettingsScope(
  textId: 'text-1',
  context: ReaderLayoutContext.library,
);
const _event = ReaderSettingsScope(
  textId: 'text-1',
  context: ReaderLayoutContext.event,
);

const _romanAndEnglish = ReaderInitialLayout(
  originalVisible: true,
  originalScriptId: 'phonetic',
  translationOn: true,
  translationLanguage: 'en',
);

const _translationOnly = ReaderInitialLayout(
  originalVisible: false,
  translationOn: true,
  translationLanguage: 'hi',
);

void main() {
  late FakeLocalStorage storage;
  late ProviderContainer container;

  setUp(() {
    storage = FakeLocalStorage();
    container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
  });

  tearDown(() => container.dispose());

  /// autoDispose: keeps the settings alive for the test.
  ReaderDualSettingsNotifier keep(ReaderSettingsScope scope) {
    final sub = container.listen(readerDualSettingsProvider(scope), (_, __) {});
    addTearDown(sub.close);
    return container.read(readerDualSettingsProvider(scope).notifier);
  }

  ReaderDualLayoutSettings settingsOf(ReaderSettingsScope scope) =>
      container.read(readerDualSettingsProvider(scope));

  group('ReaderSettingsScope', () {
    test('is the text in a context', () {
      expect(
        const ReaderSettingsScope(
          textId: 'text-1',
          context: ReaderLayoutContext.event,
        ),
        _event,
      );
      expect(_library, isNot(_event));
      expect(
        _library,
        isNot(
          const ReaderSettingsScope(
            textId: 'text-2',
            context: ReaderLayoutContext.library,
          ),
        ),
      );
    });

    test('ReaderParams derives it from the navigation context', () {
      const library = ReaderParams(textId: 'text-1');
      expect(library.settingsScope, _library);

      const event = ReaderParams(
        textId: 'text-1',
        navigationContext: NavigationContext(
          source: NavigationSource.plan,
          eventId: 'event-1',
        ),
      );
      expect(event.settingsScope, _event);
    });
  });

  group('readerDualSettingsProvider: library', () {
    test('mirrors and writes the app-wide toggles, as before', () {
      final notifier = keep(_library);
      notifier.setSecondaryEnabled(true);
      expect(container.read(readerSecondaryEnabledProvider), isTrue);
      expect(storage.values[StorageKeys.readerSecondaryEnabled], isTrue);
      expect(
        storage.values.keys.where((k) => k.startsWith('reader_layout_')),
        isEmpty,
      );
    });

    test('script picks go to the app-wide map', () async {
      final notifier = keep(_library);
      await container.read(readerScriptPreferenceProvider.notifier).loaded;
      notifier.setOriginalScript('bo', 'phonetic');
      expect(container.read(readerScriptForLanguageProvider('bo')), 'phonetic');
      expect(settingsOf(_library).originalScriptId, isNull);
    });

    test('ignores seeds', () {
      final notifier = keep(_library);
      notifier.seed(_translationOnly, language: 'bo');
      notifier.seedTranslationOn();
      expect(settingsOf(_library).originalVisible, isTrue);
      expect(settingsOf(_library).secondaryEnabled, isFalse);
    });
  });

  group('readerDualSettingsProvider: event', () {
    test('the same text keeps separate slot picks per context', () {
      keep(_library);
      keep(_event).replaceSecondary(
        const ReaderSlotConfig(
          languageCode: 'en',
          languageLabel: 'English',
          versionId: 'v-en',
        ),
      );
      expect(settingsOf(_event).secondary.versionId, 'v-en');
      expect(settingsOf(_library).secondary.isUnset, isTrue);
    });

    test('toggles write the event store, never the app-wide flags', () {
      keep(_library);
      final notifier = keep(_event);
      notifier.setSecondaryEnabled(true);
      notifier.setOriginalVisible(false);

      final prefs = container.read(
        readerContextLayoutProvider(ReaderLayoutContext.event),
      );
      expect(prefs.translationOn, isTrue);
      expect(prefs.originalVisible, isFalse);
      expect(settingsOf(_event).secondaryEnabled, isTrue);
      expect(settingsOf(_event).originalVisible, isFalse);

      expect(container.read(readerSecondaryEnabledProvider), isFalse);
      expect(container.read(readerOriginalVisibleProvider), isTrue);
      expect(settingsOf(_library).secondaryEnabled, isFalse);
      expect(storage.values[StorageKeys.readerSecondaryEnabled], isNull);
    });

    test('one layer stays on', () {
      final notifier = keep(_event);
      notifier.setOriginalVisible(false);
      expect(settingsOf(_event).secondaryEnabled, isTrue);

      notifier.setSecondaryEnabled(false);
      expect(settingsOf(_event).originalVisible, isTrue);
      expect(
        container
            .read(readerContextLayoutProvider(ReaderLayoutContext.event))
            .originalVisible,
        isTrue,
      );
    });

    test('a seed fills in what the store has no pick for', () {
      final notifier = keep(_event);
      notifier.seed(_romanAndEnglish, language: 'bo');
      expect(settingsOf(_event).originalVisible, isTrue);
      expect(settingsOf(_event).originalScriptId, 'phonetic');
      expect(
        settingsOf(_event).secondaryEnabled,
        isFalse,
        reason: 'not until a version exists',
      );

      notifier.seedTranslationOn();
      expect(settingsOf(_event).secondaryEnabled, isTrue);
      expect(
        container.read(readerContextLayoutProvider(ReaderLayoutContext.event)),
        ReaderContextLayoutPrefs.empty,
        reason: 'seeds are never persisted',
      );
    });

    test('translation only seeds the original off', () {
      keep(_event).seed(_translationOnly, language: 'bo');
      expect(settingsOf(_event).originalVisible, isFalse);
      expect(settingsOf(_event).originalScriptId, isNull);
    });

    test('stored picks win over the seed, including "as written"', () {
      final store = container.read(
        readerContextLayoutProvider(ReaderLayoutContext.event).notifier,
      );
      store.setScript('bo', null);
      store.setOriginalVisible(false);
      store.setTranslationOn(false);

      final notifier = keep(_event);
      notifier.seed(_romanAndEnglish, language: 'bo');
      notifier.seedTranslationOn();

      expect(settingsOf(_event).originalScriptId, isNull);
      expect(settingsOf(_event).originalVisible, isFalse);
      expect(settingsOf(_event).secondaryEnabled, isFalse);
    });

    test('a stored "on" with nothing to show is held off until switched on', () {
      final store = container.read(
        readerContextLayoutProvider(ReaderLayoutContext.event).notifier,
      );
      store.setTranslationOn(true);
      store.setOriginalVisible(false);

      final notifier = keep(_event);
      notifier.seed(const ReaderInitialLayout.asWritten(), language: 'en');
      expect(settingsOf(_event).secondaryEnabled, isTrue);

      notifier.markTranslationUnavailable();
      expect(settingsOf(_event).secondaryEnabled, isFalse);
      expect(settingsOf(_event).originalVisible, isTrue);
      expect(
        container
            .read(readerContextLayoutProvider(ReaderLayoutContext.event))
            .translationOn,
        isTrue,
        reason: 'the pick is kept for the next text in this context',
      );

      notifier.setSecondaryEnabled(true);
      expect(settingsOf(_event).secondaryEnabled, isTrue);
      expect(settingsOf(_event).originalVisible, isFalse);
    });

    test('hiding the original lifts a held-off translation', () {
      container
          .read(readerContextLayoutProvider(ReaderLayoutContext.event).notifier)
          .setTranslationOn(true);
      final notifier = keep(_event);
      notifier.seed(const ReaderInitialLayout.asWritten(), language: 'en');
      notifier.markTranslationUnavailable();

      notifier.setOriginalVisible(false);
      expect(settingsOf(_event).secondaryEnabled, isTrue);
      expect(settingsOf(_event).originalVisible, isFalse);
    });

    test('a stored pick for another language leaves the seed in place', () {
      container
          .read(readerContextLayoutProvider(ReaderLayoutContext.event).notifier)
          .setScript('pi', 'si');
      keep(_event).seed(_romanAndEnglish, language: 'bo');
      expect(settingsOf(_event).originalScriptId, 'phonetic');
    });

    test('a pick made during the visit replaces the seed and is stored', () {
      final notifier = keep(_event);
      notifier.seed(_romanAndEnglish, language: 'bo');
      notifier.setOriginalScript('bo', 'phonetic:hi');
      expect(settingsOf(_event).originalScriptId, 'phonetic:hi');
      final stored = container.read(
        readerContextLayoutProvider(ReaderLayoutContext.event),
      );
      expect(stored.scriptFor('bo'), 'phonetic:hi');
      expect(container.read(readerScriptForLanguageProvider('bo')), isNull);
    });

    test('remembers the translation language picked', () {
      keep(_event).rememberTranslationLanguage('ZH');
      expect(
        container
            .read(readerContextLayoutProvider(ReaderLayoutContext.event))
            .translationLanguage,
        'zh',
      );
      keep(_library).rememberTranslationLanguage('zh');
      expect(
        container
            .read(readerContextLayoutProvider(ReaderLayoutContext.library))
            .translationLanguage,
        isNull,
      );
    });

    test('remembers the translation edition for this text only', () {
      const otherText = ReaderSettingsScope(
        textId: 'text-2',
        context: ReaderLayoutContext.event,
      );
      keep(_event).rememberTranslationVersion('v-en-2');
      expect(keep(_event).rememberedTranslationVersionId, 'v-en-2');
      expect(keep(otherText).rememberedTranslationVersionId, isNull);

      keep(_library).rememberTranslationVersion('v-en-2');
      expect(keep(_library).rememberedTranslationVersionId, isNull);
    });

    test('tries the last pick, then the default, then the app language', () {
      final notifier = keep(_event);
      expect(
        notifier.preferredTranslationLanguages(contentLanguage: 'zh'),
        ['zh'],
        reason: 'nothing picked or seeded yet',
      );

      notifier.seed(_romanAndEnglish, language: 'bo');
      expect(
        notifier.preferredTranslationLanguages(contentLanguage: 'zh'),
        ['en', 'zh'],
        reason: "Chinese UI on an English-only text keeps the event's English",
      );

      notifier.rememberTranslationLanguage('hi');
      expect(
        notifier.preferredTranslationLanguages(contentLanguage: 'zh'),
        ['hi', 'en', 'zh'],
      );
    });

    test('the library tries only the app language', () {
      container
          .read(readerContextLayoutProvider(ReaderLayoutContext.event).notifier)
          .setTranslationLanguage('hi');
      final notifier = keep(_library);
      notifier.seed(_romanAndEnglish, language: 'bo');
      expect(
        notifier.preferredTranslationLanguages(contentLanguage: 'zh'),
        ['zh'],
      );
    });
  });

  group('readerOriginalScriptProvider', () {
    String? scriptOf(ReaderSettingsScope scope, String language) {
      final provider = readerOriginalScriptProvider(
        ReaderScriptScope(scope: scope, language: language),
      );
      final sub = container.listen(provider, (_, __) {});
      addTearDown(sub.close);
      return container.read(provider);
    }

    test('the library reads the app-wide map', () async {
      final prefs = container.read(readerScriptPreferenceProvider.notifier);
      await prefs.loaded;
      prefs.setScript('bo', 'phonetic');
      expect(scriptOf(_library, 'bo'), 'phonetic');
      expect(scriptOf(_library, 'pi'), isNull);
    });

    test('an event reads its own settings, not the app-wide map', () async {
      final prefs = container.read(readerScriptPreferenceProvider.notifier);
      await prefs.loaded;
      prefs.setScript('bo', 'phonetic');
      expect(scriptOf(_event, 'bo'), isNull);

      keep(_event).seed(_romanAndEnglish, language: 'bo');
      expect(scriptOf(_event, 'BO '), 'phonetic');
    });

    test('scopes normalise the language code', () {
      expect(
        ReaderScriptScope(scope: _event, language: ' BO '),
        ReaderScriptScope(scope: _event, language: 'bo'),
      );
      expect(
        ReaderScriptScope(scope: _event, language: 'bo'),
        isNot(ReaderScriptScope(scope: _library, language: 'bo')),
      );
    });
  });
}
