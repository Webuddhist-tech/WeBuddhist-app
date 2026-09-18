import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/timer/data/models/preset_timer_model.dart';

class TimersRemoteDatasource {
  TimersRemoteDatasource({required this.dio});

  final Dio dio;
  final _logger = AppLogger('TimersRemoteDatasource');

  Future<void> stopUserTimer({
    required String timerId,
    required int durationMs,
  }) async {
    try {
      final response = await dio.post(
        '/timers/user/timer_stop',
        data: {'timer_id': timerId, 'duration': durationMs},
      );

      if (response.statusCode == 201) return;

      _logger.error('Failed to stop timer: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to stop timer');
    } on DioException catch (e) {
      _logger.error('Dio error in stopUserTimer', e);
      throw _dioToException(e, 'Failed to stop timer');
    }
  }

  Future<List<PresetTimerModel>> fetchPresetTimers({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/timers',
        queryParameters: {'skip': skip, 'limit': limit},
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        final data = TimersResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return data.timers;
      }

      _logger.error('Failed to load timers: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to load timers');
    } on DioException catch (e) {
      _logger.error('Dio error in fetchPresetTimers', e);
      throw _dioToException(e, 'Failed to load timers');
    }
  }

  /// Creates a user-defined timer via `POST /timers/user`.
  ///
  /// `group_id` and `parent_preset_id` are intentionally never sent — this
  /// app has no notion of either yet.
  Future<PresetTimerModel> createUserTimer({
    required String name,
    required String description,
    required int durationMs,
    String? ambientSoundId,
    required bool bellAtStart,
    required bool bellAtEnd,
  }) async {
    try {
      final response = await dio.post(
        '/timers/user',
        data: {
          'name': name,
          'description': description,
          'duration': durationMs,
          'ambient_sound_id': ambientSoundId,
          'bell_at_start': bellAtStart,
          'bell_at_end': bellAtEnd,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PresetTimerModel.fromJson(response.data as Map<String, dynamic>);
      }

      _logger.error('Failed to create timer: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to create timer');
    } on DioException catch (e) {
      _logger.error('Dio error in createUserTimer', e);
      throw _dioToException(e, 'Failed to create timer');
    }
  }

  Future<void> deleteUserTimer({required String timerId}) async {
    try {
      final response = await dio.delete('/timers/user/$timerId');

      if (response.statusCode == 200 || response.statusCode == 204) return;

      _logger.error('Failed to delete timer: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to delete timer');
    } on DioException catch (e) {
      _logger.error('Dio error in deleteUserTimer', e);
      throw _dioToException(e, 'Failed to delete timer');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Timers not found');
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
