import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/datasource/my_recitation_collections_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';

class MyRecitationCollectionsRepository {
  final MyRecitationCollectionsRemoteDatasource remoteDatasource;

  MyRecitationCollectionsRepository({required this.remoteDatasource});

  Future<Either<Failure, MyRecitationCollectionImageUploadResponse>>
  uploadImage(File file) async {
    try {
      final result = await remoteDatasource.uploadImage(file);
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to upload collection image'),
      );
    }
  }

  Future<Either<Failure, MyRecitationCollectionModel>> createCollection({
    required String name,
    required String imgUrl,
  }) async {
    try {
      final result = await remoteDatasource.createCollection(
        CreateMyRecitationCollectionRequest(name: name, imgUrl: imgUrl),
      );
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to create collection'),
      );
    }
  }

  Future<Either<Failure, MyRecitationCollectionDetailModel>>
  getCollectionDetail(String collectionId) async {
    try {
      final result = await remoteDatasource.getCollectionDetail(collectionId);
      return Right(result);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Failed to load collection'));
    }
  }

  Future<Either<Failure, void>> deleteCollection(String collectionId) async {
    try {
      await remoteDatasource.deleteCollection(collectionId);
      return const Right(null);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to delete collection'),
      );
    }
  }

  Future<Either<Failure, MyRecitationCollectionModel>> updateCollection({
    required String collectionId,
    required String name,
    String? imgUrl,
  }) async {
    try {
      final result = await remoteDatasource.updateCollection(
        collectionId: collectionId,
        request: UpdateMyRecitationCollectionRequest(
          name: name,
          imgUrl: imgUrl,
        ),
      );
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to update collection'),
      );
    }
  }

  Future<Either<Failure, void>> deleteCollectionItem({
    required String collectionId,
    required String itemId,
  }) async {
    try {
      await remoteDatasource.deleteCollectionItem(
        collectionId: collectionId,
        itemId: itemId,
      );
      return const Right(null);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to remove chant from collection'),
      );
    }
  }

  Future<Either<Failure, MyRecitationCollectionItemModel>>
  updateCollectionItemDisplayOrder({
    required String collectionId,
    required String itemId,
    required double displayOrder,
  }) async {
    try {
      final result = await remoteDatasource.updateCollectionItemDisplayOrder(
        collectionId: collectionId,
        itemId: itemId,
        displayOrder: displayOrder,
      );
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(
          e,
          context: 'Failed to reorder chant in collection',
        ),
      );
    }
  }

  Future<Either<Failure, AddMyRecitationCollectionItemsResponse>>
  addItemsToCollection({
    required String collectionId,
    required List<String> textIds,
  }) async {
    try {
      final result = await remoteDatasource.addItemsToCollection(
        collectionId: collectionId,
        textIds: textIds,
      );
      return Right(result);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to add chants to collection'),
      );
    }
  }

  Future<Either<Failure, Set<String>>> getTodayCompletions(
    String collectionId,
  ) async {
    try {
      final result = await remoteDatasource.getTodayCompletions(
        collectionId: collectionId,
      );
      return Right(result.completedChantIds);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to load completed recitations'),
      );
    }
  }

  Future<Either<Failure, void>> completeChant({
    required String collectionId,
    required String chantId,
  }) async {
    try {
      await remoteDatasource.completeChant(
        collectionId: collectionId,
        chantId: chantId,
      );
      return const Right(null);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to complete recitation'),
      );
    }
  }

  Future<Either<Failure, int>> getCompletionDaysCount(
    String collectionId,
  ) async {
    try {
      final result = await remoteDatasource.getCompletionDaysCount(
        collectionId: collectionId,
      );
      return Right(result.dayCount);
    } catch (e) {
      return Left(
        ExceptionMapper.map(e, context: 'Failed to load completion day count'),
      );
    }
  }

  /// Creates a collection (unless [existingCollectionId] is set), then adds
  /// [textIds] when non-empty.
  ///
  /// If the collection row is already persisted but adding chants fails, returns
  /// [PartialCollectionCreateFailure] so callers can retry items without creating
  /// a duplicate collection.
  ///
  /// On such a retry the row already exists and [name] / [imgUrl] are **not**
  /// written — there is no update call on this path — so callers must lock
  /// metadata edits once they hold a collection id. The row is read back so
  /// the returned model reflects the server and only missing chants are added.
  Future<Either<Failure, MyRecitationCollectionModel>>
  createCollectionWithItems({
    required String name,
    required String imgUrl,
    required List<String> textIds,
    String? existingCollectionId,
  }) async {
    final MyRecitationCollectionModel collection;
    var idsToAdd = textIds;

    final existingId = existingCollectionId?.trim();
    if (existingId != null && existingId.isNotEmpty) {
      final detailResult = await getCollectionDetail(existingId);
      collection = detailResult.fold(
        // Detail unavailable: keep the id so the retry still targets the
        // persisted row rather than creating another one.
        (_) => MyRecitationCollectionModel(
          id: existingId,
          name: name,
          imgUrl: imgUrl,
        ),
        (detail) => MyRecitationCollectionModel(
          id: detail.id.isNotEmpty ? detail.id : existingId,
          name: detail.name,
          imgUrl: detail.imgUrl,
          createdAt: detail.createdAt,
          updatedAt: detail.updatedAt,
        ),
      );
      final alreadyPresent = detailResult.fold<Set<String>?>(
        (_) => null,
        (detail) => detail.items.map((item) => item.textId).toSet(),
      );
      if (alreadyPresent != null) {
        idsToAdd = textIds.where((id) => !alreadyPresent.contains(id)).toList();
      }
    } else {
      final createResult = await createCollection(name: name, imgUrl: imgUrl);
      final created = createResult.fold<MyRecitationCollectionModel?>(
        (_) => null,
        (c) => c,
      );
      if (created == null) {
        return createResult;
      }
      collection = created;
    }

    if (idsToAdd.isEmpty) return Right(collection);
    if (collection.id.isEmpty) {
      return const Left(
        ServerFailure('Failed to create collection: missing collection id'),
      );
    }

    final addResult = await addItemsToCollection(
      collectionId: collection.id,
      textIds: idsToAdd,
    );
    return addResult.fold(
      (failure) => Left(
        PartialCollectionCreateFailure(
          'Collection was created but chants could not be added: '
          '${failure.message}',
          collectionId: collection.id,
        ),
      ),
      (_) => Right(collection),
    );
  }
}
