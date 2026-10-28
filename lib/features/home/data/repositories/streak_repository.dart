import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/home_local_datasource.dart';
import 'package:flutter_pecha/features/home/data/datasource/streak_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';

class StreakRepository implements StreakRepositoryInterface {
  final StreakRemoteDatasource remote;
  final HomeLocalDatasource local;

  StreakRepository({required this.remote, required this.local});

  @override
  Future<Either<Failure, int>> getStreak() async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    final cached = local.readStreak(userId);
    if (cached != null) {
      unawaited(_refresh(userId));
      return Right(cached);
    }

    try {
      final streak = await remote.fetchStreak();
      await local.saveStreak(userId, streak);
      return Right(streak);
    } catch (e) {
      return Left(_toFailure(e, 'Failed to get streak'));
    }
  }

  @override
  Stream<Either<Failure, int>> watchStreak() async* {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      yield const Left(AuthenticationFailure('Not authenticated'));
      return;
    }

    final key = local.streakKey(userId);
    final cached = local.readStreak(userId);
    if (cached != null) yield Right(cached);

    try {
      await _refresh(userId);
      final refreshed = local.readStreak(userId);
      if (refreshed != null) yield Right(refreshed);
    } catch (e) {
      if (cached == null) yield Left(_toFailure(e, 'Failed to get streak'));
    }

    await for (final _ in local.watchKey(key)) {
      final latest = local.readStreak(userId);
      if (latest != null) yield Right(latest);
    }
  }

  @override
  Future<Either<Failure, Unit>> refreshStreak() async {
    final userId = local.currentUserIdSync ?? await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }
    try {
      await _refresh(userId);
      return const Right(unit);
    } catch (e) {
      return Left(_toFailure(e, 'Failed to refresh streak'));
    }
  }

  Future<void> _refresh(String userId) async {
    final streak = await remote.fetchStreak();
    await local.saveStreak(userId, streak);
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
