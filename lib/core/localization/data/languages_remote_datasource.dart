import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

/// Fetches the list of content languages the backend can serve.
///
/// Endpoint: GET /languages -> `{ "languages": [ { code, name, native_name,
/// enabled }, ... ] }`.
class LanguagesRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('LanguagesRemoteDatasource');

  LanguagesRemoteDatasource({required this.dio});

  Future<List<AppLanguage>> fetchLanguages({
    bool recitationOnly = false,
  }) async {
    try {
      final response = await dio.get(
        '/languages',
        queryParameters:
            recitationOnly ? const {'recitation_only': true} : null,
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Tolerate both a wrapped object ({ "languages": [...] }) and a bare
        // array, so a backend contract tweak does not break the app.
        final List<dynamic> list =
            data is Map<String, dynamic>
                ? (data['languages'] as List<dynamic>? ?? const [])
                : (data as List<dynamic>? ?? const []);

        final languages =
            list
                .whereType<Map<String, dynamic>>()
                .map(AppLanguage.fromJson)
                .where((lang) => lang.code.isNotEmpty && lang.enabled)
                .toList();

        return languages;
      }

      _logger.error('Failed to load languages: ${response.statusCode}');
      throw ServerException('Failed to load languages: ${response.statusCode}');
    } on DioException catch (e) {
      _logger.error('Dio error in fetchLanguages', e);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException('No internet connection');
      } else if (e.response?.statusCode != null) {
        throw ServerException(
          'Failed to load languages: ${e.response!.statusCode}',
        );
      }
      throw const NetworkException('Network error');
    }
  }

  /// Upserts the authenticated user's language for notification targeting.
  ///
  /// Endpoint: PUT /users/me/language
  /// Body: `{ "language": "BO" }` (uppercase LanguageCodeEnum).
  /// Local codes are lowercase (`bo`); the API expects uppercase (`BO`).
  Future<void> updateLanguage(String languageCode) async {
    final apiCode = languageCode.trim().toUpperCase();
    if (apiCode.isEmpty) return;

    try {
      await dio.put('/users/me/language', data: {'language': apiCode});
      _logger.info('User language synced: $apiCode');
    } on DioException catch (e) {
      _logger.error('Dio error in updateLanguage', e);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException('No internet connection');
      } else if (e.response?.statusCode != null) {
        throw ServerException(
          'Failed to update language: ${e.response!.statusCode}',
        );
      }
      throw const NetworkException('Network error');
    }
  }
}
