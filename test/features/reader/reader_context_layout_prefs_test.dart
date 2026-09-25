import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_context_layout_prefs.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_context_layout_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_local_storage.dart';

void main() {
  group('ReaderContextLayoutPrefs', () {
    test('starts with no picks', () {
      expect(ReaderContextLayoutPrefs.empty.originalVisible, isNull);
      expect(ReaderContextLayoutPrefs.empty.translationOn, isNull);
      expect(ReaderContextLayoutPrefs.empty.translationLanguage, isNull);
      expect(ReaderContextLayoutPrefs.empty.hasScriptFor('bo'), isFalse);
    });

    test('a deliberate "as written" is a pick, unlike no pick', () {
      final prefs = ReaderContextLayoutPrefs.empty.withScript('bo', null);
      expect(prefs, isNot(ReaderContextLayoutPrefs.empty));
      expect(prefs.hasScriptFor('bo'), isTrue);
      expect(prefs.scriptFor('bo'), isNull);
      expect(prefs.hasScriptFor('pi'), isFalse);
    });

    test('copyWith keeps the other fields', () {
      final prefs = ReaderContextLayoutPrefs.empty
          .copyWith(originalVisible: false)
          .copyWith(translationOn: true)
          .copyWith(translationLanguage: 'hi')
          .withScript('bo', 'phonetic:hi');
      expect(prefs.originalVisible, isFalse);
      expect(prefs.translationOn, isTrue);
      expect(prefs.translationLanguage, 'hi');
      expect(prefs.scriptFor('bo'), 'phonetic:hi');
    });

    test('round-trips through JSON, nulls included', () {
      final prefs = ReaderContextLayoutPrefs.empty
          .copyWith(originalVisible: false)
          .withScript('bo', 'phonetic')
          .withScript('pi', null);
      final decoded = ReaderContextLayoutPrefs.decode(prefs.encode());
      expect(decoded, prefs);
      expect(decoded.hasScriptFor('pi'), isTrue);
      expect(decoded.scriptFor('pi'), isNull);
      expect(decoded.translationOn, isNull);
    });

    test('a translation edition is kept per text, the latest pick winning', () {
      final prefs = ReaderContextLayoutPrefs.empty
          .withTranslationVersion('text-1', 'v-en')
          .withTranslationVersion('text-2', 'v-hi')
          .withTranslationVersion('text-1', 'v-en-2');
      expect(prefs.translationVersionFor('text-1'), 'v-en-2');
      expect(prefs.translationVersionFor('text-2'), 'v-hi');
      expect(prefs.translationVersionFor('text-3'), isNull);
      expect(
        prefs.translationVersions.keys,
        ['text-2', 'text-1'],
        reason: 'the newest pick is last',
      );
    });

    test('forgets the oldest text past the cap', () {
      var prefs = ReaderContextLayoutPrefs.empty;
      const cap = ReaderContextLayoutPrefs.maxTranslationVersions;
      for (var i = 0; i <= cap; i++) {
        prefs = prefs.withTranslationVersion('text-$i', 'v-$i');
      }
      expect(prefs.translationVersions, hasLength(cap));
      expect(prefs.translationVersionFor('text-0'), isNull);
      expect(prefs.translationVersionFor('text-1'), 'v-1');
      expect(prefs.translationVersionFor('text-$cap'), 'v-$cap');
    });

    test('translation editions round-trip in order, bad entries dropped', () {
      final prefs = ReaderContextLayoutPrefs.empty
          .withTranslationVersion('text-2', 'v-hi')
          .withTranslationVersion('text-1', 'v-en');
      final decoded = ReaderContextLayoutPrefs.decode(prefs.encode());
      expect(decoded, prefs);
      expect(decoded.translationVersions.keys, ['text-2', 'text-1']);

      final odd = ReaderContextLayoutPrefs.fromJson({
        'translationVersions': {'text-1': 3, 'text-2': null, 'text-3': 'v'},
      });
      expect(odd.translationVersions, {'text-3': 'v'});
      expect(
        ReaderContextLayoutPrefs.fromJson({'translationVersions': 'v'})
            .translationVersions,
        isEmpty,
      );
    });

    test('a corrupt or foreign value reads as no picks', () {
      expect(ReaderContextLayoutPrefs.decode('not json'), ReaderContextLayoutPrefs.empty);
      expect(ReaderContextLayoutPrefs.decode('[]'), ReaderContextLayoutPrefs.empty);
      final odd = ReaderContextLayoutPrefs.fromJson({
        'originalVisible': 'yes',
        'scripts': {
          'bo': 3,
          'pi': 'si',
        },
      });
      expect(odd.originalVisible, isNull);
      expect(odd.hasScriptFor('bo'), isFalse);
      expect(odd.scriptFor('pi'), 'si');
    });
  });

  group('ReaderContextLayoutNotifier', () {
    late FakeLocalStorage storage;
    late ProviderContainer container;
    final key = StorageKeys.readerLayoutPrefs(ReaderLayoutContext.event.name);

    setUp(() {
      storage = FakeLocalStorage();
      container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
    });

    tearDown(() => container.dispose());

    test('each context has its own key', () {
      expect(key, 'reader_layout_event');
      expect(
        StorageKeys.readerLayoutPrefs(ReaderLayoutContext.chant.name),
        'reader_layout_chant',
      );
    });

    test('loads the stored picks and persists changes', () async {
      storage.values[key] =
          ReaderContextLayoutPrefs.empty.copyWith(translationOn: false).encode();
      final provider = readerContextLayoutProvider(ReaderLayoutContext.event);
      final notifier = container.read(provider.notifier);
      expect(container.read(provider), ReaderContextLayoutPrefs.empty);

      await notifier.loaded;
      expect(container.read(provider).translationOn, isFalse);

      notifier.setScript(' BO ', 'phonetic');
      notifier.setTranslationLanguage('HI');
      notifier.setTranslationVersion('text-1', 'v-hi');
      final stored = ReaderContextLayoutPrefs.decode(
        storage.values[key] as String,
      );
      expect(stored.translationOn, isFalse);
      expect(stored.scriptFor('bo'), 'phonetic');
      expect(stored.translationLanguage, 'hi');
      expect(stored.translationVersionFor('text-1'), 'v-hi');
    });

    test('a change made before the load is replayed over the stored picks', () async {
      final chantKey = StorageKeys.readerLayoutPrefs(
        ReaderLayoutContext.chant.name,
      );
      storage.values[chantKey] =
          ReaderContextLayoutPrefs.empty.copyWith(originalVisible: false).encode();
      final provider = readerContextLayoutProvider(ReaderLayoutContext.chant);
      final notifier = container.read(provider.notifier);

      notifier.setScript('bo', null);
      expect(container.read(provider).hasScriptFor('bo'), isTrue);

      await notifier.loaded;
      final prefs = container.read(provider);
      expect(prefs.originalVisible, isFalse, reason: 'stored pick kept');
      expect(prefs.hasScriptFor('bo'), isTrue, reason: 'early edit kept');
      expect(
        ReaderContextLayoutPrefs.decode(storage.values[chantKey] as String),
        prefs,
        reason: 'the merged picks are written back',
      );
    });

    test('contexts do not share picks', () async {
      final event = readerContextLayoutProvider(ReaderLayoutContext.event);
      final plan = readerContextLayoutProvider(ReaderLayoutContext.plan);
      container.read(event.notifier).setOriginalVisible(false);
      await container.read(plan.notifier).loaded;
      expect(container.read(plan).originalVisible, isNull);
    });
  });
}
