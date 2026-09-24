import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/interlinear_segment_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_local_storage.dart';

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

  group('ReaderDualLayoutSettings.originalVisible', () {
    test('defaults to true and survives a JSON round trip', () {
      final initial = ReaderDualLayoutSettings.initial();
      expect(initial.originalVisible, isTrue);

      final hidden = initial.copyWith(originalVisible: false);
      final decoded = ReaderDualLayoutSettings.decode(hidden.encode());
      expect(decoded.originalVisible, isFalse);
      expect(decoded, hidden);

      // Old persisted settings without the field read as visible.
      expect(ReaderDualLayoutSettings.decode('{}').originalVisible, isTrue);
    });
  });

  group('ReaderOriginalVisibleNotifier', () {
    test('loads the persisted value and persists changes', () async {
      storage.values[StorageKeys.readerOriginalVisible] = false;
      final notifier = container.read(readerOriginalVisibleProvider.notifier);
      expect(container.read(readerOriginalVisibleProvider), isTrue);

      await notifier.loaded;
      expect(container.read(readerOriginalVisibleProvider), isFalse);

      notifier.setVisible(true);
      expect(storage.values[StorageKeys.readerOriginalVisible], isTrue);
    });

    test('a change made before the load is not reverted by it', () async {
      storage.values[StorageKeys.readerOriginalVisible] = true;
      storage.values[StorageKeys.readerSecondaryEnabled] = false;
      final original = container.read(readerOriginalVisibleProvider.notifier);
      final secondary = container.read(
        readerSecondaryEnabledProvider.notifier,
      );

      original.setVisible(false);
      secondary.setEnabled(true);
      await Future.wait([original.loaded, secondary.loaded]);

      expect(container.read(readerOriginalVisibleProvider), isFalse);
      expect(container.read(readerSecondaryEnabledProvider), isTrue);
      expect(storage.values[StorageKeys.readerOriginalVisible], isFalse);
      expect(storage.values[StorageKeys.readerSecondaryEnabled], isTrue);
    });
  });

  group('interlinearLayers', () {
    test('both layers while the original is shown', () {
      for (final hasTranslation in [true, false]) {
        final layers = interlinearLayers(
          showOriginal: true,
          hasTranslation: hasTranslation,
        );
        expect(layers.original, isTrue);
        expect(layers.translation, isTrue);
      }
    });

    test('translation only draws the translation when there is one', () {
      final layers = interlinearLayers(
        showOriginal: false,
        hasTranslation: true,
      );
      expect(layers.original, isFalse);
      expect(layers.translation, isTrue);
    });

    test('translation only falls back to the original when the translation '
        'failed or is missing for the verse', () {
      final layers = interlinearLayers(
        showOriginal: false,
        hasTranslation: false,
      );
      expect(layers.original, isTrue, reason: 'never an empty verse');
      expect(layers.translation, isFalse, reason: 'no placeholder instead');
    });

    test('translation only draws the loading line, not the original, while '
        "the verse's translation is on its way", () {
      final layers = interlinearLayers(
        showOriginal: false,
        hasTranslation: false,
        translationPending: true,
      );
      expect(layers.original, isFalse, reason: 'the original must not flash');
      expect(layers.translation, isTrue);
    });
  });

  group('interlinearTranslationFor', () {
    test('returns the verse line when it has loaded', () {
      expect(interlinearTranslationFor({3: 'Homage'}, 3), 'Homage');
    });

    test('is null while loading, after a failure or with no aligned line', () {
      expect(interlinearTranslationFor(null, 3), isNull);
      expect(interlinearTranslationFor(const {}, 3), isNull);
      expect(interlinearTranslationFor({4: 'Homage'}, 3), isNull);
      expect(
        interlinearTranslationFor({3: '  \n'}, 3),
        isNull,
        reason: 'a blank line would show as an empty verse',
      );
    });
  });

  group('ReaderDualSettingsNotifier', () {
    test('mirrors the global flag and restores the original when the '
        'translation is switched off', () async {
      final provider = readerDualSettingsProvider('text-1');
      // autoDispose: keep it alive for the test.
      final sub = container.listen(provider, (_, __) {});
      addTearDown(sub.close);
      final notifier = container.read(provider.notifier);

      notifier.setSecondaryEnabled(true);
      notifier.setOriginalVisible(false);
      expect(container.read(provider).originalVisible, isFalse);
      expect(container.read(readerOriginalVisibleProvider), isFalse);

      notifier.setSecondaryEnabled(false);
      expect(container.read(provider).secondaryEnabled, isFalse);
      expect(
        container.read(provider).originalVisible,
        isTrue,
        reason: 'the screen must never be empty',
      );
      expect(storage.values[StorageKeys.readerOriginalVisible], isTrue);
    });

    test('hiding the original while the translation is off switches the '
        'translation on', () {
      final provider = readerDualSettingsProvider('text-2');
      final sub = container.listen(provider, (_, __) {});
      addTearDown(sub.close);
      final notifier = container.read(provider.notifier);
      expect(container.read(provider).secondaryEnabled, isFalse);

      notifier.setOriginalVisible(false);

      expect(container.read(provider).originalVisible, isFalse);
      expect(container.read(provider).secondaryEnabled, isTrue);
      expect(storage.values[StorageKeys.readerSecondaryEnabled], isTrue);
    });

    test('opening a translation shows it alone under its root without '
        'touching the persisted flags', () async {
      final provider = readerDualSettingsProvider('translation-edition');
      final sub = container.listen(provider, (_, __) {});
      addTearDown(sub.close);
      final notifier = container.read(provider.notifier);
      const root = ReaderSlotConfig(
        languageCode: 'bo',
        languageLabel: 'bo',
        versionId: 'root-edition',
        versionLabel: 'ཟབ་ཏིག',
      );
      const translation = ReaderSlotConfig(
        languageCode: 'en',
        languageLabel: 'en',
        versionId: 'translation-edition',
        versionLabel: 'Tara Essence',
      );

      notifier.openAsTranslation(original: root, translation: translation);

      final settings = container.read(provider);
      expect(settings.primary, root);
      expect(settings.secondary, translation);
      expect(settings.secondaryEnabled, isTrue);
      expect(settings.originalVisible, isFalse);
      expect(notifier.isPrimaryEdited, isTrue);
      expect(container.read(readerSecondaryEnabledProvider), isFalse);
      expect(container.read(readerOriginalVisibleProvider), isTrue);
      expect(storage.values, isEmpty);

      // The global already holds "visible", so only this text can flip it.
      notifier.setOriginalVisible(true);
      expect(container.read(provider).originalVisible, isTrue);

      notifier.setSecondaryEnabled(false);
      expect(container.read(provider).secondaryEnabled, isFalse);
      expect(container.read(provider).primary, root);
    });
  });
}
