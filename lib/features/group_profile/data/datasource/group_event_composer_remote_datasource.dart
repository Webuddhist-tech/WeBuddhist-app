import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_request_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_cms_item.dart';
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

  /// What an event can link to, from the same CMS lists the studio's pickers
  /// read: published plans and series (partner series included), the group's
  /// chant collections and its accumulators.
  Future<List<GroupEventPracticePick>> fetchPracticeOptions(
    String groupId,
  ) async {
    try {
      final results = await Future.wait([
        _fetchContent(groupId),
        _fetchCollections(groupId),
        _fetchAccumulators(groupId),
      ]);
      return [for (final list in results) ...list];
    } on DioException catch (e) {
      _logger.error('Dio error in fetchPracticeOptions', e);
      throw _dioToException(e, 'Failed to load practices');
    }
  }

  Future<List<GroupEventPracticePick>> _fetchContent(String groupId) async {
    const pageSize = 50;
    final picks = <GroupEventPracticePick>[];
    for (var page = 1; page <= 4; page++) {
      final response = await dio.get(
        '/cms/dashboard/items',
        queryParameters: {
          'tab': 'all',
          'group_id': groupId,
          'status': 'PUBLISHED',
          'include_partner_groups': true,
          'page': page,
          'page_size': pageSize,
        },
        options: Options(extra: {'no_cache': true}),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) break;
      final items =
          (data['items'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();
      for (final item in items) {
        final id = item['id'] as String? ?? '';
        if (id.isEmpty) continue;
        final kind =
            (item['type'] as String? ?? '').toLowerCase() == 'series'
                ? GroupEventPracticeKind.series
                : GroupEventPracticeKind.plan;
        picks.add(
          GroupEventPracticePick(
            id: id,
            kind: kind,
            title: _dashboardTitle(item),
            imageUrl: _imageUrl(item),
          ),
        );
      }
      final pagination = data['pagination'];
      final totalPages =
          pagination is Map<String, dynamic>
              ? (pagination['total_pages'] as num?)?.toInt() ?? 1
              : 1;
      if (items.isEmpty || page >= totalPages) break;
    }
    return picks;
  }

  Future<List<GroupEventPracticePick>> _fetchCollections(String groupId) async {
    final picks = <GroupEventPracticePick>[];
    await _paginate('/cms/author/groups/$groupId/recitation-collections', (
      data,
    ) {
      final items =
          (data['collections'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>();
      for (final item in items) {
        final id = item['id'] as String? ?? '';
        if (id.isEmpty) continue;
        picks.add(
          GroupEventPracticePick(
            id: id,
            kind: GroupEventPracticeKind.collection,
            title: (item['name'] as String? ?? '').trim(),
            imageUrl: item['img_url'] as String?,
          ),
        );
      }
      return items.length;
    });
    return picks;
  }

  Future<List<GroupEventPracticePick>> _fetchAccumulators(
    String groupId,
  ) async {
    final picks = <GroupEventPracticePick>[];
    await _paginate('/cms/groups/$groupId/accumulators', (data) {
      final items =
          (data['accumulators'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>();
      for (final item in items) {
        final id = item['id'] as String? ?? '';
        if (id.isEmpty) continue;
        picks.add(
          GroupEventPracticePick(
            id: id,
            kind: GroupEventPracticeKind.accumulator,
            title: (item['title'] as String? ?? '').trim(),
            imageUrl: _imageUrl(item),
          ),
        );
      }
      return items.length;
    });
    return picks;
  }

  /// Walks a skip/limit list; [consume] returns how many rows a page held.
  Future<void> _paginate(
    String path,
    int Function(Map<String, dynamic> data) consume,
  ) async {
    const limit = 50;
    const maxItems = 300;
    var skip = 0;
    while (skip < maxItems) {
      final response = await dio.get(
        path,
        queryParameters: {'skip': skip, 'limit': limit},
        options: Options(extra: {'no_cache': true}),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) break;
      final count = consume(data);
      final total = (data['total'] as num?)?.toInt() ?? skip + count;
      skip += count;
      if (count == 0 || skip >= total) break;
    }
  }

  /// A plan carries `title`; a series may only have per-language metadata.
  static String _dashboardTitle(Map<String, dynamic> item) {
    final title = (item['title'] as String?)?.trim();
    if (title != null && title.isNotEmpty) return title;
    final metadata = item['metadata'];
    final rows =
        metadata is List
            ? metadata.whereType<Map<String, dynamic>>().toList()
            : metadata is Map<String, dynamic>
            ? [metadata]
            : const <Map<String, dynamic>>[];
    for (final row in rows) {
      final value = (row['title'] as String?)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  static String? _imageUrl(Map<String, dynamic> item) {
    final direct = (item['image_url'] as String?)?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final image = item['image'];
    if (image is Map<String, dynamic>) {
      for (final key in const ['thumbnail', 'medium', 'original']) {
        final value = (image[key] as String?)?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return null;
  }

  /// Every event of the group as the CMS sees it, drafts included. The
  /// title follows [language]; the request stays unfiltered so `raw` keeps
  /// every language for editing.
  Future<List<GroupEventCmsItem>> fetchCmsEvents(
    String groupId, {
    required String language,
  }) async {
    const limit = 50;
    const maxItems = 200;
    final items = <GroupEventCmsItem>[];
    var skip = 0;
    try {
      while (items.length < maxItems) {
        final response = await dio.get(
          '/cms/events',
          queryParameters: {'group_id': groupId, 'skip': skip, 'limit': limit},
          options: Options(extra: {'no_cache': true}),
        );
        final data = response.data;
        if (data is! Map<String, dynamic>) break;
        final page =
            (data['events'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .toList();
        for (final json in page) {
          items.add(GroupEventCmsItem.fromJson(json, language: language));
        }
        final total = (data['total'] as num?)?.toInt() ?? items.length;
        skip += page.length;
        if (page.isEmpty || skip >= total) break;
      }
      return items;
    } on DioException catch (e) {
      _logger.error('Dio error in fetchCmsEvents', e);
      throw _dioToException(e, 'Failed to load events');
    }
  }

  Future<GroupEventModel> updateEvent(
    String eventId,
    CreateGroupEventRequest request,
  ) async {
    try {
      final response = await dio.put(
        '/cms/events/$eventId',
        data: request.toJson()..remove('group_id'),
      );
      final data = response.data;
      if (data is! Map<String, dynamic> ||
          (data['id'] as String? ?? '').isEmpty) {
        throw const ServerException('Event update returned no id');
      }
      return GroupEventModel.fromJson(data);
    } on DioException catch (e) {
      _logger.error('Dio error in updateEvent', e);
      throw _dioToException(e, 'Failed to update event');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await dio.delete('/cms/events/$eventId');
    } on DioException catch (e) {
      _logger.error('Dio error in deleteEvent', e);
      throw _dioToException(e, 'Failed to delete event');
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
