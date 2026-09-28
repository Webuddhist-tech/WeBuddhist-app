import 'dart:async';

import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_context_layout_prefs.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_context_layout_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_local_storage.dart';

/// Storage whose write of one value is held back until the test releases it,
/// so a later write can land first — the ordering a real store may produce.
class _HeldWriteStorage extends FakeLocalStorage {
  _HeldWriteStorage({required this.heldValue});

  final Object heldValue;
  final _release = Completer<void>();

  void release() => _release.complete();

  @override
  Future<bool> set<T>(String key, T value) async {
    if (value == heldValue) await _release.future;
    return super.set<T>(key, value);
  }
}

void main() {
  group('readerLayoutsNeedReset', () {
    test('a different language drops the picks', () {
      expect(readerLayoutsNeedReset(stamped: 'en', current: 'hi'), isTrue);
    });

    test('the same language keeps them, whatever the case', () {
      expect(readerLayoutsNeedReset(stamped: 'en', current: ' EN '), isFalse);
    });

    test('nothing recorded yet drops nothing', () {
      expect(readerLayoutsNeedReset(stamped: null, current: 'hi'), isFalse);
    });
  });

  group('ReaderLayoutLanguageGuard', () {
    late FakeLocalStorage storage;
    late ProviderContainer container;

    const contexts = [
      ReaderLayoutContext.event,
      ReaderLayoutContext.plan,
      ReaderLayoutContext.chant,
    ];
    final picks =
        ReaderContextLayoutPrefs.empty.copyWith(translationOn: false).encode();

    String keyOf(ReaderLayoutContext context) =>
        StorageKeys.readerLayoutPrefs(context.name);

    /// Picks in every context, plus the library's app-wide reader settings.
    void storePicksIn(FakeLocalStorage target) {
      for (final context in contexts) {
        target.values[keyOf(context)] = picks;
      }
      target.values[StorageKeys.readerOriginalVisible] = false;
      target.values[StorageKeys.readerScriptPreference] = '{"bo":"phonetic"}';
    }

    void storePicks() => storePicksIn(storage);

    ReaderLayoutLanguageGuard guard() =>
        container.read(readerLayoutLanguageGuardProvider);

    setUp(() {
      storage = FakeLocalStorage();
      container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
    });

    tearDown(() => container.dispose());

    test('a new language drops the event, plan and chant picks', () async {
      storage.values[StorageKeys.readerLayoutLanguage] = 'en';
      storePicks();

      expect(await guard().sync('hi'), isTrue);

      for (final context in contexts) {
        expect(
          storage.values.containsKey(keyOf(context)),
          isFalse,
          reason: context.name,
        );
      }
      expect(storage.values[StorageKeys.readerLayoutLanguage], 'hi');
    });

    test('library reading keeps its settings', () async {
      storage.values[StorageKeys.readerLayoutLanguage] = 'en';
      storePicks();

      await guard().sync('hi');

      expect(storage.values[StorageKeys.readerOriginalVisible], isFalse);
      expect(
        storage.values[StorageKeys.readerScriptPreference],
        '{"bo":"phonetic"}',
      );
    });

    test('the same language keeps the picks', () async {
      storage.values[StorageKeys.readerLayoutLanguage] = 'hi';
      storePicks();

      expect(await guard().sync('HI'), isFalse);

      for (final context in contexts) {
        expect(storage.values[keyOf(context)], picks, reason: context.name);
      }
    });

    test('the first run records the language and keeps what is there', () async {
      storePicks();

      expect(await guard().sync('bo'), isFalse);

      expect(storage.values[StorageKeys.readerLayoutLanguage], 'bo');
      expect(storage.values[keyOf(ReaderLayoutContext.event)], picks);
    });

    test('switching away and back drops the picks each time', () async {
      storage.values[StorageKeys.readerLayoutLanguage] = 'en';
      storePicks();
      expect(await guard().sync('hi'), isTrue);

      storePicks();
      expect(await guard().sync('en'), isTrue);
      expect(
        storage.values.containsKey(keyOf(ReaderLayoutContext.plan)),
        isFalse,
      );
    });

    test('two quick changes leave the later language as the stamp', () async {
      final held = _HeldWriteStorage(heldValue: 'hi');
      container.dispose();
      container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(held)],
      );
      held.values[StorageKeys.readerLayoutLanguage] = 'en';

      final first = guard().sync('hi');
      final second = guard().sync('bo');
      await pumpEventQueue();
      // The first sync is still writing its stamp; the second waits for it.
      expect(held.values[StorageKeys.readerLayoutLanguage], 'en');

      held.release();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(held.values[StorageKeys.readerLayoutLanguage], 'bo');

      // Picks made under Tibetan now survive the next open.
      storePicksIn(held);
      expect(await guard().sync('bo'), isFalse);
      expect(held.values[keyOf(ReaderLayoutContext.event)], picks);
    });

    test('a live store starts over from no picks', () async {
      storage.values[StorageKeys.readerLayoutLanguage] = 'en';
      storePicks();
      final provider = readerContextLayoutProvider(ReaderLayoutContext.event);
      await container.read(provider.notifier).loaded;
      expect(container.read(provider).translationOn, isFalse);

      await guard().sync('zh');

      await container.read(provider.notifier).loaded;
      expect(container.read(provider), ReaderContextLayoutPrefs.empty);
    });
  });
}
