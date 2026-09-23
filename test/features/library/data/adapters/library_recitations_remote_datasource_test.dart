import 'package:flutter_pecha/features/library/data/adapters/library_recitations_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/datasource/my_recitation_collections_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitations_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../library_test_server.dart';

Map<String, dynamic> _collection(String id, String name, int count) => {
  'id': id,
  'name': name,
  'img_url': 'https://img.test/$id.webp',
  'item_count': count,
};

/// Library routes plus the main-API collections route on one fake server.
LibraryTestServer _server({List<Uri>? seen}) => LibraryTestServer({
  '/v2/texts': (uri) {
    seen?.add(uri);
    final offset = uri.queryParameters['offset'];
    if (uri.queryParameters['title'] == 'zzz') {
      return jsonBody(pageJson(const [], limit: 20));
    }
    if (offset == '20') {
      return jsonBody(
        pageJson([
          textJson('T3', language: 'en', editions: ['E3']),
        ], offset: 20, limit: 20),
      );
    }
    return jsonBody(
      pageJson([
        textJson('T1', language: 'en', editions: ['E1']),
        textJson('T2', language: 'en', editions: ['E2']),
        textJson('NOED', language: 'en'),
      ], hasMore: true, limit: 20),
    );
  },
  '/v2/editions/E1/segmentation/segments': (uri) {
    expect(uri.queryParameters['limit'], '1');
    return jsonBody(
      pageJson([
        segmentJson('s1', '1', [
          [0, 3],
          [3, 6],
        ]),
      ], hasMore: true, limit: 1),
    );
  },
  '/v2/editions/E1/content': (uri) {
    expect(uri.queryParameters['span_start'], '0');
    expect(uri.queryParameters['span_end'], '6');
    return jsonBody('abcdef');
  },
  '/v2/editions/E2/segmentation/segments':
      (_) => jsonBody({'detail': 'boom'}, statusCode: 500),
  '/v2/editions/E3/segmentation/segments':
      (_) => jsonBody(
        pageJson([
          segmentJson('t1', '1', [
            [0, 2],
          ]),
        ], limit: 1),
      ),
  '/v2/editions/E3/content': (_) => jsonBody('xy'),
  '/users/me/recitation-collections': (uri) {
    final skip = uri.queryParameters['skip'];
    if (skip == '0') {
      return jsonBody({
        'collections': List.generate(
          20,
          (i) => _collection('c$i', 'name $i', i),
        ),
        'skip': 0,
        'limit': 20,
        'total': 21,
      });
    }
    return jsonBody({
      'collections': [_collection('c20', 'last', 3)],
      'skip': 20,
      'limit': 20,
      'total': 21,
    });
  },
});

LibraryRecitationsRemoteDatasource _datasource(LibraryTestServer server) {
  return LibraryRecitationsRemoteDatasource(
    library: server.repository(),
    collections: MyRecitationCollectionsRemoteDatasource(dio: server.dio()),
    tagId: 'TAG',
  );
}

void main() {
  test('maps library texts to recitations with a first-verse preview', () async {
    final seen = <Uri>[];
    final page = await _datasource(_server(seen: seen)).fetchRecitationsPage(
      queryParams: RecitationsQueryParams(language: 'en', skip: 0, limit: 20),
    );

    expect(seen.single.queryParameters, {
      'language': 'en',
      'tag_id': 'TAG',
      'limit': '20',
      'offset': '0',
    });
    expect(page.recitations.map((r) => r.textId), ['T1', 'T2', 'NOED']);
    expect(page.recitations.first.title, 'Title T1');
    expect(page.recitations.first.language, 'en');
    expect(page.recitations.first.firstSegment?.id, 's1');
    expect(page.recitations.first.firstSegment?.content, 'abc⤵def');
    // A failing preview and a text without an edition still list.
    expect(page.recitations[1].firstSegment, isNull);
    expect(page.recitations[2].firstSegment, isNull);
    expect(page.collections, isEmpty);
    expect(page.skip, 0);
    expect(page.hasMore, isTrue);
  });

  test('the last page reports no more and includes collections', () async {
    final page = await _datasource(_server()).fetchRecitationsPage(
      queryParams: RecitationsQueryParams(
        language: 'en',
        skip: 20,
        limit: 20,
        shouldIncludeCollections: true,
      ),
    );

    expect(page.recitations.map((r) => r.textId), ['T3']);
    expect(page.recitations.single.firstSegment?.content, 'xy');
    expect(page.hasMore, isFalse);
    expect(page.collections, hasLength(21));
    expect(page.collections.last.collectionId, 'c20');
    expect(page.collections.last.name, 'last');
    expect(page.collections.last.itemCount, 3);
    expect(page.collections.last.imageUrl, 'https://img.test/c20.webp');
  });

  test('search passes the title filter and skips one-character queries', () async {
    final seen = <Uri>[];
    final ds = _datasource(_server(seen: seen));

    final none = await ds.fetchRecitationsPage(
      queryParams: RecitationsQueryParams(language: 'en', search: 'zzz'),
    );
    expect(seen.single.queryParameters['title'], 'zzz');
    expect(none.recitations, isEmpty);
    expect(none.hasMore, isFalse);

    final short = await ds.fetchRecitationsPage(
      queryParams: RecitationsQueryParams(language: 'en', search: 'z'),
    );
    expect(seen, hasLength(1));
    expect(short.recitations, isEmpty);
  });
}
