import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_background_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_background.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_local_storage.dart';

Future<(ReaderBackgroundNotifier, FakeLocalStorage)> _load(
  Map<String, Object> stored,
) async {
  final storage = FakeLocalStorage()..values.addAll(stored);
  final notifier = ReaderBackgroundNotifier(localStorageService: storage);
  await notifier.ready;
  return (notifier, storage);
}

void main() {
  test('Rice Paper until a background is picked', () async {
    final (notifier, _) = await _load({});
    expect(notifier.state, ReaderBackground.ricePaper);
  });

  test('a picked background is saved and read back', () async {
    final (notifier, storage) = await _load({});
    await notifier.select(ReaderBackground.templeRed);
    expect(notifier.state, ReaderBackground.templeRed);

    final (reloaded, _) = await _load(Map.of(storage.values));
    expect(reloaded.state, ReaderBackground.templeRed);
  });

  test('an unknown saved name falls back to Rice Paper', () async {
    final (notifier, _) = await _load({StorageKeys.readerBackground: 'neon'});
    expect(notifier.state, ReaderBackground.ricePaper);
  });
}
