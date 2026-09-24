import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/library/data/models/library_text.dart';
import 'package:flutter_pecha/features/library/data/repositories/library_repository.dart';
import 'package:flutter_pecha/features/practice/data/datasource/my_recitation_collections_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitations_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/data/models/my_recitation_list_collection_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitations_page_response.dart';

/// Chant catalogue and search from the library API; the user's collections
/// and saved chants still come from the main API.
class LibraryRecitationsRemoteDatasource extends RecitationsRemoteDatasource {
  LibraryRecitationsRemoteDatasource({
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
  static const int _collectionsPageSize = 20;
  static const int _maxCollectionPages = 50;

  /// `search` becomes the library title filter; `total` is synthesized from
  /// `has_more` so [RecitationsPageResponse.hasMore] keeps working, and
  /// `nextSkip` is the raw library offset. Each chant's `textId` is its
  /// edition id, the id the rest of the app stores.
  @override
  Future<RecitationsPageResponse> fetchRecitationsPage({
    RecitationsQueryParams? queryParams,
  }) async {
    final params = queryParams ?? RecitationsQueryParams();
    final skip = params.skip ?? 0;
    final limit = (params.limit ?? _defaultLimit).clamp(1, _maxLimit);
    final search = params.search?.trim();
    // Collections come from another API: when they fail the chants still
    // list. Handling the error here also keeps it from going unobserved if
    // the chant request below throws first.
    final collectionsFuture =
        params.shouldIncludeCollections
            ? _loadAllCollections().catchError((Object error) {
              _logger.warning('Recitation collections failed', error);
              return const <MyRecitationListCollectionModel>[];
            })
            : Future.value(const <MyRecitationListCollectionModel>[]);

    List<LibraryText> texts = const [];
    var hasMore = false;
    var nextSkip = skip;
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
      // A text without an edition has nothing to open, so it is not listed;
      // the next offset still counts it so pages never repeat.
      texts = page.items.where((t) => t.primaryEditionId != null).toList();
      hasMore = page.hasMore && page.items.isNotEmpty;
      nextSkip = skip + page.items.length;
    }

    // No first-verse preview: it cost two more calls per chant.
    final recitations = [
      for (final text in texts)
        RecitationModel(
          textId: text.primaryEditionId!,
          title: text.displayTitle,
          language: text.language,
        ),
    ];
    return RecitationsPageResponse(
      recitations: recitations,
      collections: await collectionsFuture,
      skip: skip,
      limit: limit,
      total: nextSkip + (hasMore ? 1 : 0),
      nextSkip: nextSkip,
    );
  }

  /// Pages by the offset it asked for, not the one echoed back, and stops on
  /// a page with nothing new so a server ignoring `skip` cannot loop it.
  Future<List<MyRecitationListCollectionModel>> _loadAllCollections() async {
    final rows = <MyRecitationListCollectionModel>[];
    final seen = <String>{};
    var skip = 0;
    for (var i = 0; i < _maxCollectionPages; i++) {
      final page = await _collections.fetchCollections(
        skip: skip,
        limit: _collectionsPageSize,
      );
      final fresh = page.collections.where((c) => seen.add(c.id)).toList();
      rows.addAll(fresh.map(_toListModel));
      skip += page.collections.length;
      if (fresh.isEmpty || skip >= page.total) return rows;
    }
    _logger.warning(
      'Stopped listing collections after $_maxCollectionPages pages',
    );
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
