import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';

/// Remote datasource for `/users/me/recitation-collections`.
///
/// Error handling is centralised in ErrorInterceptor, which converts
/// DioExceptions to typed AppExceptions that propagate to the repository.
class MyRecitationCollectionsRemoteDatasource {
  MyRecitationCollectionsRemoteDatasource({required this.dio});

  final Dio dio;
  final _logger = AppLogger('MyRecitationCollectionsRemoteDatasource');

  /// POST /users/me/recitation-collections/upload-image
  ///
  /// Uploads a cover image and returns its storage [MyRecitationCollectionImageUploadResponse.key].
  Future<MyRecitationCollectionImageUploadResponse> uploadImage(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });

    final response = await dio.post(
      '/users/me/recitation-collections/upload-image',
      data: formData,
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Unexpected /users/me/recitation-collections/upload-image payload type',
      );
    }
    return MyRecitationCollectionImageUploadResponse.fromJson(data);
  }

  /// POST /users/me/recitation-collections
  ///
  /// Creates a new collection for the authenticated user.
  /// Pass [CreateMyRecitationCollectionRequest.imgUrl] from a prior upload `key`.
  Future<MyRecitationCollectionModel> createCollection(
    CreateMyRecitationCollectionRequest request,
  ) async {
    final response = await dio.post(
      '/users/me/recitation-collections',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Unexpected /users/me/recitation-collections create payload type',
      );
    }
    return MyRecitationCollectionModel.fromJson(data);
  }

  /// GET /users/me/recitation-collections/{collectionId}
  Future<MyRecitationCollectionDetailModel> getCollectionDetail(
    String collectionId,
  ) async {
    final response = await dio.get(
      '/users/me/recitation-collections/$collectionId',
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Unexpected /users/me/recitation-collections detail payload type',
      );
    }
    return MyRecitationCollectionDetailModel.fromJson(data);
  }

  /// DELETE /users/me/recitation-collections/{collectionId}
  ///
  /// Successful response is `204 No Content`.
  Future<void> deleteCollection(String collectionId) async {
    final response = await dio.delete(
      '/users/me/recitation-collections/$collectionId',
    );
    final status = response.statusCode;
    if (status != null && status != 204 && status != 200) {
      throw FormatException(
        'Unexpected /users/me/recitation-collections delete status: $status',
      );
    }
  }

  /// PUT /users/me/recitation-collections/{collectionId}
  ///
  /// Updates name and optionally cover image. Pass [UpdateMyRecitationCollectionRequest.imgUrl]
  /// from a prior upload `key` when replacing the image.
  Future<MyRecitationCollectionModel> updateCollection({
    required String collectionId,
    required UpdateMyRecitationCollectionRequest request,
  }) async {
    final response = await dio.put(
      '/users/me/recitation-collections/$collectionId',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Unexpected /users/me/recitation-collections update payload type',
      );
    }
    return MyRecitationCollectionModel.fromJson(data);
  }

  /// DELETE /users/me/recitation-collections/{collectionId}/items/{itemId}
  ///
  /// Removes one chant from a collection. [itemId] is the collection-item id
  /// (not `text_id`). Successful response is `204 No Content`.
  Future<void> deleteCollectionItem({
    required String collectionId,
    required String itemId,
  }) async {
    final response = await dio.delete(
      '/users/me/recitation-collections/$collectionId/items/$itemId',
    );
    final status = response.statusCode;
    if (status != null && status != 204 && status != 200) {
      throw FormatException(
        'Unexpected /users/me/recitation-collections/items delete status: $status',
      );
    }
  }

  /// PATCH /users/me/recitation-collections/{collectionId}/items/{itemId}
  ///
  /// Updates one collection item's fractional `display_order`.
  Future<MyRecitationCollectionItemModel> updateCollectionItemDisplayOrder({
    required String collectionId,
    required String itemId,
    required double displayOrder,
  }) async {
    final request = UpdateMyRecitationCollectionItemDisplayOrderRequest(
      displayOrder: displayOrder,
    );
    final response = await dio.patch(
      '/users/me/recitation-collections/$collectionId/items/$itemId',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Unexpected /users/me/recitation-collections/items display-order payload type',
      );
    }
    return MyRecitationCollectionItemModel.fromJson(data);
  }

  /// POST /users/me/recitation-collections/{collectionId}/items
  ///
  /// Adds chants in a single request (preserving [textIds] order) so a failed
  /// write cannot leave a partially-added chant list from client-side looping.
  Future<AddMyRecitationCollectionItemsResponse> addItemsToCollection({
    required String collectionId,
    required List<String> textIds,
  }) async {
    final uniqueIds = _uniqueNonEmptyTextIds(textIds);
    if (uniqueIds.isEmpty) {
      return AddMyRecitationCollectionItemsResponse(
        collectionId: collectionId,
        addedCount: 0,
      );
    }

    _logger.debug(
      'Adding ${uniqueIds.length} chant(s) to collection $collectionId',
    );

    final payload =
        AddMyRecitationCollectionItemsRequest(textIds: uniqueIds).toJson();
    _logger.debug('POST .../items payload: $payload');

    try {
      final response = await dio.post(
        '/users/me/recitation-collections/$collectionId/items',
        data: payload,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException(
          'Unexpected /users/me/recitation-collections/items payload type',
        );
      }
      return AddMyRecitationCollectionItemsResponse.fromJson(data);
    } on DioException catch (e) {
      _logger.error(
        'Failed to add chants to collection $collectionId',
        e.error ?? e,
      );
      rethrow;
    }
  }

  /// GET /users/me/recitation-collections/{collectionId}/complete/today
  Future<MyRecitationCollectionTodayCompletionsResponse> getTodayCompletions({
    required String collectionId,
  }) async {
    final response = await dio.get(
      '/users/me/recitation-collections/$collectionId/complete/today',
      options: Options(extra: {'no_cache': true}),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Unexpected /users/me/recitation-collections/complete/today payload type',
      );
    }
    return MyRecitationCollectionTodayCompletionsResponse.fromJson(data);
  }

  /// POST /users/me/recitation-collections/{collectionId}/complete
  Future<void> completeChant({
    required String collectionId,
    required String chantId,
  }) async {
    final payload =
        CompleteMyRecitationCollectionChantRequest(chantId: chantId).toJson();

    try {
      _logger.debug(
        'Completing recitation $chantId in collection $collectionId',
      );
      final response = await dio.post(
        '/users/me/recitation-collections/$collectionId/complete',
        data: payload,
      );
      final status = response.statusCode;
      if (status == null || status < 200 || status >= 300) {
        throw FormatException(
          'Unexpected /users/me/recitation-collections/complete status: $status',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        _logger.info(
          'Recitation $chantId already completed (409) - treating as success',
        );
        return;
      }
      rethrow;
    }
  }

  /// GET /users/me/recitation-collections/{collectionId}/complete/days-count
  Future<MyRecitationCollectionCompletionDaysCountResponse>
  getCompletionDaysCount({required String collectionId}) async {
    final response = await dio.get(
      '/users/me/recitation-collections/$collectionId/complete/days-count',
      options: Options(extra: {'no_cache': true}),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Unexpected /users/me/recitation-collections/complete/days-count payload type',
      );
    }
    return MyRecitationCollectionCompletionDaysCountResponse.fromJson(data);
  }

  static List<String> _uniqueNonEmptyTextIds(List<String> textIds) {
    final seen = <String>{};
    final unique = <String>[];
    for (final raw in textIds) {
      final id = raw.trim();
      if (id.isEmpty || !seen.add(id)) continue;
      unique.add(id);
    }
    return unique;
  }
}
