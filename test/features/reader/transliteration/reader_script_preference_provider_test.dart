import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';

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

  ReaderScriptPreferenceNotifier notifier() =>
      container.read(readerScriptPreferenceProvider.notifier);

  test('starts empty and loads the persisted picks', () async {
    storage.values[StorageKeys.readerScriptPreference] = '{"pi":"si"}';
    expect(container.read(readerScriptPreferenceProvider), isEmpty);

    await notifier().loaded;

    expect(container.read(readerScriptPreferenceProvider), {'pi': 'si'});
    expect(notifier().scriptFor('PI'), 'si');
    expect(container.read(readerScriptForLanguageProvider('pi')), 'si');
    expect(container.read(readerScriptForLanguageProvider('bo')), isNull);
  });

  test('ignores unreadable persisted values', () async {
    storage.values[StorageKeys.readerScriptPreference] = 'not json';
    await notifier().loaded;
    expect(container.read(readerScriptPreferenceProvider), isEmpty);

    expect(ReaderScriptPreferenceNotifier.decode('{"pi":1,"bo":"x"}'), {
      'bo': 'x',
    });
  });

  test('persists a pick under the normalised language code', () async {
    await notifier().loaded;

    notifier().setScript(' Pi ', 'th');

    expect(container.read(readerScriptPreferenceProvider), {'pi': 'th'});
    expect(storage.values[StorageKeys.readerScriptPreference], '{"pi":"th"}');
  });

  test('clearing a pick removes it and skips no-op writes', () async {
    await notifier().loaded;
    notifier().setScript('pi', 'th');
    storage.values.clear();

    notifier().setScript('pi', 'th');
    expect(storage.values, isEmpty, reason: 'same pick again is a no-op');

    notifier().setScript('pi', null);
    expect(container.read(readerScriptPreferenceProvider), isEmpty);
    expect(storage.values[StorageKeys.readerScriptPreference], '{}');

    storage.values.clear();
    notifier().setScript('pi', null);
    expect(storage.values, isEmpty, reason: 'clearing twice is a no-op');
  });
}
