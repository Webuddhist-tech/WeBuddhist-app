import 'package:flutter_pecha/features/texts/data/models/search/pagination.dart';
import 'package:flutter_pecha/features/texts/data/models/search/search.dart';
import 'package:flutter_pecha/features/texts/data/models/search/source_result_item.dart';

class SearchResponse {
  final Search search;
  final List<SourceResultItem>? sources;
  final Pagination pagination;

  SearchResponse({
    required this.search,
    required this.sources,
    required this.pagination,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      search: Search.fromJson(json['search']),
      sources:
          (json['sources'] as List)
              .map((e) => SourceResultItem.fromJson(e))
              .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'search': search.toJson(),
      'sources': sources?.map((e) => e.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}
