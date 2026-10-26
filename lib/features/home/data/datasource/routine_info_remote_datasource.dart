import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/home/data/models/routine_info_model.dart';

class RoutineInfoRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('RoutineInfoRemoteDatasource');

  RoutineInfoRemoteDatasource({required this.dio});

  Future<RoutineInfoModel> fetchRoutineInfo() async {
    try {
      final response = await dio.get('/users/me/routine/info');

      if (response.statusCode == 200) {
        return RoutineInfoModel.fromJson(response.data as Map<String, dynamic>);
      }

      _logger.error('Failed to load routine info: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to load routine info');
    } on DioException catch (e) {
      // Backend returns 400 (not 404) when the user has never created a
      // routine yet — same business rule as /users/me/routine, see
      // RoutineRemoteDatasource.getUserRoutine. Treat it as zero counts
      // rather than a hard error.
      if (e.response?.statusCode == 400) {
        final msg = _extractMessage(e)?.toLowerCase() ?? '';
        if (msg.contains('no routine')) {
          _logger.info('No routine for user – treating info as empty');
          return const RoutineInfoModel(seriesCount: 0, recitationCount: 0);
        }
      }
      _logger.error('Dio error in fetchRoutineInfo', e);
      throw _dioToException(e, 'Failed to load routine info');
    }
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is Map<String, dynamic>) {
        return detail['message'] as String?;
      }
      return (data['message'] ?? data['error']) as String?;
    }
    return null;
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Routine info not found');
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
