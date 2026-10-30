import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_accumulator_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_accumulator_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_accumulator_repository.dart';

class GroupAccumulatorRepositoryImpl
    implements GroupAccumulatorRepositoryInterface {
  final GroupAccumulatorRemoteDatasource remote;
  final ScreenCacheStore store;

  GroupAccumulatorRepositoryImpl({required this.remote, required this.store});

  ScreenCacheSource<T> _userSource<T extends Object>(
    String screen, {
    String language = '',
    List<String> params = const [],
    required Future<Map<String, dynamic>> Function() fetchJson,
    required T Function(Map<String, dynamic> json) parse,
    required String failureMessage,
  }) {
    final userId = store.currentUserIdSync;
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.user(
        screen,
        userId: userId,
        language: language,
        params: params,
      ),
      fetchJson: fetchJson,
      fromJson: (json) => parse(json as Map<String, dynamic>),
      failureMessage: failureMessage,
    );
  }

  @override
  Stream<Either<Failure, GroupAccumulatorsPage>> watchGroupAccumulators(
    String groupId, {
    required String language,
    required int limit,
  }) {
    return groupAccumulatorsSource(
      groupId,
      language: language,
      limit: limit,
    ).watch();
  }

  @override
  ScreenCacheSource<GroupAccumulatorsPage> groupAccumulatorsSource(
    String groupId, {
    required String language,
    required int limit,
  }) {
    return _userSource(
      'group_accumulators',
      language: language,
      params: [groupId],
      fetchJson:
          () => remote.fetchGroupAccumulatorsJson(
            groupId,
            skip: 0,
            limit: limit,
            language: language,
          ),
      parse: (json) => GroupAccumulatorsPageModel.fromJson(json).toEntity(),
      failureMessage: 'Failed to load group accumulators',
    );
  }

  ScreenCacheSource<GroupAccumulatorDetail> _detailSource(
    String accumulatorId,
    String language,
  ) {
    return _userSource(
      'group_accumulator',
      language: language,
      params: [accumulatorId],
      fetchJson:
          () => remote.fetchGroupAccumulatorJson(
            accumulatorId,
            language: language,
          ),
      parse: (json) => GroupAccumulatorModel.fromJson(json).toDetailEntity(),
      failureMessage: 'Failed to load group accumulator',
    );
  }

  @override
  ScreenCacheSource<GroupAccumulatorDetail> groupAccumulatorDetailSource(
    String accumulatorId, {
    required String language,
  }) {
    return _detailSource(accumulatorId, language);
  }

  @override
  Stream<Either<Failure, GroupAccumulatorDetail>> watchGroupAccumulator(
    String accumulatorId, {
    required String language,
  }) {
    return _detailSource(accumulatorId, language).watch();
  }

  @override
  Future<Either<Failure, GroupAccumulatorDetail>> refreshGroupAccumulator(
    String accumulatorId, {
    required String language,
  }) {
    return _detailSource(accumulatorId, language).refresh();
  }

  @override
  GroupAccumulatorMembersPage? readStoredGroupAccumulatorMembers(
    String accumulatorId, {
    required GroupAccumulatorMemberSort sortBy,
  }) {
    final source = _membersSource(accumulatorId, limit: 20, sortBy: sortBy);
    return source.read();
  }

  ScreenCacheSource<GroupAccumulatorMembersPage> _membersSource(
    String accumulatorId, {
    required int limit,
    required GroupAccumulatorMemberSort sortBy,
  }) {
    return _userSource(
      'group_accumulator_members',
      params: [accumulatorId, sortBy.name],
      fetchJson:
          () => remote.fetchGroupAccumulatorMembersJson(
            accumulatorId,
            skip: 0,
            limit: limit,
            sortBy: sortBy,
          ),
      parse:
          (json) => GroupAccumulatorMembersPageModel.fromJson(json).toEntity(),
      failureMessage: 'Failed to load group accumulator members',
    );
  }

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
    if (skip == 0) {
      final source = _membersSource(
        accumulatorId,
        limit: limit,
        sortBy: sortBy,
      );
      return source.refresh();
    }
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
