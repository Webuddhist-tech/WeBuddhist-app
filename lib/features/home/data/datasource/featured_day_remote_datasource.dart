import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/plans/data/models/response/featured_day_response.dart';

class FeaturedDayRemoteDatasource {
  final Dio dio;

  FeaturedDayRemoteDatasource({required this.dio});

  Future<FeaturedDayResponse> fetchFeaturedDay({String? language}) async {
    try {
      final response = await dio.get(
        '/plans/featured/day',
        queryParameters: language != null ? {'language': language} : null,
      );

      if (response.statusCode == 200) {
        return FeaturedDayResponse.fromJson(response.data);
      } else {
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 404) {
          // Return empty response instead of throwing for 404
          return FeaturedDayResponse.fromJson({
            'id': '',
            'day_number': 0,
            'tasks': [],
          });
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to fetch featured day: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
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
        } else if (statusCode == 404) {
          // Return empty response instead of throwing for 404
          return FeaturedDayResponse.fromJson({
            'id': '',
            'day_number': 0,
            'tasks': [],
          });
        } else if (statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to fetch featured day: $statusCode');
        }
      } else {
        throw const NetworkException('Network error');
      }
    }
  }
}
