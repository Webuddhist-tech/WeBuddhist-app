import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_remote_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/repositories/mala_repository.dart';

class MalaRepositoryImpl implements MalaRepository {
  MalaRepositoryImpl({required this.remote, this.local});

  final MalaRemoteDataSource remote;
  final MalaLocalDataSource? local;

  @override
  Future<Either<Failure, List<Mantra>>> getCatalogue({
    String? language,
    String? search,
  }) async {
    final cacheLanguage = language ?? 'en';
    final canUseLocal = search == null || search.trim().isEmpty;
    final cached = canUseLocal ? local?.readCatalogue(cacheLanguage) : null;
    if (cached != null) {
      unawaited(_refreshCatalogue(cacheLanguage));
      return Right(cached.map((preset) => preset.toEntity()).toList());
    }

    try {
      final presets = await remote.fetchPresets(
        language: language,
        search: search,
      );
      if (canUseLocal) {
        await local?.writeCatalogue(cacheLanguage, presets);
      }
      return Right(presets.map((p) => p.toEntity()).toList());
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to load catalogue: $e'));
    }
  }

  Future<void> _refreshCatalogue(String language) async {
    final presets = await remote.fetchPresets(language: language);
    await local?.writeCatalogue(language, presets);
  }

  @override
  Future<Either<Failure, MalaCount>> getAccumulatorDetail(
    String parentId,
  ) async {
    try {
      final detail = await remote.fetchAccumulatorDetail(parentId);
      // No accumulator yet for this preset — seed at 0, lazily create later.
      return Right(detail?.toMalaCount() ?? const MalaCount(total: 0));
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to load accumulator detail: $e'));
    }
  }

  @override
  Future<Either<Failure, MalaCount>> createUserAccumulator(
    String parentId,
  ) async {
    try {
      final created = await remote.createUserAccumulator(parentId);
      return Right(created.toMalaCount());
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to create accumulator: $e'));
    }
  }

  @override
  Future<Either<Failure, MalaCount>> updateUserAccumulator({
    required String accumulatorId,
    required int currentCount,
  }) async {
    try {
      final updated = await remote.updateUserAccumulator(
        accumulatorId: accumulatorId,
        currentCount: currentCount,
      );
      return Right(updated.toMalaCount());
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to update accumulator: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteUserAccumulator(
    String accumulatorId,
  ) async {
    try {
      await remote.deleteUserAccumulator(accumulatorId);
      return const Right(unit);
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to delete accumulator: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AccumulatorGroup>>> getJoinedAccumulatorGroups(
    String accumulatorId, {
    String? language,
  }) async {
    try {
      final groups = await remote.fetchAccumulatorGroups(
        accumulatorId,
        joinedOnly: true,
        language: language,
      );
      return Right(groups.map((group) => group.toEntity()).toList());
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to load accumulator groups: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> submitGroupAccumulatorCount({
    required String groupAccumulatorId,
    required int currentCount,
  }) async {
    try {
      await remote.submitGroupCount(groupAccumulatorId, currentCount);
      return const Right(unit);
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to submit group count: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteGroupAccumulator(
    String groupAccumulatorId,
  ) async {
    try {
      await remote.deleteGroupAccumulator(groupAccumulatorId);
      return const Right(unit);
    } on AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(UnknownFailure('Failed to delete group accumulator: $e'));
    }
  }

  Failure _toFailure(AppException e) {
    if (e is AuthenticationException) return AuthenticationFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    if (e is RateLimitException) return RateLimitFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) return ServerFailure(e.message);
    return UnknownFailure(e.message);
  }
}
