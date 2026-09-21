import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_item.dart';
import 'package:flutter_pecha/features/reader/domain/services/live_position_resolver.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_live_position.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_test/flutter_test.dart';

FlattenedContent _content() {
  final segments = [
    const Segment(segmentId: 'en-1', segmentNumber: 1, mappedSegmentIds: ['bo-1']),
    const Segment(segmentId: 'en-2', segmentNumber: 2, mappedSegmentIds: ['bo-2']),
    const Segment(segmentId: 'en-3', segmentNumber: 3),
  ];
  final items = [
    for (final segment in segments)
      FlattenedItem.segment(segment: segment, depth: 0, sectionId: 'sec'),
  ];
  return FlattenedContent(
    items: items,
    segmentIndexMap: {for (var i = 0; i < items.length; i++) items[i].segmentId!: i},
    totalSegments: items.length,
  );
}

RecitationLivePosition _at({required String text, required String segment}) =>
    RecitationLivePosition(
      eventId: 'ev',
      textId: text,
      segmentId: segment,
      revision: 1,
    );

void main() {
  group('FlattenedContent.resolveSegmentIndex', () {
    test('finds a segment by its own id', () {
      expect(_content().resolveSegmentIndex('en-2'), 1);
    });

    test('finds a segment by a mapped id from another language', () {
      expect(_content().resolveSegmentIndex('bo-2'), 1);
      expect(_content().findSegmentIndexByAlias('bo-1'), 0);
    });

    test('misses an id that is neither', () {
      expect(_content().resolveSegmentIndex('bo-3'), isNull);
    });
  });

  group('LivePositionResolver.textMatches', () {
    test('matches on any known id of the loaded text', () {
      expect(
        LivePositionResolver.textMatches(
          _at(text: 'version-7', segment: 'x'),
          loadedTextIds: ['navigated', null, 'version-7'],
        ),
        isTrue,
      );
    });

    test('matches when the segment resolves even if the ids differ', () {
      expect(
        LivePositionResolver.textMatches(
          _at(text: 'bo-text', segment: 'bo-2'),
          loadedTextIds: ['en-text'],
          content: _content(),
        ),
        isTrue,
      );
    });

    test('does not match a different text with an unknown segment', () {
      expect(
        LivePositionResolver.textMatches(
          _at(text: 'other', segment: 'other-9'),
          loadedTextIds: ['en-text'],
          content: _content(),
        ),
        isFalse,
      );
    });

    test('an empty loaded id never matches an empty position id', () {
      expect(
        LivePositionResolver.textMatches(
          _at(text: '', segment: 'zzz'),
          loadedTextIds: ['', null],
        ),
        isFalse,
      );
    });
  });
}
