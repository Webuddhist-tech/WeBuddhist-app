import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/texts/data/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/search/search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/search/title_search_response.dart';
import 'package:flutter_pecha/features/texts/data/models/text/reader_response.dart';

/// Main-API text search. Reader details and in-text search are provided by
/// the library adapter that extends this class.
abstract class TextRemoteDatasource {
  final Dio dio;

  TextRemoteDatasource({required this.dio});

  Future<ReaderResponse> fetchTextDetails({
    required String textId,
    String? contentId,
    String? versionId,
    String? segmentId,
    String? direction,
    String? language,
    int? size,
  });

  Future<MultilingualSearchResponse> multilingualSearch({
    required String query,
    String? language,
    String? textId,
  });

  // search the text by query
  Future<SearchResponse> searchText({
    required String query,
    String? language,
    String? textId,
  }) async {
    final response = await dio.get(
      '/search',
      queryParameters: {
        'query': query,
        'search_type': 'SOURCE',
        if (language != null) 'language': language,
        if (textId != null) 'text_id': textId,
      },
    );

    return SearchResponse.fromJson(response.data);
  }

  // title search
  Future<TitleSearchResponse> titleSearch({
    String? title,
    String? author,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await dio.get(
      '/texts/title-search',
      queryParameters: {
        if (title != null && title.isNotEmpty) 'title': title,
        if (author != null && author.isNotEmpty) 'author': author,
        'limit': limit,
        'offset': offset,
      },
    );

    final jsonList = response.data as List<dynamic>;
    return TitleSearchResponse.fromJson(
      jsonList,
      total: jsonList.length,
      limit: limit,
      offset: offset,
    );
  }

  // author search - uses same endpoint as title search but with author parameter
  Future<TitleSearchResponse> authorSearch({
    String? author,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await dio.get(
      '/texts/title-search',
      queryParameters: {
        if (author != null && author.isNotEmpty) 'author': author,
        'limit': limit,
        'offset': offset,
      },
    );

    final jsonList = response.data as List<dynamic>;
    return TitleSearchResponse.fromJson(
      jsonList,
      total: jsonList.length,
      limit: limit,
      offset: offset,
    );
  }
}
