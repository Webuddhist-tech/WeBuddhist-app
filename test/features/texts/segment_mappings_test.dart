import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Segment.parseMappedSegmentIds', () {
    test('absent mappings give an empty list', () {
      final segment = Segment.fromJson({'segment_id': 's', 'segment_number': 1});
      expect(segment.mappedSegmentIds, isEmpty);
      expect(Segment.parseMappedSegmentIds(null), isEmpty);
    });

    test('reads a language-to-id map', () {
      expect(
        Segment.parseMappedSegmentIds({'bo': 'bo-1', 'zh': 'zh-1'}),
        ['bo-1', 'zh-1'],
      );
    });

    test('reads a language-to-object map without picking up content', () {
      expect(
        Segment.parseMappedSegmentIds({
          'bo': {'id': 'bo-1', 'content': 'text that is not an id'},
          'zh': {'segment_id': 'zh-1', 'language': 'zh'},
        }),
        ['bo-1', 'zh-1'],
      );
    });

    test('reads a list of objects or ids', () {
      expect(
        Segment.parseMappedSegmentIds([
          {'segment_id': 'bo-1', 'language': 'bo'},
          'zh-1',
        ]),
        ['bo-1', 'zh-1'],
      );
    });

    test('drops duplicates and blanks', () {
      expect(Segment.parseMappedSegmentIds(['a', '', 'a']), ['a']);
    });

    test('round-trips through toJson', () {
      final segment = Segment.fromJson({
        'segment_id': 's',
        'segment_number': 1,
        'mappings': {'bo': 'bo-1'},
      });
      final again = Segment.fromJson(segment.toJson());
      expect(again.mappedSegmentIds, ['bo-1']);
    });
  });
}
