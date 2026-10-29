import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/home_local_datasource.dart';
import 'package:flutter_pecha/features/home/data/datasource/routine_info_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/entities/routine_info.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';

class RoutineInfoRepository implements RoutineInfoRepositoryInterface {
  final RoutineInfoRemoteDatasource remote;
  final HomeLocalDatasource local;

  RoutineInfoRepository({required this.remote, required this.local});

  @override
  Future<Either<Failure, RoutineInfo>> getRoutineInfo() async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    final cached = local.readRoutineInfo(userId);
    if (cached != null) {
      unawaited(_refresh(userId));
      return Right(cached.toEntity());
    }

    try {
      final model = await remote.fetchRoutineInfo();
      await local.saveRoutineInfo(userId, model);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to get routine info'));
    }
  }

  @override
  Stream<Either<Failure, RoutineInfo>> watchRoutineInfo() async* {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      yield const Left(AuthenticationFailure('Not authenticated'));
      return;
    }

    final key = local.routineInfoKey(userId);
    final cached = local.readRoutineInfo(userId);
    if (cached != null) yield Right(cached.toEntity());

    try {
      await _refresh(userId);
      final refreshed = local.readRoutineInfo(userId);
      if (refreshed != null) yield Right(refreshed.toEntity());
    } catch (e) {
      if (cached == null) {
        yield Left(_toFailure(e, 'Failed to get routine info'));
      }
    }

    await for (final _ in local.watchKey(key)) {
      final latest = local.readRoutineInfo(userId);
      if (latest != null) yield Right(latest.toEntity());
    }
  }

  @override
  Future<Either<Failure, Unit>> refreshRoutineInfo() async {
    final userId = local.currentUserIdSync ?? await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }
    try {
      await _refresh(userId);
      return const Right(unit);
    } catch (e) {
      return Left(_toFailure(e, 'Failed to refresh routine info'));
    }
  }

  Future<void> _refresh(String userId) async {
    final model = await remote.fetchRoutineInfo();
    await local.saveRoutineInfo(userId, model);
  }

  Failure _toFailure(Object error, String fallback) {
    if (error is AuthenticationException) {
      return AuthenticationFailure(error.message);
    }
    if (error is ServerException) return ServerFailure(error.message);
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is RateLimitException) return RateLimitFailure(error.message);
    return UnknownFailure('$fallback: $error');
  }
}
