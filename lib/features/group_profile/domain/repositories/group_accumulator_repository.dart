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

  Future<Either<Failure, void>> joinGroupAccumulator(String accumulatorId);

  Future<Either<Failure, void>> deleteGroupAccumulator(String groupAccumulatorId);

  Future<Either<Failure, GroupAccumulatorMembersPage>> getGroupAccumulatorMembers(
    String accumulatorId, {
    required int skip,
    required int limit,
    required GroupAccumulatorMemberSort sortBy,
  });
}
