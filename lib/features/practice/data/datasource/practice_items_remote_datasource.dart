import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/practice/data/models/practice_item_model.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_items_tab.dart';

class PracticeItemsRemoteDatasource {
  final Dio _dio;
  final _logger = AppLogger('PracticeItemsRemoteDatasource');

  PracticeItemsRemoteDatasource({required Dio dio}) : _dio = dio;

  /// Endpoint: GET /practice/items
  /// Returns a paginated list of practice-addable items (plans + series).
  Future<PracticeItemsResponseModel> fetchPracticeItems({
    required PracticeItemsTab tab,
    required String language,
    required int page,
    required int pageSize,
  }) async {
    return PracticeItemsResponseModel.fromJson(
      await fetchPracticeItemsJson(
        tab: tab,
        language: language,
        page: page,
        pageSize: pageSize,
      ),
    );
  }

  /// Raw page as served, so the screen cache stores exactly what the API sent.
  Future<Map<String, dynamic>> fetchPracticeItemsJson({
    required PracticeItemsTab tab,
    required String language,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio.get(
        '/practice/items',
        queryParameters: {
          'tab': tab.toQueryValue(),
          'language': language,
          'page': page,
          'page_size': pageSize,
        },
        options: Options(extra: {'no_cache': true}),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        _logger.error('Unexpected /practice/items payload type: ${data.runtimeType}');
        throw const ServerException('Invalid response from /practice/items');
      }
      return data;
    } on DioException catch (e) {
      _logger.error('Dio error in fetchPracticeItems', e);
      throw _dioToException(e, 'Failed to load practice items');
    }
  }

  Exception _dioToException(DioException e, String label) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Connection timeout');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException('No internet connection');
    }
    final status = e.response?.statusCode;
    if (status == 401) return const AuthenticationException('Unauthorized');
    if (status == 404) return const NotFoundException('Practice items not found');
    if (status == 429) return const RateLimitException('Too many requests');
    return ServerException('$label: ${status ?? 'unknown error'}');
  }
}
