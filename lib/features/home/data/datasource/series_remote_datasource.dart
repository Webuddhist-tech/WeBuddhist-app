import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/home/data/models/series_model.dart';

class SeriesQueryParams {
  final String language;
  final int skip;
  final int limit;
  final String? search;

  const SeriesQueryParams({
    required this.language,
    this.skip = 0,
    this.limit = 10,
    this.search,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'language': language,
      'skip': skip,
      'limit': limit,
    };
    if (search != null && search!.trim().isNotEmpty) {
      params['search'] = search!.trim();
    }
    return params;
  }
}

class SeriesRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('SeriesRemoteDatasource');

  SeriesRemoteDatasource({required this.dio});

  Future<List<SeriesModel>> fetchFeaturedSeries({
    required String language,
    int limit = 10,
  }) async {
    try {
      final response = await dio.get(
        '/series/featured',
        queryParameters: {'language': language, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> seriesJson =
            (response.data['series'] as List<dynamic>?) ?? [];
        return seriesJson
            .map((s) => SeriesModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        _logger.error('Failed to load featured series: ${response.statusCode}');
        throw _statusToException(
          response.statusCode,
          'Failed to load featured series',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchFeaturedSeries', e);
      throw _dioToException(e, 'Failed to load featured series');
    }
  }

  /// Endpoint: GET /series?language={language}&skip={skip}&limit={limit}&search={search}
  Future<List<SeriesModel>> fetchSeries({
    required SeriesQueryParams params,
  }) async {
    try {
      final response = await dio.get(
        '/series',
        queryParameters: params.toQueryParams(),
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> seriesJson =
            (response.data['series'] as List<dynamic>?) ?? [];
        return seriesJson
            .map((s) => SeriesModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        _logger.error('Failed to load series: ${response.statusCode}');
        throw _statusToException(response.statusCode, 'Failed to load series');
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchSeries', e);
      throw _dioToException(e, 'Failed to load series');
    }
  }

  /// Endpoint: GET /series?language={language}
  Future<List<SeriesModel>> fetchSeriesList({required String language}) async {
    try {
      final response = await dio.get(
        '/series',
        queryParameters: {'language': language},
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> seriesJson =
            (response.data['series'] as List<dynamic>?) ?? [];
        return seriesJson
            .map((s) => SeriesModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        _logger.error('Failed to load series list: ${response.statusCode}');
        throw _statusToException(response.statusCode, 'Failed to load series');
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchSeriesList', e);
      throw _dioToException(e, 'Failed to load series');
    }
  }

  /// Endpoint: GET /series/{id}?language={language}
  Future<SeriesModel> fetchSeriesById(
    String id, {
    required String language,
  }) async {
    try {
      final response = await dio.get(
        '/series/$id',
        queryParameters: {'language': language},
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return SeriesModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        _logger.error('Failed to load series $id: ${response.statusCode}');
        throw _statusToException(response.statusCode, 'Failed to load series');
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchSeriesById', e);
      throw _dioToException(e, 'Failed to load series');
    }
  }

  /// Endpoint: POST /users/me/series
  /// Enrolls the authenticated user in a series. Backend auto-enrolls the
  /// user in every plan that belongs to the series.
  Future<void> enrollInSeries(String seriesId, {String? groupId}) async {
    try {
      final data = <String, dynamic>{'series_id': seriesId};
      if (groupId != null && groupId.isNotEmpty) {
        data['group_id'] = groupId;
      }

      final response = await dio.post('/users/me/series', data: data);
      final status = response.statusCode ?? 0;
      if (status == 204 || (status >= 200 && status < 300)) return;
      _logger.error('Failed to enroll in series $seriesId: $status');
      throw _enrollStatusToException(status);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 409 || status == 204) return;
      _logger.error('Dio error in enrollInSeries', e);
      if (status != null) throw _enrollStatusToException(status);
      throw _dioToException(e, 'Failed to enroll in series');
    }
  }

  /// Like [_statusToException], but tells apart the answers that mean the
  /// server will never accept this enrollment (400, 403, 422), so the offline
  /// queue can drop them instead of retrying forever.
  Exception _enrollStatusToException(int status) {
    const label = 'Failed to enroll in series';
    if (status == 400 || status == 422) {
      return ValidationException('$label: $status');
    }
    if (status == 403) return AuthorizationException('$label: $status');
    return _statusToException(status, label);
  }

  /// Endpoint: GET /users/me/series
  /// Returns the set of series IDs the authenticated user is enrolled in.
  ///
  /// The response shape is parsed defensively: it accepts either a top-level
  /// list, a `{ "series": [...] }` envelope, or a `{ "enrollments": [...] }`
  /// envelope, and pulls the series id from either `series_id` or `id` on
  /// each item.
  Future<Set<String>> fetchUserSeriesEnrollments() async {
    try {
      final response = await dio.get('/users/me/series');

      if (response.statusCode == 200) {
        return _extractSeriesIds(response.data);
      } else {
        _logger.error(
          'Failed to load user series enrollments: ${response.statusCode}',
        );
        throw _statusToException(
          response.statusCode,
          'Failed to load user series enrollments',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchUserSeriesEnrollments', e);
      throw _dioToException(e, 'Failed to load user series enrollments');
    }
  }

  Set<String> _extractSeriesIds(dynamic data) {
    List<dynamic>? items;
    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic>) {
      items =
          (data['series'] as List<dynamic>?) ??
          (data['enrollments'] as List<dynamic>?);
    }
    if (items == null) return const <String>{};

    final ids = <String>{};
    for (final raw in items) {
      if (raw is String && raw.isNotEmpty) {
        ids.add(raw);
      } else if (raw is Map<String, dynamic>) {
        final id = (raw['series_id'] ?? raw['id']);
        if (id is String && id.isNotEmpty) ids.add(id);
      }
    }
    return ids;
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Series not found');
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
