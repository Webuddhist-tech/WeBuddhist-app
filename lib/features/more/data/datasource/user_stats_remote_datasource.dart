import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/more/data/models/mantra_count_model.dart';
import 'package:flutter_pecha/features/more/data/models/series_day_completed_model.dart';
import 'package:flutter_pecha/features/more/data/models/user_stats_model.dart';

class UserStatsRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('UserStatsRemoteDatasource');

  UserStatsRemoteDatasource({required this.dio});

  Future<MantraCountPageModel> fetchMantraCounts({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    return MantraCountPageModel.fromJson(
      await fetchMantraCountsJson(language: language, skip: skip, limit: limit),
    );
  }

  /// Raw page as served, so the screen cache stores exactly what the API sent.
  Future<Map<String, dynamic>> fetchMantraCountsJson({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/users/me/mantra-counts',
        queryParameters: {
          'language': language,
          'skip': skip,
          'limit': limit,
        },
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      _logger.error('Failed to load mantra counts: ${response.statusCode}');
      throw _statusToException(
        response.statusCode,
        'Failed to load mantra counts',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchMantraCounts', e);
      throw _dioToException(e, 'Failed to load mantra counts');
    }
  }

  Future<SeriesDayCompletedPageModel> fetchSeriesDayCompleted({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    return SeriesDayCompletedPageModel.fromJson(
      await fetchSeriesDayCompletedJson(
        language: language,
        skip: skip,
        limit: limit,
      ),
    );
  }

  /// Raw page as served, so the screen cache stores exactly what the API sent.
  Future<Map<String, dynamic>> fetchSeriesDayCompletedJson({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/users/me/series/day-completed',
        queryParameters: {
          'language': language,
          'skip': skip,
          'limit': limit,
        },
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      _logger.error(
        'Failed to load series day completed: ${response.statusCode}',
      );
      throw _statusToException(
        response.statusCode,
        'Failed to load series day completed',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchSeriesDayCompleted', e);
      throw _dioToException(e, 'Failed to load series day completed');
    }
  }

  Future<UserStatsModel> fetchUserStats() async {
    try {
      final response = await dio.get(
        '/users/me/stats',
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return UserStatsModel.fromJson(response.data as Map<String, dynamic>);
      }

      _logger.error('Failed to load user stats: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to load user stats');
    } on DioException catch (e) {
      _logger.error('Dio error in fetchUserStats', e);
      throw _dioToException(e, 'Failed to load user stats');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('User stats not found');
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
