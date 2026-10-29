import 'dart:async';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fake_screen_cache_store.dart';

const _key = 'v1:p:en:thing';
typedef _Either = Either<Failure, String>;

void main() {
  late FakeScreenCacheStore store;
  late List<Object> responses;
  late int fetchCalls;

  setUp(() {
    store = FakeScreenCacheStore();
    responses = [];
    fetchCalls = 0;
  });

  ScreenCacheSource<String> source() {
    return ScreenCacheSource<String>(
      store: store,
      key: _key,
      fetchJson: () async {
        fetchCalls++;
        if (responses.isEmpty) throw const NetworkException('offline');
        return responses.removeAt(0);
      },
      fromJson: (json) => (json as Map<String, dynamic>)['v'] as String,
      failureMessage: 'Unable to load thing',
    );
  }

  final eitherProvider = AsyncNotifierProvider<
    ScreenCacheNotifier<String, _Either>,
    _Either
  >(() => ScreenCacheNotifier((ref, bind) => bind.source(source())));

  final valueProvider = AsyncNotifierProvider.autoDispose<
    AutoDisposeScreenCacheNotifier<String, String>,
    String
  >(
    () => AutoDisposeScreenCacheNotifier(
      (ref, bind) => bind.source(
        source(),
        select: (r) => r.fold((f) => throw Exception(f.message), (v) => v),
      ),
    ),
  );

  test('stored value is the state on the very first read', () async {
    store.entries[_key] = '{"v":"stored"}';
    responses = [
      {'v': 'fresh'},
    ];
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final seen = <_Either>[];
    container.listen(eitherProvider, (_, next) {
      if (next.hasValue) seen.add(next.requireValue);
    }, fireImmediately: true);

    final first = container.read(eitherProvider);
    expect(first.isLoading, isFalse);
    expect(first.requireValue, const Right<Failure, String>('stored'));

    await pumpEventQueue();
    expect(seen, [
      const Right<Failure, String>('stored'),
      const Right<Failure, String>('fresh'),
    ]);
    expect(fetchCalls, 1);
  });

  test('unchanged response causes no second state', () async {
    store.entries[_key] = '{"v":"same"}';
    responses = [
      {'v': 'same'},
    ];
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var changes = 0;
    container.listen(eitherProvider, (_, __) => changes++);
    await pumpEventQueue();
    expect(changes, 0);
  });

  test('nothing stored loads first, then shows the fetched value', () async {
    responses = [
      {'v': 'fresh'},
    ];
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(eitherProvider, (_, __) {});
    expect(container.read(eitherProvider).isLoading, isTrue);
    await pumpEventQueue();
    expect(
      container.read(eitherProvider).requireValue,
      const Right<Failure, String>('fresh'),
    );
  });

  test('a first-load failure is a Left; invalidate fetches again', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(eitherProvider, (_, __) {});
    await pumpEventQueue();
    expect(container.read(eitherProvider).requireValue.isLeft(), isTrue);

    responses = [
      {'v': 'fresh'},
    ];
    container.invalidate(eitherProvider);
    await pumpEventQueue();
    expect(
      container.read(eitherProvider).requireValue,
      const Right<Failure, String>('fresh'),
    );
    expect(fetchCalls, 2);
  });

  test('select can turn a failure into an error state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(valueProvider, (_, __) {});
    await pumpEventQueue();
    expect(container.read(valueProvider).hasError, isTrue);
  });

  test('a stored write from elsewhere updates the state', () async {
    store.entries[_key] = '{"v":"stored"}';
    responses = [
      {'v': 'stored'},
    ];
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(valueProvider, (_, __) {});
    await pumpEventQueue();
    await store.save(_key, '{"v":"pushed"}');
    await pumpEventQueue();
    expect(container.read(valueProvider).requireValue, 'pushed');
  });

  test('stream binding seeds from another store', () async {
    final updates = StreamController<String>();
    addTearDown(updates.close);
    final seeded = AsyncNotifierProvider<
      ScreenCacheNotifier<String, String>,
      String
    >(() => ScreenCacheNotifier((ref, bind) => bind.stream('local', updates.stream)));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(seeded, (_, __) {});
    expect(container.read(seeded).requireValue, 'local');
    updates.add('remote');
    await pumpEventQueue();
    expect(container.read(seeded).requireValue, 'remote');
  });

  test('fixed and pending notifiers serve tests', () async {
    final fixed = AsyncNotifierProvider<
      ScreenCacheNotifier<String, _Either>,
      _Either
    >(() => ScreenCacheNotifier.fixed(const Right('x')));
    final pending = AsyncNotifierProvider<
      ScreenCacheNotifier<String, _Either>,
      _Either
    >(() => ScreenCacheNotifier.pending());
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(fixed).requireValue, const Right<Failure, String>('x'));
    expect(container.read(pending).isLoading, isTrue);
    await pumpEventQueue();
    expect(container.read(pending).isLoading, isTrue);
  });
}
