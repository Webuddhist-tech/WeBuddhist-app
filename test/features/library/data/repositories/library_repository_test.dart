import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/library/data/models/library_reader_models.dart';
import 'package:flutter_pecha/features/library/data/models/library_segment.dart';
import 'package:flutter_pecha/features/library/data/repositories/library_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../library_test_server.dart';

LibrarySegment _segment(String id, String reference) => LibrarySegment(
  id: id,
  type: 'verse',
  reference: reference,
  lines: const [LibraryLineSpan(start: 0, end: 1)],
);

LibrarySegment _relatedSegment(List<List<int>> lines) => LibrarySegment(
  id: 'r1',
  type: 'verse',
  reference: '1',
  lines: [for (final l in lines) LibraryLineSpan(start: l[0], end: l[1])],
  editionId: 'e1',
  textId: 't1',
);

void main() {
  group('LibraryRepository.getTableOfContents', () {
    test('returns the first non-empty table once per edition', () async {
      final server = LibraryTestServer({
        '/v2/editions/e1/table-of-contents':
            (_) => jsonBody([
              {'id': 'empty', 'edition_id': 'e1', 'sections': []},
              {
                'id': 'toc',
                'edition_id': 'e1',
                'sections': [
                  {
                    'id': 'h1',
                    'title': {'en': 'One'},
                    'span': {'start': 0, 'end': 9},
                  },
                ],
              },
            ]),
      });
      final repository = server.repository();

      final toc = await repository.getTableOfContents('e1');
      await repository.getTableOfContents('e1');

      expect(toc.single.id, 'h1');
      expect(server.count('/v2/editions/e1/table-of-contents'), 1);
    });

    test('an empty list or a missing table is no headings', () async {
      final server = LibraryTestServer({
        '/v2/editions/e1/table-of-contents': (_) => jsonBody([]),
      });
      final repository = server.repository();

      expect(await repository.getTableOfContents('e1'), isEmpty);
      expect(await repository.getTableOfContents('gone'), isEmpty);
    });
  });

  group('LibraryRepository.getEditionSegments', () {
    test('walks every page and drops segments without lines', () async {
      final server = LibraryTestServer({
        '/v2/editions/e1/segmentation/segments': (uri) {
          final offset = int.parse(uri.queryParameters['offset']!);
          expect(uri.queryParameters['limit'], '2');
          if (offset == 0) {
            return jsonBody(
              pageJson([
                segmentJson('s1', '1', [
                  [0, 3],
                ]),
                segmentJson('empty', null, const []),
              ], hasMore: true, limit: 2),
            );
          }
          expect(offset, 2);
          return jsonBody(
            pageJson([
              segmentJson('s2', '2', [
                [3, 6],
              ]),
            ], offset: 2, limit: 2),
          );
        },
      });
      final repository = server.repository(segmentPageSize: 2);

      final segments = await repository.getEditionSegments('e1');
      await repository.getEditionSegments('e1');

      expect(segments.map((s) => s.id), ['s1', 's2']);
      expect(server.count('/v2/editions/e1/segmentation/segments'), 2);
    });

    test('stops when a page repeats instead of advancing', () async {
      final server = LibraryTestServer({
        '/v2/editions/e1/segmentation/segments':
            (_) => jsonBody(pageJson(threeVerses('s'), hasMore: true)),
      });

      final segments = await server.repository().getEditionSegments('e1');

      expect(segments.map((s) => s.id), ['s1', 's2', 's3']);
      expect(server.count('/v2/editions/e1/segmentation/segments'), 2);
    });

    test('stops after the page limit', () async {
      final server = LibraryTestServer({
        '/v2/editions/e1/segmentation/segments': (uri) {
          final offset = uri.queryParameters['offset'];
          return jsonBody(
            pageJson([
              segmentJson('s$offset', null, [
                [0, 1],
              ]),
            ], hasMore: true),
          );
        },
      });

      final segments = await server
          .repository(maxPages: 3)
          .getEditionSegments('e1');

      expect(segments, hasLength(3));
      expect(server.count('/v2/editions/e1/segmentation/segments'), 3);
    });
  });

  group('LibraryRepository.loadWindow', () {
    LibraryTestServer server() => LibraryTestServer({
      '/v2/editions/e1/segmentation/segments':
          (_) => jsonBody(pageJson(threeVerses('s'))),
      '/v2/editions/e1/content': (uri) {
        final start = int.parse(uri.queryParameters['span_start']!);
        final end = int.parse(uri.queryParameters['span_end']!);
        return jsonBody('abcdefghi'.substring(start, end));
      },
    });

    test('next without an anchor is the first page', () async {
      final s = server();
      final window = await s.repository().loadWindow(
        editionId: 'e1',
        direction: 'next',
        size: 2,
      );

      expect(window.segments.map((x) => x.id), ['s1', 's2']);
      expect(window.segments.map((x) => x.number), [1, 2]);
      expect(window.segments.map((x) => x.lines.single), ['abc', 'def']);
      expect(window.currentPosition, 1);
      expect(window.totalSegments, 3);
      final content = s.requests.singleWhere(
        (u) => u.path == '/v2/editions/e1/content',
      );
      expect(content.queryParameters, {'span_start': '0', 'span_end': '6'});
    });

    test('next starts at the anchor and reports its position', () async {
      final window = await server().repository().loadWindow(
        editionId: 'e1',
        anchorSegmentId: 's2',
        direction: 'next',
        size: 20,
      );

      expect(window.segments.map((x) => x.id), ['s2', 's3']);
      expect(window.segments.map((x) => x.lines.single), ['def', 'ghi']);
      expect(window.currentPosition, 2);
    });

    test('previous ends before the anchor and reports the first position', () async {
      final window = await server().repository().loadWindow(
        editionId: 'e1',
        anchorSegmentId: 's3',
        direction: 'previous',
        size: 1,
      );

      expect(window.segments.map((x) => x.id), ['s2']);
      expect(window.currentPosition, 2);
    });

    test('previous of the first segment is empty and fetches no content', () async {
      final s = server();
      final window = await s.repository().loadWindow(
        editionId: 'e1',
        anchorSegmentId: 's1',
        direction: 'previous',
        size: 20,
      );

      expect(window.segments, isEmpty);
      expect(window.currentPosition, 1);
      expect(s.count('/v2/editions/e1/content'), 0);
    });

    test('an unknown anchor falls back to the first page', () async {
      final window = await server().repository().loadWindow(
        editionId: 'e1',
        anchorSegmentId: 'nope',
        direction: 'next',
        size: 20,
      );

      expect(window.segments.map((x) => x.id), ['s1', 's2', 's3']);
      expect(window.currentPosition, 1);
    });

    test('an anchor from another edition is mapped by verse number', () async {
      final s = LibraryTestServer({
        '/v2/editions/e1/segmentation/segments':
            (_) => jsonBody(pageJson(threeVerses('s'))),
        '/v2/editions/e2/segmentation/segments':
            (_) => jsonBody(pageJson(threeVerses('b'))),
        '/v2/editions/e2/content': (_) => jsonBody('ABCDEFGHI'),
      });

      final window = await s.repository().loadWindow(
        editionId: 'e2',
        anchorSegmentId: 's2',
        anchorEditionId: 'e1',
        direction: 'next',
        size: 20,
      );

      expect(window.segments.map((x) => x.id), ['b2', 'b3']);
      expect(window.currentPosition, 2);
    });

    test('the page that reaches the end reports it', () async {
      final repository = server().repository();
      final first = await repository.loadWindow(
        editionId: 'e1',
        direction: 'next',
        size: 2,
      );
      final last = await repository.loadWindow(
        editionId: 'e1',
        anchorSegmentId: 's2',
        direction: 'next',
        size: 2,
      );

      expect(first.lastPosition, 2);
      expect(last.segments.map((x) => x.id), ['s2', 's3']);
      expect(last.currentPosition, 2);
      expect(last.lastPosition, last.totalSegments);
    });
  });

  group('LibraryRepository.alignSegment', () {
    LibraryTestServer server() => LibraryTestServer({
      '/v2/editions/bo1': (_) => jsonBody({'id': 'bo1', 'text_id': 'tbo'}),
      '/v2/editions/en1': (_) => jsonBody({'id': 'en1', 'text_id': 'ten'}),
      '/v2/editions/x1': (_) => jsonBody({'id': 'x1', 'text_id': 'tx'}),
      '/v2/texts/tbo':
          (_) => jsonBody(
            textJson('tbo', editions: ['bo1'], translations: ['ten']),
          ),
      '/v2/texts/ten':
          (_) => jsonBody(
            textJson(
              'ten',
              language: 'en',
              translationOf: 'tbo',
              editions: ['en1'],
            ),
          ),
      '/v2/texts/tx': (_) => jsonBody(textJson('tx', editions: ['x1'])),
      '/v2/editions/bo1/segmentation/segments':
          (_) => jsonBody(pageJson(threeVerses('bo'))),
      '/v2/editions/en1/segmentation/segments':
          (_) => jsonBody(pageJson(threeVerses('en'))),
      '/v2/editions/x1/segmentation/segments':
          (_) => jsonBody(pageJson(threeVerses('x'))),
    });

    test('maps a verse to another language of the same text', () async {
      final aligned = await server().repository().alignSegment(
        segmentId: 'bo2',
        sourceId: 'bo1',
        targetId: 'en1',
      );

      expect(aligned, 'en2');
    });

    test('an unrelated text never matches by verse number', () async {
      final aligned = await server().repository().alignSegment(
        segmentId: 'x2',
        sourceId: 'x1',
        targetId: 'en1',
      );

      expect(aligned, isNull);
    });

    test('the same edition keeps the id without fetching segments', () async {
      final s = server();
      final aligned = await s.repository().alignSegment(
        segmentId: 'bo2',
        sourceId: 'bo1',
        targetId: 'bo1',
      );

      expect(aligned, 'bo2');
      expect(s.count('/v2/editions/bo1/segmentation/segments'), 0);
    });
  });

  group('LibraryRepository.segmentNumbers', () {
    test('uses references when they are unique positive integers', () {
      final numbers = LibraryRepository.segmentNumbers([
        _segment('a', '3'),
        _segment('b', '7'),
      ]);
      expect(numbers, [3, 7]);
    });

    test('falls back to positions for duplicate or missing references', () {
      expect(
        LibraryRepository.segmentNumbers([
          _segment('a', '1'),
          _segment('b', '1'),
        ]),
        [1, 2],
      );
      expect(
        LibraryRepository.segmentNumbers([_segment('a', ''), _segment('b', '2')]),
        [1, 2],
      );
    });
  });

  group('LibraryRepository.getTextFamily', () {
    test('lists the root first, then its translations, fetching each once', () async {
      final server = LibraryTestServer({
        '/v2/texts/root':
            (_) => jsonBody(textJson('root', translations: ['t1', 't2'])),
        '/v2/texts/t1':
            (_) => jsonBody(textJson('t1', language: 'en', translationOf: 'root')),
        '/v2/texts/t2':
            (_) => jsonBody(textJson('t2', language: 'ne', translationOf: 'root')),
      });
      final repository = server.repository();

      final fromTranslation = await repository.getTextFamily('t2');
      final fromRoot = await repository.getTextFamily('root');

      expect(fromTranslation.map((t) => t.id), ['root', 't1', 't2']);
      expect(fromRoot.map((t) => t.id), ['root', 't1', 't2']);
      expect(server.count('/v2/texts/root'), 1);
      expect(server.count('/v2/texts/t1'), 1);
      expect(server.count('/v2/texts/t2'), 1);
    });
  });

  group('LibraryRepository.resolveEdition', () {
    LibraryTestServer server() => LibraryTestServer({
      '/v2/editions/E1': (_) => jsonBody({'id': 'E1', 'text_id': 'T1'}),
      '/v2/texts/T1': (_) => jsonBody(textJson('T1', editions: ['E1'])),
      '/v2/texts/NOED': (_) => jsonBody(textJson('NOED')),
    });

    test('an edition id resolves directly and is memoized', () async {
      final s = server();
      final repository = s.repository();

      final first = await repository.resolveEdition('E1');
      final second = await repository.resolveEdition('E1');

      expect(first.textId, 'T1');
      expect(second.id, 'E1');
      expect(s.count('/v2/editions/E1'), 1);
    });

    test('a text id falls back to its first edition', () async {
      final s = server();

      final edition = await s.repository().resolveEdition('T1');

      expect(edition.id, 'E1');
      expect(s.count('/v2/editions/T1'), 1);
      expect(s.count('/v2/texts/T1'), 1);
    });

    test('unknown ids and edition-less texts are not found', () async {
      final repository = server().repository();

      expect(
        () => repository.resolveEdition('NOPE'),
        throwsA(isA<NotFoundException>()),
      );
      expect(
        () => repository.resolveEdition('NOED'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('LibraryRepository.loadSegmentResources', () {
    test('splits by text kind, fetches each text once, memoizes', () async {
      final server = LibraryTestServer({
        '/v2/segments/s1/related':
            (_) => jsonBody(
              pageJson([
                segmentJson('r1', '1', [[0, 5]], textId: 'root', editionId: 'e-root'),
                segmentJson('r2', '1', [[0, 5]], textId: 'comm', editionId: 'e-comm'),
                segmentJson('r3', '1', [[0, 5]], textId: 'root', editionId: 'e-root2'),
                segmentJson('r4', '1', [[0, 5]], textId: 'trans', editionId: 'e-trans'),
                segmentJson('r5', '1', [[0, 5]]),
              ], limit: 20),
            ),
        '/v2/texts/root': (_) => jsonBody(textJson('root')),
        '/v2/texts/comm':
            (_) => jsonBody(textJson('comm', commentaryOf: 'root', language: 'en')),
        '/v2/texts/trans':
            (_) => jsonBody(textJson('trans', translationOf: 'root', language: 'en')),
      });
      final repository = server.repository();

      final resources = await repository.loadSegmentResources('s1');
      await repository.loadSegmentResources('s1');

      expect(resources.versions.map((r) => r.segmentId), ['r1', 'r3', 'r4']);
      expect(resources.commentaries.map((r) => r.segmentId), ['r2']);
      expect(
        resources.commentaries.single.kind,
        LibraryResourceKind.commentary,
      );
      expect(resources.versions.first.title, 'Title root');
      expect(resources.versions.first.language, 'bo');
      expect(server.count('/v2/segments/s1/related'), 1);
      expect(server.count('/v2/texts/root'), 1);
    });
  });

  group('LibraryRepository.loadResourceContent', () {
    test('slices segment content and attaches the edition source', () async {
      final server = LibraryTestServer({
        '/v2/segments/r1/content': (_) => jsonBody('abcdef'),
        '/v2/editions/e1':
            (_) => jsonBody({
              'id': 'e1',
              'text_id': 't1',
              'type': 'critical',
              'source': 'https://dharmamitra.org',
            }),
      });

      final content = await server.repository().loadResourceContent(
        _relatedSegment([
          [0, 3],
          [3, 6],
        ]),
      );

      expect(content.lines, ['abc', 'def']);
      expect(content.source, 'https://dharmamitra.org');
    });

    test('reads offsets relative to the first line', () async {
      final server = LibraryTestServer({
        '/v2/segments/r1/content': (_) => jsonBody('abcdef'),
        '/v2/editions/e1': (_) => jsonBody({'id': 'e1', 'text_id': 't1'}),
      });

      final content = await server.repository().loadResourceContent(
        _relatedSegment([
          [40, 43],
          [43, 46],
        ]),
      );

      expect(content.lines, ['abc', 'def']);
    });

    test('keeps the content when the edition lookup fails', () async {
      final server = LibraryTestServer({
        '/v2/segments/r1/content': (_) => jsonBody('abcdef'),
        '/v2/editions/e1':
            (_) => jsonBody({'detail': 'boom'}, statusCode: 500),
      });

      final content = await server.repository().loadResourceContent(
        _relatedSegment([
          [0, 3],
          [3, 6],
        ]),
      );

      expect(content.lines, ['abc', 'def']);
      expect(content.source, isNull);
    });
  });
}
