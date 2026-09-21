import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/timer/data/datasource/timers_local_datasource.dart';
import 'package:flutter_pecha/features/timer/data/datasource/timers_remote_datasource.dart';
import 'package:flutter_pecha/features/timer/data/models/preset_timer_model.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/domain/repositories/timers_repository.dart';

class TimersRepository implements TimersRepositoryInterface {
  TimersRepository({required this.remote, required this.local});

  final TimersRemoteDatasource remote;
  final TimersLocalDatasource local;

  @override
  Future<Either<Failure, void>> stopUserTimer({
    required String timerId,
    required int durationMs,
  }) async {
    try {
      final userId = await local.currentUserId();
      if (userId == null || userId.isEmpty) {
        return const Left(AuthenticationFailure('Not authenticated'));
      }

      await local.enqueueTimerStop(
        userId,
        timerId: timerId,
        durationMs: durationMs,
      );
      await flushPendingTimerStops();
      return const Right(null);
    } on AuthenticationException {
      return const Right(null);
    } on ServerException {
      return const Right(null);
    } on NetworkException {
      return const Right(null);
    } on NotFoundException {
      return const Right(null);
    } on RateLimitException {
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Failed to stop timer: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PresetTimer>>> getPresetTimers({
    int skip = 0,
    int limit = 20,
  }) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    final cached = local.readPresetTimers(userId, skip: skip, limit: limit);
    if (cached != null) {
      unawaited(refreshPresetTimers(skip: skip, limit: limit));
      return Right(cached.map((timer) => timer.toEntity()).toList());
    }

    return refreshPresetTimers(skip: skip, limit: limit);
  }

  @override
  Stream<Either<Failure, List<PresetTimer>>> watchPresetTimers({
    int skip = 0,
    int limit = 20,
  }) async* {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      yield const Left(AuthenticationFailure('Not authenticated'));
      return;
    }

    final key = local.presetTimersKey(userId, skip, limit);
    List<PresetTimer>? read() {
      return local
          .readPresetTimers(userId, skip: skip, limit: limit)
          ?.map((timer) => timer.toEntity())
          .toList();
    }

    final cached = read();
    if (cached != null) yield Right(cached);

    try {
      final timers = await remote.fetchPresetTimers(skip: skip, limit: limit);
      await local.savePresetTimers(
        userId,
        skip: skip,
        limit: limit,
        timers: timers,
      );
      final refreshed = read();
      if (refreshed != null) yield Right(refreshed);
    } catch (e) {
      if (cached == null) {
        yield Left(_toFailure(e, 'Failed to get preset timers'));
      }
    }

    await for (final _ in local.watchKey(key)) {
      final latest = read();
      if (latest != null) yield Right(latest);
    }
  }

  @override
  Future<Either<Failure, List<PresetTimer>>> refreshPresetTimers({
    int skip = 0,
    int limit = 20,
  }) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    try {
      final timers = await remote.fetchPresetTimers(skip: skip, limit: limit);
      await local.savePresetTimers(
        userId,
        skip: skip,
        limit: limit,
        timers: timers,
      );
      return Right(timers.map((timer) => timer.toEntity()).toList());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to get preset timers'));
    }
  }

  @override
  Future<Either<Failure, PresetTimer>> createUserTimer({
    required String name,
    required String description,
    required int durationMs,
    String? ambientSoundId,
  }) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    final PresetTimerModel created;
    try {
      created = await remote.createUserTimer(
        name: name,
        description: description,
        durationMs: durationMs,
        ambientSoundId: ambientSoundId,
        // Always on — the backend defaults these to true as well.
        bellAtStart: true,
        bellAtEnd: true,
      );
    } catch (e) {
      return Left(_toFailure(e, 'Failed to create timer'));
    }

    // The server has committed at this point, so nothing below may turn the
    // creation into a failure: a retry would create a duplicate timer.
    try {
      // Write it into the cached list first so it shows up under "Your timers"
      // via the Hive box watch.
      await local.upsertPresetTimer(userId, timer: created);
      // Best-effort resync with the server ordering.
      await refreshPresetTimers();
    } catch (_) {
      // Cache is stale until the next refresh, but the timer exists remotely.
    }
    return Right(created.toEntity());
  }

  @override
  Future<Either<Failure, void>> deleteUserTimer({
    required String timerId,
  }) async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    try {
      await remote.deleteUserTimer(timerId: timerId);
    } catch (e) {
      return Left(_toFailure(e, 'Failed to delete timer'));
    }

    // The timer is gone on the server at this point, so nothing below may
    // report the delete as failed: a retry would target a missing timer.
    try {
      // Drop it from the cache ourselves so "Your timers" updates through the
      // Hive box watch even when the resync below fails.
      await local.removePresetTimer(userId, timerId);
      // Best-effort resync with the server.
      await refreshPresetTimers();
    } catch (_) {
      // Cache is stale until the next refresh, but the timer is already gone
      // remotely.
    }
    return const Right(null);
  }

  @override
  Future<void> flushPendingTimerStops() async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) return;

    final pending = local.readPendingStops(userId);
    for (final stop in pending) {
      try {
        await remote.stopUserTimer(
          timerId: stop.timerId,
          durationMs: stop.durationMs,
        );
        await local.removePendingStop(userId, stop.id);
      } on NotFoundException {
        // Permanent rejection (endpoint/timer gone) — retrying never succeeds,
        // so drop the queued stop instead of re-attempting it on every resume.
        await local.removePendingStop(userId, stop.id);
      } catch (_) {
        // Transient failure (network/server) — stop here and retry next flush.
        return;
      }
    }
  }

  Failure _toFailure(Object error, String fallback) {
    if (error is ServerException) return ServerFailure(error.message);
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is AuthenticationException) {
      return AuthenticationFailure(error.message);
    }
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is RateLimitException) return RateLimitFailure(error.message);
    return UnknownFailure('$fallback: $error');
  }
}
