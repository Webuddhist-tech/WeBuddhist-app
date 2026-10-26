import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_accumulator_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';

class GroupAccumulatorRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('GroupAccumulatorRemoteDatasource');

  GroupAccumulatorRemoteDatasource({required this.dio});

  Future<GroupAccumulatorsPageModel> fetchGroupAccumulators(
    String groupId, {
    required int skip,
    required int limit,
    required String language,
  }) async {
    try {
      final response = await dio.get(
        '/group-accumulators/$groupId/accumulators',
        queryParameters: {'skip': skip, 'limit': limit, 'language': language},
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return GroupAccumulatorsPageModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw _statusToException(
        response.statusCode,
        'Failed to load group accumulators',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupAccumulators', e);
      throw _dioToException(e, 'Failed to load group accumulators');
    }
  }

  Future<GroupAccumulatorModel> fetchGroupAccumulator(
    String accumulatorId, {
    required String language,
  }) async {
    try {
      final response = await dio.get(
        '/group-accumulators/$accumulatorId',
        queryParameters: {'language': language},
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return GroupAccumulatorModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw _statusToException(
        response.statusCode,
        'Failed to load group accumulator',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupAccumulator', e);
      throw _dioToException(e, 'Failed to load group accumulator');
    }
  }

  /// `DELETE /group-accumulators/{group_accumulator_id}` — end the user's
  /// active chant session (204 No Content on success).
  Future<void> deleteGroupAccumulator(String groupAccumulatorId) async {
    try {
      final response = await dio.delete(
        '/group-accumulators/$groupAccumulatorId',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw _statusToException(
        response.statusCode,
        'Failed to end group accumulator session',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in deleteGroupAccumulator', e);
      throw _dioToException(e, 'Failed to end group accumulator session');
    }
  }

  Future<void> joinGroupAccumulator(String accumulatorId) async {
    try {
      final response = await dio.post('/group-accumulators/$accumulatorId/join');
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw _statusToException(
          response.statusCode,
          'Failed to join group accumulator',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in joinGroupAccumulator', e);
      throw _dioToException(e, 'Failed to join group accumulator');
    }
  }

  Future<GroupAccumulatorMembersPageModel> fetchGroupAccumulatorMembers(
    String accumulatorId, {
    required int skip,
    required int limit,
    required GroupAccumulatorMemberSort sortBy,
  }) async {
    try {
      final response = await dio.get(
        '/group-accumulators/$accumulatorId/members',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          'sort_by': sortBy == GroupAccumulatorMemberSort.today ? 'today' : 'total',
        },
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return GroupAccumulatorMembersPageModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw _statusToException(
        response.statusCode,
        'Failed to load group accumulator members',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupAccumulatorMembers', e);
      throw _dioToException(e, 'Failed to load group accumulator members');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Group accumulator not found');
    } else if (statusCode == 429) {
      return const RateLimitException('Too many requests');
    } else {
      return ServerException('$label: $statusCode');
    }
  }

  Exception _dioToException(DioException e, String label) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Connection timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      return const NetworkException('No internet connection');
    } else if (e.response?.statusCode != null) {
      return _statusToException(e.response!.statusCode, label);
    } else {
      return const NetworkException('Network error');
    }
  }
}
