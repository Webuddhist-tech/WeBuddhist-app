import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/mala/data/models/accumulator_group_model.dart';
import 'package:flutter_pecha/features/mala/data/models/accumulator_model.dart';

class MalaRemoteDataSource {
  MalaRemoteDataSource({required this.dio});

  final Dio dio;
  final _logger = AppLogger('MalaRemoteDataSource');

  static const int _pageSize = 100;

  /// `GET /accumulators/presets` — preset accumulators (catalogue). Pages all.
  /// [language] localizes the embedded mantra title/text/pronunciation.
  /// [search] filters presets server-side by name when non-empty.
  Future<List<PresetAccumulatorModel>> fetchPresets({
    String? language,
    String? search,
  }) async {
    final query = search?.trim();
    try {
      final all = <PresetAccumulatorModel>[];
      var skip = 0;
      while (true) {
        final response = await dio.get(
          '/accumulators/presets',
          queryParameters: {
            'skip': skip,
            'limit': _pageSize,
            if (language != null) 'language': language,
            if (query != null && query.isNotEmpty) 'search': query,
          },
        );
        if (response.statusCode != 200) {
          throw _statusToException(
            response.statusCode,
            'Failed to load presets',
          );
        }
        final page = PresetAccumulatorsResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        all.addAll(page.accumulators);
        skip += _pageSize;
        if (page.accumulators.length < _pageSize || all.length >= page.total) {
          break;
        }
      }
      return all;
    } on DioException catch (e) {
      _logger.error('Dio error in fetchPresets', e);
      throw _dioToException(e, 'Failed to load presets');
    }
  }

  /// `GET /accumulators/{accumulator_id}/groups` — groups using this preset.
  /// [language] localizes each row's group name and event title.
  Future<List<AccumulatorGroupModel>> fetchAccumulatorGroups(
    String accumulatorId, {
    bool joinedOnly = false,
    String? language,
  }) async {
    try {
      final response = await dio.get(
        '/accumulators/$accumulatorId/groups',
        queryParameters: {
          'joined_only': joinedOnly,
          if (language != null) 'language': language,
        },
        options: Options(extra: {'no_cache': true}),
      );
      if (response.statusCode == 200) {
        return AccumulatorGroupsResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        ).groups;
      }
      throw _statusToException(
        response.statusCode,
        'Failed to load accumulator groups',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchAccumulatorGroups', e);
      throw _dioToException(e, 'Failed to load accumulator groups');
    }
  }

  /// `GET /accumulators/{parent_id}` — the user's detail for one preset.
  ///
  /// Returns `null` when the user has no accumulator for this preset yet
  /// (the endpoint 404s), so the caller can seed at 0 and lazily create.
  /// After reset (soft-delete), expect `accumulator_id: null` and
  /// `current_count: 0`; `total_counted` retains lifetime history only.
  Future<AccumulatorDetailModel?> fetchAccumulatorDetail(
    String parentId,
  ) async {
    try {
      final response = await dio.get(
        '/accumulators/$parentId',
        options: Options(extra: {'no_cache': true}),
      );
      if (response.statusCode == 200) {
        return AccumulatorDetailModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      if (response.statusCode == 404) return null;
      throw _statusToException(response.statusCode, 'Failed to load detail');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _logger.error('Dio error in fetchAccumulatorDetail', e);
      throw _dioToException(e, 'Failed to load detail');
    }
  }

  /// `POST /accumulators/user` — create the user's accumulator for a preset.
  /// Body is `{parent_id}`. Used lazily on first sync after counting starts.
  Future<AccumulatorModel> createUserAccumulator(String parentId) async {
    try {
      final response = await dio.post(
        '/accumulators/user',
        data: {'parent_id': parentId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AccumulatorModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw _statusToException(
        response.statusCode,
        'Failed to create accumulator',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in createUserAccumulator', e);
      throw _dioToException(e, 'Failed to create accumulator');
    }
  }

  /// `PUT /accumulators/user/{id}` — push the absolute lifetime total.
  Future<AccumulatorModel> updateUserAccumulator({
    required String accumulatorId,
    required int currentCount,
  }) async {
    try {
      final response = await dio.put(
        '/accumulators/user/$accumulatorId',
        data: {'current_count': currentCount},
      );
      if (response.statusCode == 200) {
        return AccumulatorModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw _statusToException(
        response.statusCode,
        'Failed to update accumulator',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in updateUserAccumulator', e);
      throw _dioToException(e, 'Failed to update accumulator');
    }
  }

  /// `DELETE /accumulators/user/{id}` — soft-delete the user's accumulator.
  Future<void> deleteUserAccumulator(String accumulatorId) async {
    try {
      final response = await dio.delete('/accumulators/user/$accumulatorId');
      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        return;
      }
      throw _statusToException(
        response.statusCode,
        'Failed to delete accumulator',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in deleteUserAccumulator', e);
      throw _dioToException(e, 'Failed to delete accumulator');
    }
  }

  /// `DELETE /group-accumulators/{group_accumulator_id}` — soft-delete the
  /// user's count for this group accumulator. Resets [current_count] to zero
  /// server-side while preserving lifetime history on the deleted record.
  Future<void> deleteGroupAccumulator(String groupAccumulatorId) async {
    try {
      final response = await dio.delete(
        '/group-accumulators/$groupAccumulatorId',
      );
      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        return;
      }
      throw _statusToException(
        response.statusCode,
        'Failed to delete group accumulator',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in deleteGroupAccumulator', e);
      throw _dioToException(e, 'Failed to delete group accumulator');
    }
  }

  /// `POST /group-accumulators/{group_accumulator_id}` — submit absolute count.
  ///
  /// Body: `{ "current_count": <int> }` ([SubmitGroupCountRequest]).
  /// Path param is [groupAccumulatorId] (`group_accumulator_id` from the groups
  /// list API), not the parent `group_id`.
  Future<void> submitGroupCount(
    String groupAccumulatorId,
    int currentCount,
  ) async {
    try {
      final response = await dio.post(
        '/group-accumulators/$groupAccumulatorId',
        data: {'current_count': currentCount},
      );
      final status = response.statusCode;
      if (status != null && status >= 200 && status < 300) return;
      throw _statusToException(status, 'Failed to submit group count');
    } on DioException catch (e) {
      _logger.error('Dio error in submitGroupCount', e);
      throw _dioToException(e, 'Failed to submit group count');
    }
  }

  Future<List<int>> fetchImageBytes(String url) async {
    try {
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      }
      throw _statusToException(response.statusCode, 'Failed to load image');
    } on DioException catch (e) {
      _logger.error('Dio error in fetchImageBytes', e);
      throw _dioToException(e, 'Failed to load image');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Not found');
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
