import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/library/data/adapters/library_text_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../library_test_server.dart';

LibraryTestServer _server() => LibraryTestServer({
  '/v2/editions/E1':
      (_) => jsonBody({'id': 'E1', 'text_id': 'T1', 'source': 'https://src'}),
  '/v2/editions/E2': (_) => jsonBody({'id': 'E2', 'text_id': 'R'}),
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
    expect(uri.queryParameters['edition_id'], 'E1');
    expect(uri.queryParameters.containsKey('text_id'), isFalse);
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
    test('first page keeps the edition id and numbers verses', () async {
      final response = await _datasource(_server()).fetchTextDetails(
        textId: 'E1',
        direction: 'next',
      );

      expect(response.textDetail.id, 'E1');
      expect(response.textDetail.title, 'Title T1');
      expect(response.textDetail.language, 'en');
      expect(response.textDetail.sourceLink, 'https://src');
      expect(response.size, 20);
      expect(response.paginationDirection, 'next');
      expect(response.currentSegmentPosition, 1);
      expect(response.totalSegments, 3);

      final section = response.content.sections.single;
      expect(section.id, 'E1');
      expect(response.content.textId, 'T1');
      expect(section.segments.map((s) => s.segmentId), ['s1', 's2', 's3']);
      expect(section.segments.map((s) => s.segmentNumber), [1, 2, 3]);
      expect(section.segments.map((s) => s.reference), ['1', '2', '3']);
      expect(section.segments.map((s) => s.displayNumber), ['1', '2', '3']);
      expect(section.segments.first.content, 'a&lt;b');
      expect(section.segments.first.translation, isNull);
    });

    test('pages after an anchor and before it', () async {
      final ds = _datasource(_server());

      final next = await ds.fetchTextDetails(
        textId: 'E1',
        segmentId: 's3',
        direction: 'next',
        size: 1,
      );
      expect(next.content.sections.single.segments.single.segmentId, 's3');
      expect(next.currentSegmentPosition, 3);

      final previous = await ds.fetchTextDetails(
        textId: 'E1',
        segmentId: 's3',
        direction: 'previous',
        size: 1,
      );
      expect(previous.content.sections.single.segments.single.segmentId, 's2');
      expect(previous.currentSegmentPosition, 2);
    });

    test('a version id loads the companion edition into translation content', () async {
      final response = await _datasource(_server()).fetchTextDetails(
        textId: 'E1',
        versionId: 'E2',
        direction: 'next',
      );

      final segments = response.content.sections.single.segments;
      expect(segments.map((s) => s.segmentId), ['b1', 'b2', 'b3']);
      expect(segments.map((s) => s.segmentNumber), [1, 2, 3]);
      expect(segments.first.content, isNull);
      expect(segments.first.translation?.content, 'ABC');
      expect(segments.first.translation?.language, 'bo');
      expect(segments.first.translation?.textId, 'E2');
      expect(response.textDetail.id, 'E2');
    });

    test('a companion anchored on a primary segment starts at that verse', () async {
      final response = await _datasource(_server()).fetchTextDetails(
        textId: 'E1',
        versionId: 'E2',
        segmentId: 's2',
        direction: 'next',
        size: 1,
      );

      final segments = response.content.sections.single.segments;
      expect(segments.map((s) => s.segmentId), ['b2']);
      expect(segments.single.segmentNumber, 2);
      expect(segments.single.translation?.content, 'DEF');
      expect(response.currentSegmentPosition, 2);
    });

    test('a text id still resolves to its first edition', () async {
      final response = await _datasource(_server()).fetchTextDetails(
        textId: 'T1',
      );

      expect(response.textDetail.id, 'T1');
      expect(response.content.sections.single.id, 'E1');
      expect(response.totalSegments, 3);
    });

    test('an unknown id and a text without an edition are not found', () async {
      final ds = _datasource(_server());
      expect(
        () => ds.fetchTextDetails(textId: 'NOPE'),
        throwsA(isA<NotFoundException>()),
      );
      expect(
        () => ds.fetchTextDetails(textId: 'NOED'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('LibraryTextRemoteDatasource table of contents', () {
    LibraryTestServer withToc(ResponseBody Function(Uri uri) toc) =>
        LibraryTestServer({
          ..._server().routes,
          '/v2/editions/E1/table-of-contents': toc,
        });

    test('nests the page under the headings that span it', () async {
      final server = withToc(
        (_) => jsonBody([
          {
            'id': 'toc',
            'edition_id': 'E1',
            'text_id': 'T1',
            'sections': [
              {
                'id': 'top',
                'title': {'en': 'Top'},
                'span': {'start': 0, 'end': 9},
                'subsections': [
                  {
                    'id': 'one',
                    'title': {'en': 'One'},
                    'span': {'start': 0, 'end': 3},
                  },
                  {
                    'id': 'two',
                    'title': {'en': 'Two'},
                    'span': {'start': 3, 'end': 9},
                  },
                ],
              },
            ],
          },
        ]),
      );

      final ds = _datasource(server);
      final response = await ds.fetchTextDetails(textId: 'E1');

      final top = response.content.sections.single;
      expect(top.id, 'top');
      expect(top.title, 'Top');
      expect(top.segments, isEmpty);
      final children = top.sections!;
      expect(children.map((s) => s.title), ['One', 'Two']);
      expect(children[0].segments.map((s) => s.segmentId), ['s1']);
      expect(children[1].segments.map((s) => s.segmentId), ['s2', 's3']);
      expect(children[1].segments.first.content, '&amp;cd');

      // The reader cache stores pages as JSON; headings must survive it.
      final cached = ReaderResponse.fromJson(response.toJson());
      final cachedTop = cached.content.sections.single;
      expect(cachedTop.title, 'Top');
      expect(cachedTop.sections!.map((s) => s.title), ['One', 'Two']);
      expect(cachedTop.sections![1].parentId, 'top');

      final page = await ds.fetchTextDetails(
        textId: 'E1',
        segmentId: 's3',
        size: 1,
      );
      expect(page.content.sections.single.sections!.single.id, 'two');
      expect(server.count('/v2/editions/E1/table-of-contents'), 1);
    });

    test('the text still opens when the table fails', () async {
      final server = withToc(
        (_) => jsonBody({'detail': 'boom'}, statusCode: 500),
      );

      final response = await _datasource(server).fetchTextDetails(
        textId: 'E1',
      );

      final section = response.content.sections.single;
      expect(section.id, 'E1');
      expect(section.title, isNull);
      expect(section.segments.map((s) => s.segmentId), ['s1', 's2', 's3']);
    });
  });

  test('multilingualSearch searches the edition and keys hits by it', () async {
    final response = await _datasource(_server()).multilingualSearch(
      query: 'def',
      textId: 'E1',
    );

    expect(response.query, 'def');
    final source = response.sources.single;
    expect(source.text.textId, 'E1');
    expect(source.text.title, 'Title T1');
    expect(source.segmentMatches.map((m) => m.segmentId), ['s2', 's3']);
    expect(source.segmentMatches.first.content, 'def');
    expect(source.segmentMatches.first.relevanceScore, 21.7);
  });
}
