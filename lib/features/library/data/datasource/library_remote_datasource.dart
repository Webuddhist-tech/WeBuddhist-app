import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/library/data/models/library_edition.dart';
import 'package:flutter_pecha/features/library/data/models/library_language.dart';
import 'package:flutter_pecha/features/library/data/models/library_search_result.dart';
import 'package:flutter_pecha/features/library/data/models/library_segment.dart';
import 'package:flutter_pecha/features/library/data/models/library_text.dart';

/// Library (texts) API. Errors are mapped by ErrorInterceptor and propagate.
class LibraryRemoteDatasource {
  LibraryRemoteDatasource({required this.dio});

  final Dio dio;

  /// [title] filters by title and must be at least two characters.
  Future<LibraryTextPage> fetchTexts({
    required String tagId,
    String? language,
    String? title,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await dio.get(
      '/v2/texts',
      queryParameters: {
        if (language != null && language.isNotEmpty) 'language': language,
        if (title != null && title.isNotEmpty) 'title': title,
        'tag_id': tagId,
        'limit': limit,
        'offset': offset,
      },
    );
    return LibraryTextPage.fromJson(_asMap(response.data, '/v2/texts'));
  }

  Future<LibraryText> fetchText(String textId) async {
    final response = await dio.get('/v2/texts/$textId');
    return LibraryText.fromJson(_asMap(response.data, '/v2/texts/{id}'));
  }

  Future<LibraryEdition> fetchEdition(String editionId) async {
    final response = await dio.get('/v2/editions/$editionId');
    return LibraryEdition.fromJson(
      _asMap(response.data, '/v2/editions/{id}'),
    );
  }

  Future<LibrarySegmentPage> fetchEditionSegments(
    String editionId, {
    int limit = 500,
    int offset = 0,
  }) async {
    final response = await dio.get(
      '/v2/editions/$editionId/segmentation/segments',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return LibrarySegmentPage.fromJson(
      _asMap(response.data, '/v2/editions/{id}/segmentation/segments'),
    );
  }

  Future<String> fetchEditionContent(
    String editionId, {
    required int spanStart,
    required int spanEnd,
  }) async {
    final response = await dio.get(
      '/v2/editions/$editionId/content',
      queryParameters: {'span_start': spanStart, 'span_end': spanEnd},
    );
    return _asContent(response.data, '/v2/editions/{id}/content');
  }

  Future<LibrarySegment> fetchSegment(String segmentId) async {
    final response = await dio.get('/v2/segments/$segmentId');
    return LibrarySegment.fromJson(
      _asMap(response.data, '/v2/segments/{id}'),
    );
  }

  Future<LibrarySegmentPage> fetchRelatedSegments(
    String segmentId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await dio.get(
      '/v2/segments/$segmentId/related',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return LibrarySegmentPage.fromJson(
      _asMap(response.data, '/v2/segments/{id}/related'),
    );
  }

  Future<String> fetchSegmentContent(String segmentId) async {
    final response = await dio.get('/v2/segments/$segmentId/content');
    return _asContent(response.data, '/v2/segments/{id}/content');
  }

  Future<List<LibraryLanguage>> fetchLanguages() async {
    final response = await dio.get('/v2/languages');
    return _asList(response.data, '/v2/languages')
        .map(LibraryLanguage.fromJson)
        .toList(growable: false);
  }

  Future<List<LibrarySearchResult>> searchContent({
    required String query,
    String? textId,
    String? editionId,
    int limit = 50,
    String searchType = 'exact',
  }) async {
    final response = await dio.get(
      '/v2/content-search',
      queryParameters: {
        'query': query,
        'search_type': searchType,
        'limit': limit,
        if (textId != null) 'text_id': textId,
        if (editionId != null) 'edition_id': editionId,
      },
    );
    return _asList(response.data, '/v2/content-search')
        .map(LibrarySearchResult.fromJson)
        .toList(growable: false);
  }

  static Map<String, dynamic> _asMap(Object? data, String endpoint) {
    if (data is Map<String, dynamic>) return data;
    throw FormatException('Unexpected $endpoint payload type');
  }

  static Iterable<Map<String, dynamic>> _asList(Object? data, String endpoint) {
    if (data is List) return data.whereType<Map<String, dynamic>>();
    throw FormatException('Unexpected $endpoint payload type');
  }

  // Content endpoints return a bare JSON string.
  static String _asContent(Object? data, String endpoint) {
    if (data is String) return data;
    if (data is Map<String, dynamic> && data['content'] is String) {
      return data['content'] as String;
    }
    throw FormatException('Unexpected $endpoint payload type');
  }
}
