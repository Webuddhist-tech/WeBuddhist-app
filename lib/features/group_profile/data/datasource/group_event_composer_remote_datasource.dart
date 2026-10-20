import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_request_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';

/// CMS endpoints the event composer writes to, as the studio does.
class GroupEventComposerRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('GroupEventComposerRemoteDatasource');

  GroupEventComposerRemoteDatasource({required this.dio});

  Future<List<GroupEventIntention>> fetchIntentions() async {
    try {
      final response = await dio.get('/cms/intentions');
      final data = response.data;
      final list =
          data is Map<String, dynamic>
              ? (data['intentions'] as List<dynamic>? ?? const [])
              : (data as List<dynamic>? ?? const []);
      final intentions = <GroupEventIntention>[];
      for (final item in list.whereType<Map<String, dynamic>>()) {
        final id = item['id'] as String? ?? '';
        if (id.isEmpty) continue;
        intentions.add(
          GroupEventIntention(
            id: id,
            slug: item['slug'] as String? ?? '',
            label: item['label'] as String? ?? item['slug'] as String? ?? id,
          ),
        );
      }
      return intentions;
    } on DioException catch (e) {
      _logger.error('Dio error in fetchIntentions', e);
      throw _dioToException(e, 'Failed to load intentions');
    }
  }

  /// Returns the new location's id.
  Future<String> createLocation(
    String groupId,
    CreateGroupLocationRequest request,
  ) async {
    try {
      final response = await dio.post(
        '/cms/author/groups/$groupId/locations',
        data: request.toJson(),
      );
      final data = response.data;
      final id = data is Map<String, dynamic> ? data['id'] as String? : null;
      if (id == null || id.isEmpty) {
        throw const ServerException('Location create returned no id');
      }
      return id;
    } on DioException catch (e) {
      _logger.error('Dio error in createLocation', e);
      throw _dioToException(e, 'Failed to create location');
    }
  }

  Future<GroupEventModel> createEvent(CreateGroupEventRequest request) async {
    try {
      final response = await dio.post('/cms/events', data: request.toJson());
      final data = response.data;
      if (data is! Map<String, dynamic> ||
          (data['id'] as String? ?? '').isEmpty) {
        throw const ServerException('Event create returned no id');
      }
      return GroupEventModel.fromJson(data);
    } on DioException catch (e) {
      _logger.error('Dio error in createEvent', e);
      throw _dioToException(e, 'Failed to create event');
    }
  }

  Exception _dioToException(DioException e, String label) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Connection timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      return const NetworkException('No internet connection');
    }
    final status = e.response?.statusCode;
    if (status == null) return const NetworkException('Network error');
    if (status == 401) return const AuthenticationException('Unauthorized');
    if (status == 403) return const AuthorizationException('Forbidden');
    if (status == 404) return const NotFoundException('Not found');
    if (status == 429) return const RateLimitException('Too many requests');
    // Validation errors carry the reason; keep it for the snackbar.
    final body = e.response?.data;
    final detail =
        body is Map<String, dynamic> ? body['detail'] ?? body['message'] : null;
    return ServerException(
      detail is String && detail.isNotEmpty ? detail : '$label: $status',
    );
  }
}
