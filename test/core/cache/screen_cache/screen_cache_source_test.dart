import 'dart:async';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fake_screen_cache_store.dart';

const _key = 'v1:p:en:thing';

void main() {
  late FakeScreenCacheStore store;
  late List<Object> responses;
  late int fetchCalls;

  setUp(() {
    store = FakeScreenCacheStore();
    responses = [];
    fetchCalls = 0;
  });

  ScreenCacheSource<String> source({Future<Object> Function()? fetch}) {
    return ScreenCacheSource<String>(
      store: store,
      key: _key,
      fetchJson:
          fetch ??
          () async {
            fetchCalls++;
            if (responses.isEmpty) throw const NetworkException('offline');
            return responses.removeAt(0);
          },
      fromJson: (json) => (json as Map<String, dynamic>)['v'] as String,
      failureMessage: 'Unable to load thing',
    );
  }

  Future<List<Either<Failure, String>>> collect(
    Stream<Either<Failure, String>> stream,
  ) async {
    final events = <Either<Failure, String>>[];
    final sub = stream.listen(events.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    return events;
  }

  test('first load fetches, saves and renders', () async {
    responses = [
      {'v': 'fresh'},
    ];
    final events = await collect(source().watch());
    expect(events, [const Right<Failure, String>('fresh')]);
    expect(store.entries[_key], '{"v":"fresh"}');
  });

  test('first load failure surfaces as a Left, later refresh recovers',
      () async {
    final src = source();
    final events = await collect(src.watch());
    expect(events, hasLength(1));
    expect(events.single.isLeft(), isTrue);
    expect(events.single.getLeft().toNullable(), isA<NetworkFailure>());

    responses = [
      {'v': 'fresh'},
    ];
    expect(await src.refresh(), const Right<Failure, String>('fresh'));
    await pumpEventQueue();
    expect(events.last, const Right<Failure, String>('fresh'));
  });

  test('cached value shows first and the changed response replaces it',
      () async {
    store.entries[_key] = '{"v":"old"}';
    responses = [
      {'v': 'new'},
    ];
    final events = await collect(source().watch());
    expect(events, [
      const Right<Failure, String>('old'),
      const Right<Failure, String>('new'),
    ]);
  });

  test('unchanged response emits nothing after the cached value', () async {
    store.entries[_key] = '{"v":"same"}';
    responses = [
      {'v': 'same'},
    ];
    final events = await collect(source().watch());
    expect(events, [const Right<Failure, String>('same')]);
    expect(fetchCalls, 1);
  });

  test('failed background refresh keeps the cached value silently', () async {
    store.entries[_key] = '{"v":"old"}';
    final events = await collect(source().watch());
    expect(events, [const Right<Failure, String>('old')]);
  });

  test('corrupt cache is dropped and treated as a miss', () async {
    store.entries[_key] = 'not json';
    responses = [
      {'v': 'fresh'},
    ];
    final events = await collect(source().watch());
    expect(events, [const Right<Failure, String>('fresh')]);
    expect(fetchCalls, 1);
    expect(store.entries[_key], '{"v":"fresh"}');
  });

  test('a write from elsewhere reaches an open stream', () async {
    store.entries[_key] = '{"v":"old"}';
    responses = [
      {'v': 'old'},
    ];
    final events = await collect(source().watch());
    await store.save(_key, '{"v":"pushed"}');
    await pumpEventQueue();
    expect(events.last, const Right<Failure, String>('pushed'));
  });

  test('an unreadable response keeps the stored value', () async {
    store.entries[_key] = '{"v":"old"}';
    responses = [
      {'other': 1},
    ];
    final events = await collect(source().watch());
    expect(events, [const Right<Failure, String>('old')]);
    expect(store.entries[_key], '{"v":"old"}');
  });

  test('an unreadable first response is a failure, not a hang', () async {
    responses = [
      {'other': 1},
    ];
    final events = await collect(source().watch());
    expect(events, hasLength(1));
    expect(events.single.getLeft().toNullable(), isA<CacheFailure>());
    expect(store.entries[_key], isNull);
  });

  test('refresh returns the mapped failure when the fetch throws', () async {
    final result = await source().refresh();
    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
  });

  test('watch and a concurrent refresh share one fetch', () async {
    final gate = Completer<Object>();
    var calls = 0;
    final src = source(
      fetch: () {
        calls++;
        return gate.future;
      },
    );
    final events = await collect(src.watch());
    final refreshed = src.refresh();
    gate.complete({'v': 'once'});
    expect(await refreshed, const Right<Failure, String>('once'));
    await pumpEventQueue();
    expect(calls, 1);
    expect(events, [const Right<Failure, String>('once')]);
  });
}
