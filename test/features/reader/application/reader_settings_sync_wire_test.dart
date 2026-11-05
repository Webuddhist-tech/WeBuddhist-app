import 'dart:convert';

import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_recitations_paginated_provider.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_context_layout_prefs.dart';
import 'package:flutter_pecha/features/reader/domain/sync/reader_settings_sync_plan.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_sync_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_appearance_prefs.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_background.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_text_size.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';

void main() {
  group('ReaderAppearancePrefs wire shape', () {
    test('defaults send nothing', () {
      expect(const ReaderAppearancePrefs().toWire(), isEmpty);
    });

    test('round trips what was changed', () {
      const prefs = ReaderAppearancePrefs(
        background: ReaderBackground.sky,
        textSize: ReaderTextSize(
          originalStep: 5,
          translationStep: 2,
          spacing: ReaderSpacing.relaxed,
        ),
        verseNumbers: false,
      );

      expect(prefs.toWire(), {
        'background': 'sky',
        'original_step': 5,
        'translation_step': 2,
        'spacing': 'relaxed',
        'verse_numbers': false,
      });
      expect(ReaderAppearancePrefs.fromWire(prefs.toWire()), prefs);
    });

    test('values it does not recognise read as defaults', () {
      final prefs = ReaderAppearancePrefs.fromWire(const {
        'background': 'neon',
        'original_step': 'big',
        'translation_step': 99,
        'spacing': 'huge',
        'fonts': 'none',
        'verse_numbers': 'no',
      });

      expect(prefs.background, ReaderBackground.defaultBackground);
      expect(prefs.textSize.originalStep, ReaderTextSize.defaultStep);
      expect(prefs.textSize.translationStep, ReaderTextSize.maxStep);
      expect(prefs.textSize.spacing, ReaderSpacing.normal);
      expect(prefs.verseNumbers, isTrue);
    });
  });

  group('ReaderContextLayoutPrefs wire shape', () {
    test('what was never picked is left out', () {
      expect(ReaderContextLayoutPrefs.empty.toWire(), isEmpty);
    });

    test('round trips every pick, "as written" included', () {
      const prefs = ReaderContextLayoutPrefs(
        originalVisible: false,
        translationOn: true,
        translationLanguage: 'zh',
        scripts: {'bo': null, 'pi': 'si'},
        translationVersions: {'text': 'version'},
      );

      expect(prefs.toWire(), {
        'original_visible': false,
        'translation_on': true,
        'translation_language': 'zh',
        'scripts': {'bo': null, 'pi': 'si'},
        'translation_versions': {'text': 'version'},
      });
      final throughJson =
          jsonDecode(jsonEncode(prefs.toWire())) as Map<String, dynamic>;
      expect(ReaderContextLayoutPrefs.fromWire(throughJson), prefs);
    });

    test('values of the wrong type read as no pick', () {
      expect(
        ReaderContextLayoutPrefs.fromWire(const {
          'original_visible': 'no',
          'scripts': 3,
        }),
        ReaderContextLayoutPrefs.empty,
      );
    });
  });

  group('ReaderSyncBlocks', () {
    test('key order does not count as a change', () {
      const a = ReaderSyncBlocks(appearance: {'spacing': 'relaxed', 'x': 1});
      const b = ReaderSyncBlocks(appearance: {'x': 1, 'spacing': 'relaxed'});

      expect(a.sameBlock(ReaderSyncBlock.appearance, b), isTrue);
    });

    test('a corrupt stored value reads as nothing synced', () {
      expect(ReaderSyncBlocks.decode('{oops'), isNull);
      expect(ReaderSyncBlocks.decode('[]'), isNull);
      expect(ReaderSyncBlocks.decode(null), isNull);
    });

    test('round trips through storage', () {
      const blocks = ReaderSyncBlocks(
        appearance: {'background': 'sky'},
        chant: {
          'scripts': {'bo': null},
        },
        listLanguage: 'hi',
      );

      final decoded = ReaderSyncBlocks.decode(blocks.encode())!;

      for (final block in ReaderSyncBlock.values) {
        expect(decoded.sameBlock(block, blocks), isTrue, reason: block.name);
      }
    });
  });

  group('ProviderReaderSyncStore', () {
    late FakeLocalStorage storage;
    late ProviderContainer container;
    late ProviderReaderSyncStore store;

    setUp(() {
      storage = FakeLocalStorage();
      container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
      store = container.read(Provider(ProviderReaderSyncStore.new));
    });

    tearDown(() async {
      // The list language notifier remembers its pick in a static.
      await container
          .read(practiceRecitationsLanguageProvider.notifier)
          .applySynced(null);
      container.dispose();
    });

    test('a new install reads as nothing to sync', () async {
      final blocks = await store.read();

      expect(blocks.appearance, isEmpty);
      expect(blocks.chant, isEmpty);
      expect(blocks.listLanguage, isNull);
    });

    test('settings from the server reach the stores and read back', () async {
      const appearance = {
        'background': 'plum',
        'original_step': 6,
        'spacing': 'compact',
        'verse_numbers': false,
      };
      const chant = {
        'translation_language': 'zh',
        'scripts': {'bo': null},
      };

      await store.applyAppearance(appearance);
      await store.applyChant(chant);
      await store.applyListLanguage('hi');

      final blocks = await store.read();
      expect(blocks.appearance, appearance);
      expect(blocks.chant, chant);
      expect(blocks.listLanguage, 'hi');
      expect(storage.values[StorageKeys.readerBackground], 'plum');
      expect(storage.values[StorageKeys.chantListLanguage], 'hi');
      expect(container.read(practiceRecitationsLanguageProvider), 'hi');
    });

    test('empty blocks put the stores back on their defaults', () async {
      await store.applyAppearance(const {'background': 'plum'});
      await store.applyChant(const {'translation_language': 'zh'});
      await store.applyListLanguage('hi');

      await store.applyAppearance(const {});
      await store.applyChant(const {});
      await store.applyListLanguage(null);

      final blocks = await store.read();
      expect(blocks.appearance, isEmpty);
      expect(blocks.chant, isEmpty);
      expect(blocks.listLanguage, isNull);
      expect(storage.values.containsKey(StorageKeys.chantListLanguage), isFalse);
    });

    test('a font pick from the server survives the trip', () async {
      const appearance = {
        'fonts': {
          'original': {'tibetan': 'jomolhari'},
        },
      };

      await store.applyAppearance(appearance);

      expect((await store.read()).appearance, appearance);
    });
  });
}
