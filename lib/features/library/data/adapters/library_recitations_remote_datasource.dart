import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/library/data/models/library_text.dart';
import 'package:flutter_pecha/features/library/data/repositories/library_repository.dart';
import 'package:flutter_pecha/features/practice/data/datasource/my_recitation_collections_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitations_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/data/models/my_recitation_list_collection_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitations_page_response.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Chant catalogue and search from the library API; the user's collections
/// and saved chants still come from the main API.
class LibraryRecitationsRemoteDatasource extends RecitationsRemoteDatasource {
  LibraryRecitationsRemoteDatasource({
    required super.dio,
    required LibraryRepository library,
    required MyRecitationCollectionsRemoteDatasource collections,
    required String tagId,
  }) : _library = library,
       _collections = collections,
       _tagId = tagId;

  final LibraryRepository _library;
  final MyRecitationCollectionsRemoteDatasource _collections;
  final String _tagId;
  final _logger = AppLogger('LibraryRecitationsRemoteDatasource');

  static const int _defaultLimit = 20;
  static const int _maxLimit = 100;
  static const int _minTitleQueryLength = 2;
  static const int _previewConcurrency = 6;
  static const int _collectionsPageSize = 20;

  /// `search` becomes the library title filter; `total` is synthesized from
  /// `has_more` so [RecitationsPageResponse.hasMore] keeps working.
  @override
  Future<RecitationsPageResponse> fetchRecitationsPage({
    RecitationsQueryParams? queryParams,
  }) async {
    final params = queryParams ?? RecitationsQueryParams();
    final skip = params.skip ?? 0;
    final limit = (params.limit ?? _defaultLimit).clamp(1, _maxLimit);
    final search = params.search?.trim();
    final collectionsFuture =
        params.shouldIncludeCollections
            ? _loadAllCollections()
            : Future.value(const <MyRecitationListCollectionModel>[]);

    List<LibraryText> texts = const [];
    var hasMore = false;
    final tooShort =
        search != null &&
        search.isNotEmpty &&
        search.length < _minTitleQueryLength;
    if (!tooShort) {
      final page = await _library.fetchChants(
        tagId: _tagId,
        language: params.language,
        title: search,
        limit: limit,
        offset: skip,
      );
      texts = page.items;
      hasMore = page.hasMore && page.items.isNotEmpty;
    }

    final previews = await _previews(texts);
    final recitations = [
      for (var i = 0; i < texts.length; i++)
        RecitationModel(
          textId: texts[i].id,
          title: texts[i].displayTitle,
          language: texts[i].language,
          firstSegment: previews[i],
        ),
    ];
    return RecitationsPageResponse(
      recitations: recitations,
      collections: await collectionsFuture,
      skip: skip,
      limit: limit,
      total: skip + recitations.length + (hasMore ? 1 : 0),
    );
  }

  Future<List<RecitationFirstSegmentModel?>> _previews(
    List<LibraryText> texts,
  ) async {
    final results = List<RecitationFirstSegmentModel?>.filled(
      texts.length,
      null,
    );
    for (var i = 0; i < texts.length; i += _previewConcurrency) {
      final end =
          i + _previewConcurrency > texts.length
              ? texts.length
              : i + _previewConcurrency;
      final batch = await Future.wait([
        for (var j = i; j < end; j++) _firstSegment(texts[j]),
      ]);
      results.setRange(i, end, batch);
    }
    return results;
  }

  // A preview that fails to load must not drop the chant from the list.
  Future<RecitationFirstSegmentModel?> _firstSegment(LibraryText text) async {
    final editionId = text.primaryEditionId;
    if (editionId == null) return null;
    try {
      final segment = await _library.loadFirstSegment(editionId);
      if (segment == null) return null;
      return RecitationFirstSegmentModel(
        id: segment.id,
        content: segment.lines.join(kSegmentSoftBreak),
      );
    } catch (e) {
      _logger.warning('First segment of ${text.id} failed', e);
      return null;
    }
  }

  Future<List<MyRecitationListCollectionModel>> _loadAllCollections() async {
    final rows = <MyRecitationListCollectionModel>[];
    var skip = 0;
    while (true) {
      final page = await _collections.fetchCollections(
        skip: skip,
        limit: _collectionsPageSize,
      );
      rows.addAll(page.collections.map(_toListModel));
      skip += page.collections.length;
      if (page.collections.isEmpty || !page.hasMore) break;
    }
    return rows;
  }

  static MyRecitationListCollectionModel _toListModel(
    MyRecitationCollectionModel collection,
  ) {
    return MyRecitationListCollectionModel(
      type: 'RECITATION_COLLECTION',
      name: collection.name,
      collectionId: collection.id,
      imageUrl: collection.imgUrl,
      itemCount: collection.itemCount,
    );
  }
}
