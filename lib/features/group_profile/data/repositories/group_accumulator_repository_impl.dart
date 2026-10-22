import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_accumulator_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_accumulator_repository.dart';

class GroupAccumulatorRepositoryImpl
    implements GroupAccumulatorRepositoryInterface {
  final GroupAccumulatorRemoteDatasource remote;

  GroupAccumulatorRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, GroupAccumulatorsPage>> getGroupAccumulators(
    String groupId, {
    required int skip,
    required int limit,
    required String language,
  }) async {
    try {
      final model = await remote.fetchGroupAccumulators(
        groupId,
        skip: skip,
        limit: limit,
        language: language,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load group accumulators: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupAccumulatorDetail>> getGroupAccumulator(
    String accumulatorId, {
    required String language,
  }) async {
    try {
      final model = await remote.fetchGroupAccumulator(
        accumulatorId,
        language: language,
      );
      return Right(model.toDetailEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load group accumulator: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> joinGroupAccumulator(
    String accumulatorId,
  ) async {
    try {
      await remote.joinGroupAccumulator(accumulatorId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to join group accumulator: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroupAccumulator(
    String groupAccumulatorId,
  ) async {
    try {
      await remote.deleteGroupAccumulator(groupAccumulatorId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Failed to end group accumulator session: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, GroupAccumulatorMembersPage>>
  getGroupAccumulatorMembers(
    String accumulatorId, {
    required int skip,
    required int limit,
    required GroupAccumulatorMemberSort sortBy,
  }) async {
    try {
      final model = await remote.fetchGroupAccumulatorMembers(
        accumulatorId,
        skip: skip,
        limit: limit,
        sortBy: sortBy,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Failed to load group accumulator members: $e'),
      );
    }
  }
}
