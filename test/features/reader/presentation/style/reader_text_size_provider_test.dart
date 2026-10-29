import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_text_size_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_text_size.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_local_storage.dart';

Future<(ReaderTextSizeNotifier, FakeLocalStorage)> _load(
  Map<String, Object> stored,
) async {
  final storage = FakeLocalStorage()..values.addAll(stored);
  final notifier = ReaderTextSizeNotifier(localStorageService: storage);
  await notifier.ready;
  return (notifier, storage);
}

void main() {
  group('first load', () {
    test('with nothing stored, both lines are at step 3', () async {
      final (notifier, _) = await _load({});
      expect(notifier.state, const ReaderTextSize());
    });

    test('the old default 18 becomes step 3 and is saved', () async {
      final (notifier, storage) = await _load({StorageKeys.fontSize: 18.0});
      expect(notifier.state.originalStep, 3);
      expect(notifier.state.translationStep, 3);
      expect(storage.values[StorageKeys.readerOriginalStep], 3);
      expect(storage.values[StorageKeys.readerTranslationStep], 3);
    });

    test('any other old size becomes the nearest step', () async {
      final expected = {12.0: 1, 14.0: 1, 22.0: 4, 28.0: 6, 36.0: 7, 44.0: 7};
      for (final MapEntry(key: size, value: step) in expected.entries) {
        final (notifier, _) = await _load({StorageKeys.fontSize: size});
        expect(notifier.state.originalStep, step, reason: 'font size $size');
      }
    });

    test('saved steps win over the old size', () async {
      final (notifier, _) = await _load({
        StorageKeys.fontSize: 44.0,
        StorageKeys.readerOriginalStep: 2,
        StorageKeys.readerTranslationStep: 5,
        StorageKeys.readerSpacing: 'relaxed',
      });
      expect(
        notifier.state,
        const ReaderTextSize(
          originalStep: 2,
          translationStep: 5,
          spacing: ReaderSpacing.relaxed,
        ),
      );
    });

    test('an unknown spacing name is Normal', () async {
      final (notifier, _) = await _load({StorageKeys.readerSpacing: 'huge'});
      expect(notifier.state.spacing, ReaderSpacing.normal);
    });
  });

  group('changes', () {
    test('stepping moves both lines and is saved', () async {
      final (notifier, storage) = await _load({});
      await notifier.stepBoth(1);
      expect(notifier.state.originalStep, 4);
      expect(notifier.state.translationStep, 4);
      expect(storage.values[StorageKeys.readerOriginalStep], 4);
    });

    test('steps stop at 1 and 7', () async {
      final (notifier, _) = await _load({
        StorageKeys.readerOriginalStep: 7,
        StorageKeys.readerTranslationStep: 1,
      });
      await notifier.stepBoth(1);
      expect(notifier.state.originalStep, 7);
      expect(notifier.state.translationStep, 2);
      await notifier.stepBoth(-1);
      await notifier.stepBoth(-1);
      expect(notifier.state.translationStep, 1);
    });

    test('each line and the spacing can be set on its own', () async {
      final (notifier, storage) = await _load({});
      await notifier.setOriginalStep(6);
      await notifier.setTranslationStep(2);
      await notifier.setSpacing(ReaderSpacing.compact);
      expect(
        notifier.state,
        const ReaderTextSize(
          originalStep: 6,
          translationStep: 2,
          spacing: ReaderSpacing.compact,
        ),
      );
      expect(storage.values[StorageKeys.readerSpacing], 'compact');
    });
  });
}
