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
    if (offset == '3') {
      return jsonBody(
        pageJson([
          textJson('NOED2', language: 'en'),
        ], hasMore: true, offset: 3, limit: 20),
      );
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
  test('maps library texts to recitations keyed by edition id', () async {
    final seen = <Uri>[];
    final server = _server(seen: seen);
    final page = await _datasource(server).fetchRecitationsPage(
      queryParams: RecitationsQueryParams(language: 'en', skip: 0, limit: 20),
    );

    expect(seen.single.queryParameters, {
      'language': 'en',
      'tag_id': 'TAG',
      'limit': '20',
      'offset': '0',
    });
    // The list is one call: no per-chant preview fetches.
    expect(server.requests.map((u) => u.path), ['/v2/texts']);
    // NOED has no edition, so it is not listed.
    expect(page.recitations.map((r) => r.textId), ['E1', 'E2']);
    expect(page.recitations.first.title, 'Title T1');
    expect(page.recitations.first.language, 'en');
    expect(page.recitations.first.firstSegment, isNull);
    expect(page.collections, isEmpty);
    expect(page.skip, 0);
    // The dropped text still counts towards the library offset.
    expect(page.nextSkip, 3);
    expect(page.hasMore, isTrue);
  });

  test('a page of texts without editions still advances the offset', () async {
    final page = await _datasource(_server()).fetchRecitationsPage(
      queryParams: RecitationsQueryParams(language: 'en', skip: 3, limit: 20),
    );

    expect(page.recitations, isEmpty);
    expect(page.nextSkip, 4);
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

    expect(page.recitations.map((r) => r.textId), ['E3']);
    expect(page.nextSkip, 21);
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

  test('chants still list when the collections request fails', () async {
    final server = LibraryTestServer({
      ..._server().routes,
      '/users/me/recitation-collections':
          (_) => jsonBody({'detail': 'boom'}, statusCode: 500),
    });

    final page = await _datasource(server).fetchRecitationsPage(
      queryParams: RecitationsQueryParams(
        language: 'en',
        skip: 0,
        limit: 20,
        shouldIncludeCollections: true,
      ),
    );

    expect(page.recitations.map((r) => r.textId), ['E1', 'E2']);
    expect(page.collections, isEmpty);
  });

  test('a chant failure surfaces alone, collections errors handled', () async {
    final server = LibraryTestServer({
      '/v2/texts': (_) => jsonBody({'detail': 'down'}, statusCode: 503),
      '/users/me/recitation-collections':
          (_) => jsonBody({'detail': 'boom'}, statusCode: 500),
    });

    await expectLater(
      _datasource(server).fetchRecitationsPage(
        queryParams: RecitationsQueryParams(
          language: 'en',
          shouldIncludeCollections: true,
        ),
      ),
      throwsA(anything),
    );
    // Let the collections request settle: an unhandled error would fail here.
    await Future<void>.delayed(Duration.zero);
  });

  test('collections stop when the server ignores skip', () async {
    final server = LibraryTestServer({
      ..._server().routes,
      '/users/me/recitation-collections':
          (_) => jsonBody({
            'collections': [_collection('c0', 'only', 1)],
            'skip': 0,
            'limit': 20,
            'total': 99,
          }),
    });

    final page = await _datasource(server).fetchRecitationsPage(
      queryParams: RecitationsQueryParams(
        language: 'en',
        skip: 0,
        limit: 20,
        shouldIncludeCollections: true,
      ),
    );

    expect(page.collections.map((c) => c.collectionId), ['c0']);
    expect(server.count('/users/me/recitation-collections'), 2);
  });
}
