import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/library/data/datasource/library_remote_datasource.dart';
import 'package:flutter_pecha/features/library/data/repositories/library_repository.dart';

class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this._onFetch);

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

ResponseBody jsonBody(Object? data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// Routes requests by path and records every URI it served.
class LibraryTestServer {
  LibraryTestServer(this.routes);

  final Map<String, ResponseBody Function(Uri uri)> routes;
  final List<Uri> requests = [];

  Future<ResponseBody> handle(RequestOptions options) async {
    final uri = options.uri;
    requests.add(uri);
    final route = routes[uri.path];
    if (route == null) return jsonBody({'detail': 'missing'}, statusCode: 404);
    return route(uri);
  }

  int count(String path) => requests.where((u) => u.path == path).length;

  Dio dio() {
    final dio = Dio(BaseOptions(baseUrl: 'https://library.test'));
    dio.httpClientAdapter = FakeHttpAdapter(handle);
    return dio;
  }

  LibraryRepository repository({
    int segmentPageSize = 500,
    int relatedPageSize = 20,
  }) {
    return LibraryRepository(
      datasource: LibraryRemoteDatasource(dio: dio()),
      segmentPageSize: segmentPageSize,
      relatedPageSize: relatedPageSize,
    );
  }
}

Map<String, dynamic> segmentJson(
  String id,
  String? reference,
  List<List<int>> lines, {
  String? textId,
  String? editionId,
}) => {
  'id': id,
  'type': 'verse',
  'reference': reference,
  'lines': [
    for (final line in lines) {'start': line[0], 'end': line[1]},
  ],
  if (textId != null) 'text_id': textId,
  if (editionId != null) 'edition_id': editionId,
};

Map<String, dynamic> textJson(
  String id, {
  String language = 'bo',
  String? translationOf,
  String? commentaryOf,
  List<String> editions = const [],
  List<String> translations = const [],
}) => {
  'id': id,
  'title': {language: 'Title $id'},
  'language': language,
  'commentary_of': commentaryOf,
  'translation_of': translationOf,
  'license': 'public',
  'editions': editions,
  'translations': translations,
  'commentaries': [],
  'tag_ids': [],
};

Map<String, dynamic> pageJson(
  List<Map<String, dynamic>> items, {
  bool hasMore = false,
  int offset = 0,
  int limit = 500,
}) => {'items': items, 'has_more': hasMore, 'offset': offset, 'limit': limit};

/// Three verses at [0,3) [3,6) [6,9) with references 1..3.
List<Map<String, dynamic>> threeVerses(String prefix) => [
  segmentJson('${prefix}1', '1', [
    [0, 3],
  ]),
  segmentJson('${prefix}2', '2', [
    [3, 6],
  ]),
  segmentJson('${prefix}3', '3', [
    [6, 9],
  ]),
];
