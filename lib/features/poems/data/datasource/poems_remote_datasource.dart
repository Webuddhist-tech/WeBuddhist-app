import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/poems/data/models/poem_model.dart';

/// Result of a `GET /poems` call: the page of poems plus enough information
/// to know whether another page is worth requesting.
class PoemsPageResult {
  final List<PoemModel> poems;
  final bool hasMore;

  const PoemsPageResult({required this.poems, required this.hasMore});
}

/// Remote source for the public Poems API (`/poems`, `/poems/{poem_id}`).
///
/// Fully public — no auth header is sent (the path isn't listed in
/// [ProtectedRoutes]).
class PoemsRemoteDatasource {
  PoemsRemoteDatasource({required this.dio});

  final Dio dio;
  final _logger = AppLogger('PoemsRemoteDatasource');

  Future<PoemsPageResult> fetchPoems({
    required String language,
    int skip = 0,
    int limit = 20,
    String? chapterName,
    String? authorName,
  }) async {
    final data = await fetchPoemsJson(
      language: language,
      skip: skip,
      limit: limit,
      chapterName: chapterName,
      authorName: authorName,
    );
    return parsePage(data, skip: skip, limit: limit);
  }

  /// Raw page as served, so the screen cache stores exactly what the API sent.
  Future<Object> fetchPoemsJson({
    required String language,
    int skip = 0,
    int limit = 20,
    String? chapterName,
    String? authorName,
    bool noCache = false,
  }) async {
    try {
      final response = await dio.get(
        '/poems',
        queryParameters: {
          'language': language,
          'skip': skip,
          'limit': limit,
          if (chapterName != null && chapterName.isNotEmpty)
            'chapter_name': chapterName,
          if (authorName != null && authorName.isNotEmpty)
            'author_name': authorName,
        },
        options: noCache ? Options(extra: {'no_cache': true}) : null,
      );

      if (response.statusCode == 200) {
        return response.data ?? const <dynamic>[];
      }
      _logger.error('Failed to load poems: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to load poems');
    } on DioException catch (e) {
      _logger.error('Dio error in fetchPoems', e);
      throw _dioToException(e, 'Failed to load poems');
    }
  }

  Future<PoemModel> fetchPoem(String poemId) async {
    try {
      final response = await dio.get(
        '/poems/${Uri.encodeComponent(poemId)}',
      );

      if (response.statusCode == 200) {
        return PoemModel.fromJson(response.data as Map<String, dynamic>);
      }
      _logger.error('Failed to load poem $poemId: ${response.statusCode}');
      throw _statusToException(response.statusCode, 'Failed to load poem');
    } on DioException catch (e) {
      _logger.error('Dio error in fetchPoem', e);
      throw _dioToException(e, 'Failed to load poem');
    }
  }

  /// Tolerates a bare array (`[...]`) or a wrapped envelope
  /// (`{ "poems"|"items"|"results"|"data": [...], "total"?: n }`) since the
  /// exact list envelope isn't guaranteed by the contract.
  static PoemsPageResult parsePage(
    Object? data, {
    required int skip,
    required int limit,
  }) {
    List<dynamic> list;
    int? total;

    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      list =
          (data['poems'] as List<dynamic>?) ??
          (data['items'] as List<dynamic>?) ??
          (data['results'] as List<dynamic>?) ??
          (data['data'] as List<dynamic>?) ??
          const [];
      final totalRaw = data['total'] ?? data['count'];
      if (totalRaw is int) total = totalRaw;
      if (totalRaw is String) total = int.tryParse(totalRaw);
    } else {
      list = const [];
    }

    final poems =
        list
            .whereType<Map<String, dynamic>>()
            .map(PoemModel.fromJson)
            .toList();

    final loadedThrough = skip + poems.length;
    final hasMore =
        total != null ? loadedThrough < total : poems.length >= limit;

    return PoemsPageResult(poems: poems, hasMore: hasMore);
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 404) {
      return const NotFoundException('Poem not found');
    } else if (statusCode == 422) {
      return const ValidationException('Invalid poem request');
    } else if (statusCode == 429) {
      return const RateLimitException('Too many requests');
    } else {
      return ServerException('$label: $statusCode');
    }
  }

  Exception _dioToException(DioException e, String label) {
    if (e.error is Exception) return e.error as Exception;

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
