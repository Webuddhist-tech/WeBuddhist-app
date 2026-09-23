import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/library/data/adapters/library_text_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../library_test_server.dart';

LibraryTestServer _server() => LibraryTestServer({
  '/v2/texts/T1':
      (_) => jsonBody(
        textJson('T1', language: 'en', translationOf: 'R', editions: ['E1']),
      ),
  '/v2/texts/R':
      (_) => jsonBody(textJson('R', editions: ['E2'], translations: ['T1'])),
  '/v2/texts/NOED': (_) => jsonBody(textJson('NOED', language: 'en')),
  '/v2/editions/E1/segmentation/segments':
      (_) => jsonBody(pageJson(threeVerses('s'))),
  '/v2/editions/E2/segmentation/segments':
      (_) => jsonBody(pageJson(threeVerses('b'))),
  '/v2/editions/E1/content': (uri) {
    final start = int.parse(uri.queryParameters['span_start']!);
    final end = int.parse(uri.queryParameters['span_end']!);
    return jsonBody('a<b&cdefghi'.substring(0, 9).substring(start, end));
  },
  '/v2/editions/E2/content': (uri) {
    final start = int.parse(uri.queryParameters['span_start']!);
    final end = int.parse(uri.queryParameters['span_end']!);
    return jsonBody('ABCDEFGHI'.substring(start, end));
  },
  '/v2/content-search': (uri) {
    expect(uri.queryParameters['text_id'], 'T1');
    expect(uri.queryParameters['search_type'], 'exact');
    return jsonBody([
      {
        'text_id': 'T1',
        'edition_id': 'E1',
        'segment_ids': ['s2'],
        'context': 'def',
        'score': 21.7,
      },
      {
        'text_id': 'T1',
        'edition_id': 'E1',
        'segment_ids': ['s2', 's3'],
        'context': 'defghi',
        'score': 3,
      },
    ]);
  },
});

LibraryTextRemoteDatasource _datasource(LibraryTestServer server) {
  return LibraryTextRemoteDatasource(library: server.repository());
}

void main() {
  group('LibraryTextRemoteDatasource.fetchTextDetails', () {
    test('first page keeps the path id and numbers verses', () async {
      final response = await _datasource(_server()).fetchTextDetails(
        textId: 'T1',
        direction: 'next',
      );

      expect(response.textDetail.id, 'T1');
      expect(response.textDetail.title, 'Title T1');
      expect(response.textDetail.language, 'en');
      expect(response.size, 20);
      expect(response.paginationDirection, 'next');
      expect(response.currentSegmentPosition, 1);
      expect(response.totalSegments, 3);

      final section = response.content.sections.single;
      expect(section.id, 'E1');
      expect(section.segments.map((s) => s.segmentId), ['s1', 's2', 's3']);
      expect(section.segments.map((s) => s.segmentNumber), [1, 2, 3]);
      expect(section.segments.first.content, 'a&lt;b');
      expect(section.segments.first.translation, isNull);
    });

    test('pages after an anchor and before it', () async {
      final ds = _datasource(_server());

      final next = await ds.fetchTextDetails(
        textId: 'T1',
        segmentId: 's3',
        direction: 'next',
        size: 1,
      );
      expect(next.content.sections.single.segments.single.segmentId, 's3');
      expect(next.currentSegmentPosition, 3);

      final previous = await ds.fetchTextDetails(
        textId: 'T1',
        segmentId: 's3',
        direction: 'previous',
        size: 1,
      );
      expect(previous.content.sections.single.segments.single.segmentId, 's2');
      expect(previous.currentSegmentPosition, 2);
    });

    test('a version id loads the companion into translation content', () async {
      final response = await _datasource(_server()).fetchTextDetails(
        textId: 'T1',
        versionId: 'R',
        direction: 'next',
      );

      final segments = response.content.sections.single.segments;
      expect(segments.map((s) => s.segmentId), ['b1', 'b2', 'b3']);
      expect(segments.map((s) => s.segmentNumber), [1, 2, 3]);
      expect(segments.first.content, isNull);
      expect(segments.first.translation?.content, 'ABC');
      expect(segments.first.translation?.language, 'bo');
      expect(segments.first.translation?.textId, 'R');
      expect(response.textDetail.id, 'R');
    });

    test('a text without an edition is not found', () async {
      expect(
        () => _datasource(_server()).fetchTextDetails(textId: 'NOED'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  test('multilingualSearch groups hits per text and dedupes segments', () async {
    final response = await _datasource(_server()).multilingualSearch(
      query: 'def',
      textId: 'T1',
    );

    expect(response.query, 'def');
    final source = response.sources.single;
    expect(source.text.textId, 'T1');
    expect(source.text.title, 'Title T1');
    expect(source.segmentMatches.map((m) => m.segmentId), ['s2', 's3']);
    expect(source.segmentMatches.first.content, 'def');
    expect(source.segmentMatches.first.relevanceScore, 21.7);
  });
}
