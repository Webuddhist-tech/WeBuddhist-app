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

  test('a pick made before the load survives it and keeps the other '
      'languages', () async {
    storage.values[StorageKeys.readerScriptPreference] =
        '{"pi":"si","bo":"phonetic"}';
    final n = notifier();

    n.setScript('pi', 'th');
    expect(container.read(readerScriptPreferenceProvider), {'pi': 'th'});
    expect(
      storage.values[StorageKeys.readerScriptPreference],
      '{"pi":"si","bo":"phonetic"}',
      reason: 'no write before the stored picks are known',
    );

    await n.loaded;

    const expected = {'pi': 'th', 'bo': 'phonetic'};
    expect(container.read(readerScriptPreferenceProvider), expected);
    expect(
      ReaderScriptPreferenceNotifier.decode(
        storage.values[StorageKeys.readerScriptPreference]! as String,
      ),
      expected,
    );
  });

  test('clearing a pick before the load clears the stored one', () async {
    storage.values[StorageKeys.readerScriptPreference] = '{"pi":"si"}';
    final n = notifier();

    n.setScript('pi', null);
    await n.loaded;

    expect(container.read(readerScriptPreferenceProvider), isEmpty);
    expect(storage.values[StorageKeys.readerScriptPreference], '{}');
  });
}
