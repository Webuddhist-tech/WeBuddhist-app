import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_fonts_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_fonts.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_script.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_local_storage.dart';

Future<(ReaderFontsNotifier, FakeLocalStorage)> _load(
  Map<String, Object> stored,
) async {
  final storage = FakeLocalStorage()..values.addAll(stored);
  final notifier = ReaderFontsNotifier(localStorageService: storage);
  await notifier.ready;
  return (notifier, storage);
}

void main() {
  test('with nothing stored, every line is in its default', () async {
    final (notifier, _) = await _load({});
    expect(notifier.state, const ReaderFontChoices());
  });

  test('loads the saved picks', () async {
    final (notifier, _) = await _load({
      StorageKeys.readerFonts: '{"translation":{"latin":"literata"}}',
    });
    expect(
      notifier.state.fontFor(ReaderFontLine.translation, ReaderScript.latin),
      ReaderFonts.literata,
    );
  });

  test('a pick is saved, and picking the default again clears it', () async {
    final (notifier, storage) = await _load({});
    await notifier.choose(
      ReaderFontLine.original,
      ReaderScript.tibetan,
      ReaderFonts.jomolhari,
    );
    expect(
      storage.values[StorageKeys.readerFonts],
      '{"original":{"tibetan":"jomolhari"}}',
    );

    await notifier.choose(
      ReaderFontLine.original,
      ReaderScript.tibetan,
      ReaderFonts.babelStone,
    );
    expect(storage.values[StorageKeys.readerFonts], '{}');
    expect(notifier.state, const ReaderFontChoices());
  });
}
