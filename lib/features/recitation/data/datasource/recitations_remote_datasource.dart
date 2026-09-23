import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitations_page_response.dart';

/// Chant catalogue query; the library adapter overrides the page fetch.
class RecitationsQueryParams {
  final String? language;
  final String? search;
  final int? skip;
  final int? limit;
  final bool shouldIncludeCollections;

  RecitationsQueryParams({
    this.language,
    this.search,
    this.skip,
    this.limit,
    this.shouldIncludeCollections = false,
  });

  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {};
    if (language != null) params['language'] = language!;
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    if (skip != null) params['skip'] = skip!;
    if (limit != null) params['limit'] = limit!;
    if (shouldIncludeCollections) {
      params['should_include_collections'] = 'true';
    }
    return params;
  }
}

class RecitationsRemoteDatasource {
  final Dio dio;

  RecitationsRemoteDatasource({required this.dio});

  Future<RecitationsPageResponse> fetchRecitationsPage({
    RecitationsQueryParams? queryParams,
  }) async {
    final response = await dio.get(
      '/recitations',
      queryParameters: queryParams?.toQueryParams(),
    );

    return RecitationsPageResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<RecitationModel>> fetchRecitations({
    RecitationsQueryParams? queryParams,
  }) async {
    final page = await fetchRecitationsPage(queryParams: queryParams);
    return page.recitations;
  }
}
