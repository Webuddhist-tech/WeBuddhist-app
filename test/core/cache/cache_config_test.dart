import 'package:flutter_pecha/core/cache/cache_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CacheKeys.textDetails', () {
    test('omits the size part when no size is given', () {
      final key = CacheKeys.textDetails(
        textId: 't1',
        versionId: 'v1',
        segmentId: 's1',
        direction: 'next',
        language: 'bo',
      );
      expect(key, 'text_details_t1_default_v1_s1_next_bo');
    });

    test('keeps the legacy key shape for default-sized fetches', () {
      // Entries cached before `size` existed must still resolve.
      final before = CacheKeys.textDetails(textId: 't1');
      expect(before, 'text_details_t1_default_default_start_next_default');
    });

    test('appends the size so a plan window does not collide with a page', () {
      final page = CacheKeys.textDetails(textId: 't1', segmentId: 's1');
      final window = CacheKeys.textDetails(
        textId: 't1',
        segmentId: 's1',
        size: 45,
      );
      expect(window, '${page}_size45');
      expect(window, isNot(page));
    });

    test('different sizes yield different keys', () {
      final a = CacheKeys.textDetails(textId: 't1', size: 30);
      final b = CacheKeys.textDetails(textId: 't1', size: 31);
      expect(a, isNot(b));
    });
  });
}
