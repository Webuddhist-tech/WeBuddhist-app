import 'package:dio/dio.dart';

/// Home preview of the user's upcoming group events (`GET /events`).
class HomeEventsRemoteDatasource {
  HomeEventsRemoteDatasource({required this.dio});

  final Dio dio;

  /// Raw page as served, so the screen cache stores exactly what the API sent.
  Future<Map<String, dynamic>> fetchPreviewJson({
    required String language,
    required int limit,
  }) async {
    final response = await dio.get(
      '/events',
      queryParameters: {'skip': 0, 'limit': limit, 'language': language},
      options: Options(extra: {'no_cache': true}),
    );
    return response.data as Map<String, dynamic>;
  }
}
