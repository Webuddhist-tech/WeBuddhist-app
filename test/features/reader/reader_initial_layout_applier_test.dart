import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_initial_layout_applier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('readerInitialLayoutStep', () {
    const loaded = AsyncData<List<ReaderLanguageOption>>([]);
    const loading = AsyncLoading<List<ReaderLanguageOption>>();
    const failed = AsyncError<List<ReaderLanguageOption>>(
      'offline',
      StackTrace.empty,
    );

    test('waits until the text and its list of translations are known', () {
      expect(
        readerInitialLayoutStep(applied: false, hasText: false, languages: loaded),
        ReaderInitialLayoutStep.wait,
      );
      expect(
        readerInitialLayoutStep(applied: false, hasText: true, languages: loading),
        ReaderInitialLayoutStep.wait,
      );
    });

    test('applies once both are known, and only once', () {
      expect(
        readerInitialLayoutStep(applied: false, hasText: true, languages: loaded),
        ReaderInitialLayoutStep.apply,
      );
      expect(
        readerInitialLayoutStep(applied: true, hasText: true, languages: loaded),
        ReaderInitialLayoutStep.wait,
      );
    });

    test('only seeds while the list failed to load, so a retry can still apply', () {
      expect(
        readerInitialLayoutStep(applied: false, hasText: true, languages: failed),
        ReaderInitialLayoutStep.seedOnly,
      );
      expect(
        readerInitialLayoutStep(applied: false, hasText: false, languages: failed),
        ReaderInitialLayoutStep.wait,
      );
    });
  });

  group('translationCandidates', () {
    test('remembered pick first, then the seeded default, then the fallback', () {
      expect(
        translationCandidates(remembered: 'zh', seeded: 'hi', fallback: 'en'),
        ['zh', 'hi', 'en'],
      );
    });

    test('drops blanks and repeats, and normalises codes', () {
      expect(
        translationCandidates(remembered: ' EN', seeded: 'en', fallback: 'en '),
        ['en'],
      );
      expect(
        translationCandidates(remembered: '', seeded: null, fallback: 'hi'),
        ['hi'],
      );
    });

    test('a blank fallback yields nothing to try', () {
      expect(translationCandidates(fallback: ' '), isEmpty);
    });
  });
}
