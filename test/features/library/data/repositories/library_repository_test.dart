import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:dio/dio.dart';
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
              pageJson(
                [
                  segmentJson('s1', '1', [
                    [0, 3],
                  ]),
                  segmentJson('empty', null, const []),
                ],
                hasMore: true,
                limit: 2,
              ),
            );
          }
          expect(offset, 2);
          return jsonBody(
            pageJson(
              [
                segmentJson('s2', '2', [
                  [3, 6],
                ]),
              ],
              offset: 2,
              limit: 2,
            ),
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

    test(
      'previous ends before the anchor and reports the first position',
      () async {
        final window = await server().repository().loadWindow(
          editionId: 'e1',
          anchorSegmentId: 's3',
          direction: 'previous',
          size: 1,
        );

        expect(window.segments.map((x) => x.id), ['s2']);
        expect(window.currentPosition, 2);
      },
    );

    test(
      'previous of the first segment is empty and fetches no content',
      () async {
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
      },
    );

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

    test(
      'an anchor of unknown origin is placed from its own edition',
      () async {
        final s = LibraryTestServer({
          '/v2/editions/e1/segmentation/segments':
              (_) => jsonBody(pageJson(threeVerses('s'))),
          '/v2/editions/e2/segmentation/segments':
              (_) => jsonBody(pageJson(threeVerses('b'))),
          '/v2/editions/e2/content': (_) => jsonBody('ABCDEFGHI'),
          '/v2/segments/s3':
              (_) => jsonBody(
                segmentJson(
                  's3',
                  '3',
                  [
                    [6, 9],
                  ],
                  textId: 't1',
                  editionId: 'e1',
                ),
              ),
        });

        // A bookmark on a translation whose root is now the primary.
        final window = await s.repository().loadWindow(
          editionId: 'e2',
          anchorSegmentId: 's3',
          direction: 'next',
          size: 20,
        );

        expect(window.segments.map((x) => x.id), ['b3']);
        expect(window.currentPosition, 3);
        expect(s.count('/v2/segments/s3'), 1);
      },
    );

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
        LibraryRepository.segmentNumbers([
          _segment('a', ''),
          _segment('b', '2'),
        ]),
        [1, 2],
      );
    });
  });

  group('LibraryRepository.getTextFamily', () {
    test(
      'lists the root first, then its translations, fetching each once',
      () async {
        final server = LibraryTestServer({
          '/v2/texts/root':
              (_) => jsonBody(textJson('root', translations: ['t1', 't2'])),
          '/v2/texts/t1':
              (_) => jsonBody(
                textJson('t1', language: 'en', translationOf: 'root'),
              ),
          '/v2/texts/t2':
              (_) => jsonBody(
                textJson('t2', language: 'ne', translationOf: 'root'),
              ),
        });
        final repository = server.repository();

        final fromTranslation = await repository.getTextFamily('t2');
        final fromRoot = await repository.getTextFamily('root');

        expect(fromTranslation.map((t) => t.id), ['root', 't1', 't2']);
        expect(fromRoot.map((t) => t.id), ['root', 't1', 't2']);
        expect(server.count('/v2/texts/root'), 1);
        expect(server.count('/v2/texts/t1'), 1);
        expect(server.count('/v2/texts/t2'), 1);
      },
    );

    test('follows translations of translations, from any member', () async {
      // Sanskrit root > Tibetan translation > English translation of it.
      final server = LibraryTestServer({
        '/v2/texts/sa':
            (_) => jsonBody(
              textJson('sa', language: 'sa', translations: ['bo', 'en1']),
            ),
        '/v2/texts/bo':
            (_) => jsonBody(
              textJson('bo', translationOf: 'sa', translations: ['en2']),
            ),
        '/v2/texts/en1':
            (_) =>
                jsonBody(textJson('en1', language: 'en', translationOf: 'sa')),
        '/v2/texts/en2':
            (_) =>
                jsonBody(textJson('en2', language: 'en', translationOf: 'bo')),
      });
      final repository = server.repository();

      for (final id in ['en2', 'bo', 'sa']) {
        final family = await repository.getTextFamily(id);
        expect(family.map((t) => t.id), ['sa', 'bo', 'en1', 'en2'], reason: id);
      }
    });

    test(
      'a parent that does not list the text, or a cycle, still ends',
      () async {
        final server = LibraryTestServer({
          '/v2/texts/root': (_) => jsonBody(textJson('root')),
          '/v2/texts/orphan':
              (_) => jsonBody(textJson('orphan', translationOf: 'root')),
          '/v2/texts/a': (_) => jsonBody(textJson('a', translationOf: 'b')),
          '/v2/texts/b': (_) => jsonBody(textJson('b', translationOf: 'a')),
        });
        final repository = server.repository();

        expect((await repository.getTextFamily('orphan')).map((t) => t.id), [
          'root',
          'orphan',
        ]);
        expect((await repository.getTextFamily('a')).map((t) => t.id), [
          'b',
          'a',
        ]);
      },
    );
  });

  group('LibraryRepository.alignSegment across a translation chain', () {
    test("maps a translation's verse to the text it was made from", () async {
      final server = LibraryTestServer({
        '/v2/texts/sa':
            (_) =>
                jsonBody(textJson('sa', language: 'sa', translations: ['bo'])),
        '/v2/texts/bo':
            (_) => jsonBody(
              textJson(
                'bo',
                translationOf: 'sa',
                translations: ['en'],
                editions: ['e-bo'],
              ),
            ),
        '/v2/texts/en':
            (_) => jsonBody(
              textJson(
                'en',
                language: 'en',
                translationOf: 'bo',
                editions: ['e-en'],
              ),
            ),
        '/v2/editions/e-bo': (_) => jsonBody({'id': 'e-bo', 'text_id': 'bo'}),
        '/v2/editions/e-en': (_) => jsonBody({'id': 'e-en', 'text_id': 'en'}),
        '/v2/editions/e-bo/segmentation/segments':
            (_) => jsonBody(pageJson(threeVerses('b'))),
        '/v2/editions/e-en/segmentation/segments':
            (_) => jsonBody(pageJson(threeVerses('n'))),
      });

      final aligned = await server.repository().alignSegment(
        segmentId: 'n2',
        sourceId: 'e-en',
        targetId: 'e-bo',
      );

      expect(aligned, 'b2');
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
    // root (bo) <- trans (en, translation_of root)
    // comm (bo, commentary_of root) <- comm-en (translation_of comm)
    // other-comm-en: translation of a commentary that is not itself related.
    Map<String, ResponseBody Function(Uri)> texts() => {
      '/v2/texts/root': (_) => jsonBody(textJson('root')),
      '/v2/texts/trans':
          (_) => jsonBody(
            textJson('trans', translationOf: 'root', language: 'en'),
          ),
      '/v2/texts/comm': (_) => jsonBody(textJson('comm', commentaryOf: 'root')),
      '/v2/texts/comm-en':
          (_) => jsonBody(
            textJson('comm-en', translationOf: 'comm', language: 'en'),
          ),
      '/v2/texts/other-comm-en':
          (_) => jsonBody(
            textJson(
              'other-comm-en',
              translationOf: 'other-comm',
              language: 'en',
            ),
          ),
      '/v2/texts/other-comm':
          (_) => jsonBody(textJson('other-comm', commentaryOf: 'root')),
      '/v2/editions/e-comm':
          (_) => jsonBody({'id': 'e-comm', 'text_id': 'comm'}),
    };

    test(
      'open root: same work is a translation, commentaries nest their translations',
      () async {
        final server = LibraryTestServer({
          '/v2/segments/s1':
              (_) => jsonBody(
                segmentJson(
                  's1',
                  '1',
                  [
                    [0, 5],
                  ],
                  textId: 'root',
                  editionId: 'e-root',
                ),
              ),
          '/v2/segments/s1/related':
              (_) => jsonBody(
                pageJson([
                  segmentJson(
                    'r0',
                    '1',
                    [
                      [0, 5],
                    ],
                    textId: 'root',
                    editionId: 'e-root2',
                  ),
                  segmentJson(
                    'r1',
                    '1',
                    [
                      [0, 5],
                    ],
                    textId: 'trans',
                    editionId: 'e-trans',
                  ),
                  segmentJson(
                    'c2',
                    '3',
                    [
                      [10, 15],
                    ],
                    textId: 'comm',
                    editionId: 'e-comm',
                  ),
                  segmentJson(
                    'c1',
                    '2',
                    [
                      [5, 10],
                    ],
                    textId: 'comm',
                    editionId: 'e-comm',
                  ),
                  segmentJson(
                    'ce',
                    '2',
                    [
                      [5, 10],
                    ],
                    textId: 'comm-en',
                    editionId: 'e-comm-en',
                  ),
                  segmentJson(
                    'oc',
                    '2',
                    [
                      [5, 10],
                    ],
                    textId: 'other-comm-en',
                    editionId: 'e-oc',
                  ),
                  segmentJson('r5', '1', [
                    [0, 5],
                  ]),
                ], limit: 20),
              ),
          ...texts(),
        });
        final repository = server.repository();

        final resources = await repository.loadSegmentResources('s1');
        await repository.loadSegmentResources('s1');

        expect(resources.hasRootWork, isFalse);
        expect(resources.rootTexts, isEmpty);
        expect(resources.translations.map((e) => e.editionId), ['e-trans']);
        expect(resources.translations.single.title, 'Title trans');
        expect(resources.commentaries.map((e) => e.editionId), [
          'e-comm',
          'e-oc',
        ]);
        final comm = resources.commentaries.first;
        expect(comm.segments.map((s) => s.id), ['c1', 'c2']);
        expect(comm.translations.map((e) => e.editionId), ['e-comm-en']);
        expect(server.count('/v2/segments/s1/related'), 1);
        expect(server.count('/v2/texts/root'), 1);
        expect(server.count('/v2/texts/comm'), 1);
      },
    );

    test(
      'open translated commentary: root work in any language, own work as translations',
      () async {
        final server = LibraryTestServer({
          '/v2/segments/s1':
              (_) => jsonBody(
                segmentJson(
                  's1',
                  '1',
                  [
                    [0, 5],
                  ],
                  textId: 'comm-en',
                  editionId: 'e-comm-en',
                ),
              ),
          '/v2/segments/s1/related':
              (_) => jsonBody(
                pageJson([
                  segmentJson(
                    'r0',
                    '1',
                    [
                      [0, 5],
                    ],
                    textId: 'root',
                    editionId: 'e-root',
                  ),
                  segmentJson(
                    'r1',
                    '1',
                    [
                      [0, 5],
                    ],
                    textId: 'trans',
                    editionId: 'e-trans',
                  ),
                  segmentJson(
                    'c1',
                    '2',
                    [
                      [5, 10],
                    ],
                    textId: 'comm',
                    editionId: 'e-comm',
                  ),
                  segmentJson(
                    'oc',
                    '2',
                    [
                      [5, 10],
                    ],
                    textId: 'other-comm-en',
                    editionId: 'e-oc',
                  ),
                  segmentJson(
                    'x',
                    '2',
                    [
                      [5, 10],
                    ],
                    textId: 'missing',
                    editionId: 'e-x',
                  ),
                ], limit: 20),
              ),
          ...texts(),
        });

        final resources = await server.repository().loadSegmentResources('s1');

        expect(resources.hasRootWork, isTrue);
        expect(resources.rootTexts.map((e) => e.editionId), [
          'e-root',
          'e-trans',
        ]);
        expect(resources.translations.map((e) => e.editionId), [
          'e-comm',
          'e-x',
        ]);
        expect(resources.commentaries.map((e) => e.editionId), ['e-oc']);
      },
    );

    test(
      'the open text is known from an edition the reader already loaded',
      () async {
        final server = LibraryTestServer({
          '/v2/editions/e-comm/segmentation/segments':
              (_) => jsonBody(
                pageJson([
                  segmentJson('s1', '1', [
                    [0, 5],
                  ]),
                ]),
              ),
          '/v2/segments/s1/related':
              (_) => jsonBody(
                pageJson([
                  segmentJson(
                    'c1',
                    '2',
                    [
                      [5, 10],
                    ],
                    textId: 'comm-en',
                    editionId: 'e-comm2',
                  ),
                  segmentJson(
                    'r0',
                    '1',
                    [
                      [0, 5],
                    ],
                    textId: 'root',
                    editionId: 'e-root',
                  ),
                ], limit: 20),
              ),
          ...texts(),
        });
        final repository = server.repository();
        await repository.getEditionSegments('e-comm');

        final resources = await repository.loadSegmentResources('s1');

        expect(server.count('/v2/segments/s1'), 0);
        expect(resources.rootTexts.map((e) => e.editionId), ['e-root']);
        expect(resources.translations.map((e) => e.editionId), ['e-comm2']);
      },
    );
  });

  group('LibraryRepository.loadEditionContent', () {
    test('slices every segment from one content fetch', () async {
      final server = LibraryTestServer({
        '/v2/editions/e1/content': (_) => jsonBody('cdefghi'),
        '/v2/editions/e1':
            (_) => jsonBody({'id': 'e1', 'text_id': 't', 'source': 'src'}),
      });
      final edition = LibraryRelatedEdition(
        editionId: 'e1',
        text: null,
        segments: [
          LibrarySegment.fromJson(
            segmentJson('a', '1', [
              [2, 4],
            ]),
          ),
          LibrarySegment.fromJson(
            segmentJson('b', '2', [
              [4, 6],
              [6, 9],
            ]),
          ),
        ],
      );

      final content = await server.repository().loadEditionContent(edition);

      expect(content.segmentLines, [
        ['cd'],
        ['ef', 'ghi'],
      ]);
      expect(content.source, 'src');
      final uri = server.requests.singleWhere(
        (u) => u.path.endsWith('/content'),
      );
      expect(uri.queryParameters, {'span_start': '2', 'span_end': '9'});
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
        '/v2/editions/e1': (_) => jsonBody({'detail': 'boom'}, statusCode: 500),
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
