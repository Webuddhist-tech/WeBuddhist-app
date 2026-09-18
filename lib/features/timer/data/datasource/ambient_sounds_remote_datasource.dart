import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/timer/data/models/ambient_sound_model.dart';

class AmbientSoundsRemoteDatasource {
  AmbientSoundsRemoteDatasource({required this.dio});

  final Dio dio;
  final _logger = AppLogger('AmbientSoundsRemoteDatasource');

  Future<List<AmbientSoundModel>> fetchAmbientSounds() async {
    try {
      final response = await dio.get('/ambient-sounds');

      if (response.statusCode == 200) {
        final data = AmbientSoundsResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        final sounds = List<AmbientSoundModel>.from(data.sounds)
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        return sounds;
      }

      _logger.error('Failed to load ambient sounds: ${response.statusCode}');
      throw _statusToException(
        response.statusCode,
        'Failed to load ambient sounds',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchAmbientSounds', e);
      throw _dioToException(e, 'Failed to load ambient sounds');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Ambient sounds not found');
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
