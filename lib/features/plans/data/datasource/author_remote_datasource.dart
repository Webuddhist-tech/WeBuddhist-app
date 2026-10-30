import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';
import '../models/author/author_model.dart';

class AuthorRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('AuthorRemoteDatasource');

  AuthorRemoteDatasource({required this.dio});

  // Helper method to handle Dio errors
  Never _throwDioException(DioException e, String defaultMessage) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw const NetworkException('Connection timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      throw const NetworkException('No internet connection');
    } else if (e.response?.statusCode != null) {
      final statusCode = e.response!.statusCode!;
      if (statusCode == 401) {
        throw const AuthenticationException('Unauthorized');
      } else if (statusCode == 403) {
        throw const AuthorizationException('Forbidden');
      } else if (statusCode == 404) {
        throw const NotFoundException('Resource not found');
      } else if (statusCode == 429) {
        throw const RateLimitException('Too many requests');
      } else {
        throw ServerException('$defaultMessage: $statusCode');
      }
    } else {
      throw const NetworkException('Network error');
    }
  }

  Future<AuthorModel> getAuthorById(String authorId) async {
    return AuthorModel.fromJson(await fetchAuthorJson(authorId));
  }

  /// Raw author as served, so the screen cache stores exactly what the API sent.
  Future<Map<String, dynamic>> fetchAuthorJson(String authorId) async {
    try {
      final response = await dio.get(
        '/authors/$authorId',
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        _logger.error('Error to load author: ${response.statusCode}');
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 403) {
          throw const AuthorizationException('Forbidden');
        } else if (response.statusCode == 404) {
          throw const NotFoundException('Author not found');
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to load author: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      _throwDioException(e, 'Failed to load author');
    }
  }

  // gets plans by author id
  Future<List<PlansModel>> getPlansByAuthorId(String authorId) async {
    try {
      final response = await dio.get('/authors/$authorId/plans');
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data['plans'] as List<dynamic>;
        return jsonData
            .map((json) => PlansModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _logger.error('Failed to load plans: ${response.statusCode}');
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 403) {
          throw const AuthorizationException('Forbidden');
        } else if (response.statusCode == 404) {
          throw const NotFoundException('Plans not found');
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to load plans: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      _throwDioException(e, 'Failed to load plans');
    }
  }
}
