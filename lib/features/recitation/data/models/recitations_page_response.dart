import 'package:flutter_pecha/features/recitation/data/models/my_recitation_list_collection_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';

class RecitationsPageResponse {
  final List<RecitationModel> recitations;
  final List<MyRecitationListCollectionModel> collections;
  final int skip;
  final int limit;
  final int total;

  /// Where the next page starts. Can exceed `skip + recitations.length` when
  /// the source dropped items it cannot list.
  final int nextSkip;

  const RecitationsPageResponse({
    required this.recitations,
    this.collections = const [],
    required this.skip,
    required this.limit,
    required this.total,
    int? nextSkip,
  }) : nextSkip = nextSkip ?? skip + recitations.length;

  factory RecitationsPageResponse.fromJson(Map<String, dynamic> json) {
    final recitationsData = json['recitations'] as List<dynamic>? ?? [];
    final collectionsData = json['collections'] as List<dynamic>? ?? [];
    return RecitationsPageResponse(
      recitations:
          recitationsData
              .map(
                (item) =>
                    RecitationModel.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      collections:
          collectionsData
              .whereType<Map<String, dynamic>>()
              .map(MyRecitationListCollectionModel.fromJson)
              .toList(),
      skip: json['skip'] as int? ?? 0,
      limit: json['limit'] as int? ?? recitationsData.length,
      total: json['total'] as int? ?? recitationsData.length,
    );
  }

  bool get hasMore => nextSkip < total;
}
