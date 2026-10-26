import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/home/data/models/today_event_model.dart';

class TodayEventsRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('TodayEventsRemoteDatasource');

  TodayEventsRemoteDatasource({required this.dio});

  Future<List<TodayEventModel>> fetchTodayEvents({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/events/today',
        queryParameters: {
          'language': language,
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        return TodayEventsResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        ).events;
      }

      _logger.error('Failed to load today events: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to load today events');
    } on DioException catch (e) {
      _logger.error('Dio error in fetchTodayEvents', e);
      throw _dioToException(e, 'Failed to load today events');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Today events not found');
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
