import 'dart:convert';

import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary.dart';
import 'package:flutter_test/flutter_test.dart';

/// The screen cache stores a commentary as JSON and reads it back, fresh
/// responses included, so nothing may be lost on the way.
void main() {
  test('translations survive a trip through the screen cache', () {
    final commentary = SegmentCommentary(
      textId: 'bo-commentary',
      title: 'Tibetan commentary',
      segments: [MappedSegmentDTO(segmentId: 's1', content: 'བོད')],
      language: 'bo',
      count: 1,
      translations: [
        SegmentCommentary(
          textId: 'en-commentary',
          title: 'English translation',
          segments: [MappedSegmentDTO(segmentId: 's2', content: 'English')],
          language: 'en',
          count: 1,
        ),
      ],
    );

    final restored = SegmentCommentary.fromJson(
      jsonDecode(jsonEncode(commentary.toJson())) as Map<String, dynamic>,
    );

    expect(restored.translations, hasLength(1));
    expect(restored.translations.single.textId, 'en-commentary');
    expect(restored.translations.single.segments.single.content, 'English');
  });

  test('a response without translations reads as none', () {
    final restored = SegmentCommentary.fromJson({
      'text_id': 't',
      'title': 'Commentary',
      'language': 'bo',
      'count': 0,
    });

    expect(restored.translations, isEmpty);
  });
}
