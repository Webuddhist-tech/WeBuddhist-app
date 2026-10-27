import 'dart:async';
import 'dart:io';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ScreenCacheStore store;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('screen_cache_test');
    Hive.init(tempDir.path);
    await ScreenCacheStore.init();
    store = ScreenCacheStore();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(ScreenCacheStore.boxName);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('read misses before save and returns the saved payload', () async {
    expect(store.read('v1:p:en:x'), isNull);
    expect(await store.save('v1:p:en:x', '{"a":1}'), isTrue);
    expect(store.read('v1:p:en:x'), '{"a":1}');
  });

  test('identical save writes nothing and fires no watch event', () async {
    const key = 'v1:p:en:x';
    final events = <void>[];
    final sub = store.watch(key).listen(events.add);
    addTearDown(sub.cancel);

    await store.save(key, 'a');
    await store.save(key, 'a');
    await pumpEventQueue();
    expect(events, hasLength(1));

    expect(await store.save(key, 'a'), isFalse);
    expect(await store.save(key, 'b'), isTrue);
    await pumpEventQueue();
    expect(events, hasLength(2));
  });

  test('remove drops the entry', () async {
    await store.save('v1:p:en:x', 'a');
    await store.remove('v1:p:en:x');
    expect(store.read('v1:p:en:x'), isNull);
  });

  test('revalidate shares one fetch between concurrent callers', () async {
    final fetch = Completer<String>();
    var calls = 0;
    Future<String> fetchJson() {
      calls++;
      return fetch.future;
    }

    final first = store.revalidate('k', fetchJson);
    final second = store.revalidate('k', fetchJson);
    expect(calls, 1);

    fetch.complete('{"v":1}');
    expect(await first, '{"v":1}');
    expect(await second, '{"v":1}');
    expect(store.read('k'), '{"v":1}');

    await store.revalidate('k', fetchJson);
    expect(calls, 2);
  });

  test('revalidate error reaches every awaiter and clears the slot', () async {
    final fetch = Completer<String>();
    final first = store.revalidate('k', () => fetch.future);
    final second = store.revalidate('k', () => fetch.future);
    fetch.completeError(StateError('offline'));
    await expectLater(first, throwsStateError);
    await expectLater(second, throwsStateError);

    expect(await store.revalidate('k', () async => 'ok'), 'ok');
  });

  test('init drops entries written under an older schema', () async {
    final box = Hive.box<String>(ScreenCacheStore.boxName);
    await box.put('v0:old', 'old');
    await box.put('${ScreenCacheStore.versionPrefix}keep', 'keep');
    await box.close();

    await ScreenCacheStore.init();
    expect(store.read('v0:old'), isNull);
    expect(store.read('${ScreenCacheStore.versionPrefix}keep'), 'keep');
  });

  test('is a network-only no-op when the box never opened', () async {
    await Hive.box<String>(ScreenCacheStore.boxName).close();

    expect(store.read('k'), isNull);
    expect(await store.save('k', 'a'), isFalse);
    await store.remove('k');
    expect(await store.watch('k').toList(), isEmpty);
    expect(await store.revalidate('k', () async => 'fresh'), 'fresh');
  });

  test('currentUserId reads the stored user id', () async {
    SharedPreferences.setMockInitialValues({'current_user_id': 'user-9'});
    expect(await store.currentUserId(), 'user-9');
  });
}
