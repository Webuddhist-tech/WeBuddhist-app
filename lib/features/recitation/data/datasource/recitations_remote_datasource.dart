import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitations_page_response.dart';

/// Chant catalogue query, served by the library adapter.
class RecitationsQueryParams {
  final String? language;
  final String? search;
  final int? skip;
  final int? limit;
  final bool shouldIncludeCollections;

  /// Bypasses the HTTP cache so a revalidation reaches the server.
  final bool noCache;

  RecitationsQueryParams({
    this.language,
    this.search,
    this.skip,
    this.limit,
    this.shouldIncludeCollections = false,
    this.noCache = false,
  });
}

abstract class RecitationsRemoteDatasource {
  Future<RecitationsPageResponse> fetchRecitationsPage({
    RecitationsQueryParams? queryParams,
  });

  Future<List<RecitationModel>> fetchRecitations({
    RecitationsQueryParams? queryParams,
  }) async {
    final page = await fetchRecitationsPage(queryParams: queryParams);
    return page.recitations;
  }
}
