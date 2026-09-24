import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/practice/data/datasource/my_recitation_collections_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._onFetch);

  final Future<ResponseBody> Function(RequestOptions options) _onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _onFetch(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Object data) {
  return ResponseBody.fromString(
    jsonEncode(data),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

MyRecitationCollectionsRemoteDatasource _datasource(
  Future<ResponseBody> Function(RequestOptions) onFetch,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
  dio.httpClientAdapter = _FakeAdapter(onFetch);
  return MyRecitationCollectionsRemoteDatasource(dio: dio);
}

Map<String, dynamic> _collection(String id, String name, int count) => {
  'id': id,
  'name': name,
  'img_url': 'https://img.test/$id.webp',
  'item_count': count,
  'created_at': '2026-09-07T08:49:25.279166',
  'updated_at': '2026-09-07T08:49:25.279166',
};

void main() {
  test('parses the collections page', () {
    final page = MyRecitationCollectionsPageResponse.fromJson({
      'collections': [_collection('c1', 'the', 1), _collection('c2', 'prayers', 5)],
      'skip': 0,
      'limit': 20,
      'total': 2,
    });

    expect(page.collections.map((c) => c.name), ['the', 'prayers']);
    expect(page.collections.first.itemCount, 1);
    expect(page.collections.first.imgUrl, 'https://img.test/c1.webp');
    expect(page.total, 2);
    expect(page.hasMore, isFalse);
  });

  test('fetchCollections sends skip and limit', () async {
    Uri? requested;
    final ds = _datasource((options) async {
      requested = options.uri;
      return _jsonBody({
        'collections': [_collection('c1', 'the', 1)],
        'skip': 0,
        'limit': 20,
        'total': 1,
      });
    });

    final page = await ds.fetchCollections(skip: 0, limit: 20);

    expect(requested!.path, '/users/me/recitation-collections');
    expect(requested!.queryParameters, {'skip': '0', 'limit': '20'});
    expect(page.collections.single.id, 'c1');
  });
}
