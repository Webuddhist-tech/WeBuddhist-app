import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/home_local_datasource.dart';
import 'package:flutter_pecha/features/home/data/datasource/today_events_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/entities/today_event.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';

class TodayEventsRepository implements TodayEventsRepositoryInterface {
  final TodayEventsRemoteDatasource remote;
  final HomeLocalDatasource local;

  TodayEventsRepository({required this.remote, required this.local});

  @override
  Future<Either<Failure, List<TodayEvent>>> getTodayEvents({
    required String language,
  }) async {
    final cached = local.readTodayEvents(language);
    if (cached != null) {
      unawaited(_refresh(language));
      return Right(cached.map((model) => model.toEntity()).toList());
    }

    try {
      final models = await remote.fetchTodayEvents(language: language);
      await local.saveTodayEvents(language, models);
      return Right(models.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to get today events'));
    }
  }

  @override
  Stream<Either<Failure, List<TodayEvent>>> watchTodayEvents({
    required String language,
  }) async* {
    final key = local.todayEventsKey(language);
    final cached = local.readTodayEvents(language);
    if (cached != null) {
      yield Right(cached.map((model) => model.toEntity()).toList());
    }

    try {
      await _refresh(language);
      final refreshed = local.readTodayEvents(language);
      if (refreshed != null) {
        yield Right(refreshed.map((model) => model.toEntity()).toList());
      }
    } catch (e) {
      if (cached == null) {
        yield Left(_toFailure(e, 'Failed to get today events'));
      }
    }

    await for (final _ in local.watchKey(key)) {
      final latest = local.readTodayEvents(language);
      if (latest != null) {
        yield Right(latest.map((model) => model.toEntity()).toList());
      }
    }
  }

  @override
  Future<Either<Failure, Unit>> refreshTodayEvents({
    required String language,
  }) async {
    try {
      await _refresh(language);
      return const Right(unit);
    } catch (e) {
      return Left(_toFailure(e, 'Failed to refresh today events'));
    }
  }

  Future<void> _refresh(String language) async {
    final models = await remote.fetchTodayEvents(language: language);
    await local.saveTodayEvents(language, models);
  }

  Failure _toFailure(Object error, String fallback) {
    if (error is ServerException) return ServerFailure(error.message);
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is RateLimitException) return RateLimitFailure(error.message);
    return UnknownFailure('$fallback: $error');
  }
}
