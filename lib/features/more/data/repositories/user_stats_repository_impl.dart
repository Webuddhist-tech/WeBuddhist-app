import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/more/data/datasource/user_stats_local_datasource.dart';
import 'package:flutter_pecha/features/more/data/datasource/user_stats_remote_datasource.dart';
import 'package:flutter_pecha/features/more/data/models/mantra_count_model.dart';
import 'package:flutter_pecha/features/more/data/models/series_day_completed_model.dart';
import 'package:flutter_pecha/features/more/data/models/user_stats_model.dart';
import 'package:flutter_pecha/features/more/domain/entities/mantra_count.dart';
import 'package:flutter_pecha/features/more/domain/entities/series_day_completed.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/features/more/domain/repositories/user_stats_repository.dart';
import 'package:flutter_pecha/features/more/domain/usecases/get_mantra_counts_usecase.dart';
import 'package:flutter_pecha/features/more/domain/usecases/get_series_day_completed_usecase.dart';

class UserStatsRepositoryImpl implements UserStatsRepositoryInterface {
  final UserStatsRemoteDatasource remote;
  final UserStatsLocalDatasource local;
  final ScreenCacheStore store;

  UserStatsRepositoryImpl({
    required this.remote,
    required this.local,
    required this.store,
  });

  @override
  Stream<Either<Failure, SeriesDayCompletedPage>> watchSeriesDayCompleted({
    required String language,
  }) async* {
    final userId = await store.currentUserId();
    yield* _seriesDayCompletedSource(userId, language).watch();
  }

  @override
  Future<Either<Failure, SeriesDayCompletedPage>> refreshSeriesDayCompleted({
    required String language,
  }) async {
    final userId = await store.currentUserId();
    return _seriesDayCompletedSource(userId, language).refresh();
  }

  @override
  Stream<Either<Failure, MantraCountPage>> watchMantraCounts({
    required String language,
  }) async* {
    final userId = await store.currentUserId();
    yield* _mantraCountsSource(userId, language).watch();
  }

  @override
  Future<Either<Failure, MantraCountPage>> refreshMantraCounts({
    required String language,
  }) async {
    final userId = await store.currentUserId();
    return _mantraCountsSource(userId, language).refresh();
  }

  ScreenCacheSource<SeriesDayCompletedPage> _seriesDayCompletedSource(
    String? userId,
    String language,
  ) {
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.user(
        'series_day_completed',
        userId: userId,
        language: language,
      ),
      fetchJson: () => remote.fetchSeriesDayCompletedJson(language: language),
      fromJson:
          (json) =>
              SeriesDayCompletedPageModel.fromJson(
                json as Map<String, dynamic>,
              ).toEntity(),
      failureMessage: 'Failed to load series day completed',
    );
  }

  ScreenCacheSource<MantraCountPage> _mantraCountsSource(
    String? userId,
    String language,
  ) {
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.user(
        'mantra_counts',
        userId: userId,
        language: language,
      ),
      fetchJson: () => remote.fetchMantraCountsJson(language: language),
      fromJson:
          (json) =>
              MantraCountPageModel.fromJson(
                json as Map<String, dynamic>,
              ).toEntity(),
      failureMessage: 'Failed to load mantra counts',
    );
  }

  @override
  Future<Either<Failure, MantraCountPage>> getMantraCounts(
    GetMantraCountsParams params,
  ) async {
    try {
      final model = await remote.fetchMantraCounts(
        language: params.language,
        skip: params.skip,
        limit: params.limit,
      );
      return Right(model.toEntity());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get mantra counts: $e'));
    }
  }

  @override
  Future<Either<Failure, SeriesDayCompletedPage>> getSeriesDayCompleted(
    GetSeriesDayCompletedParams params,
  ) async {
    try {
      final model = await remote.fetchSeriesDayCompleted(
        language: params.language,
        skip: params.skip,
        limit: params.limit,
      );
      return Right(model.toEntity());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get series day completed: $e'));
    }
  }

  @override
  Future<Either<Failure, UserStats>> getUserStats() async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    final cached = local.readUserStats(userId);
    if (cached != null) {
      unawaited(_refreshUserStatsModel(userId));
      return Right(cached.toEntity());
    }

    try {
      final model = await _refreshUserStatsModel(userId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to get user stats'));
    }
  }

  @override
  Stream<Either<Failure, UserStats>> watchUserStats() async* {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      yield const Left(AuthenticationFailure('Not authenticated'));
      return;
    }

    final cached = local.readUserStats(userId);
    if (cached != null) yield Right(cached.toEntity());

    try {
      final refreshed = await _refreshUserStatsModel(userId);
      yield Right(refreshed.toEntity());
    } catch (e) {
      if (cached == null) {
        yield Left(_toFailure(e, 'Failed to get user stats'));
      }
    }

    await for (final _ in local.watchUserStats(userId)) {
      final latest = local.readUserStats(userId);
      if (latest != null) yield Right(latest.toEntity());
    }
  }

  @override
  Future<Either<Failure, UserStats>> refreshUserStats() async {
    final userId = await local.currentUserId();
    if (userId == null || userId.isEmpty) {
      return const Left(AuthenticationFailure('Not authenticated'));
    }

    try {
      final model = await _refreshUserStatsModel(userId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_toFailure(e, 'Failed to get user stats'));
    }
  }

  Future<UserStatsModel> _refreshUserStatsModel(String userId) async {
    final cached = local.readUserStats(userId);

    final model = await remote.fetchUserStats();
    if (cached?.toEntity() != model.toEntity()) {
      await local.saveUserStats(userId, model);
    }
    return model;
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
