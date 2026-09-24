import 'package:flutter_pecha/features/reader/presentation/utils/reader_initial_layout_applier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
