import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';

abstract class GroupAccumulatorRepositoryInterface {
  Future<Either<Failure, GroupAccumulatorsPage>> getGroupAccumulators(
    String groupId, {
    required int skip,
    required int limit,
    required String language,
  });

  Future<Either<Failure, GroupAccumulatorDetail>> getGroupAccumulator(
    String accumulatorId, {
    required String language,
  });

  ScreenCacheSource<GroupAccumulatorsPage> groupAccumulatorsSource(
    String groupId, {
    required String language,
    required int limit,
  });

  ScreenCacheSource<GroupAccumulatorDetail> groupAccumulatorDetailSource(
    String accumulatorId, {
    required String language,
  });

  Stream<Either<Failure, GroupAccumulatorsPage>> watchGroupAccumulators(
    String groupId, {
    required String language,
    required int limit,
  });

  Stream<Either<Failure, GroupAccumulatorDetail>> watchGroupAccumulator(
    String accumulatorId, {
    required String language,
  });

  Future<Either<Failure, GroupAccumulatorDetail>> refreshGroupAccumulator(
    String accumulatorId, {
    required String language,
  });

  /// Stored first page; `getGroupAccumulatorMembers(skip: 0)` writes it.
  GroupAccumulatorMembersPage? readStoredGroupAccumulatorMembers(
    String accumulatorId, {
    required GroupAccumulatorMemberSort sortBy,
  });

  Future<Either<Failure, void>> joinGroupAccumulator(String accumulatorId);

  Future<Either<Failure, void>> deleteGroupAccumulator(String groupAccumulatorId);

  Future<Either<Failure, GroupAccumulatorMembersPage>> getGroupAccumulatorMembers(
    String accumulatorId, {
    required int skip,
    required int limit,
    required GroupAccumulatorMemberSort sortBy,
  });
}
