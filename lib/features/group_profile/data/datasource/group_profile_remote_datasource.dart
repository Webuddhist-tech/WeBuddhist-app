import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_member_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_notification_preferences_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_practice_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_profile_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

/// Marker carried by the failure raised when a chant completion is rejected
/// because the user only follows the group instead of having joined it.
const String noGroupMembershipCode = 'NO_GROUP_MEMBERSHIP';

class GroupProfileRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('GroupProfileRemoteDatasource');

  GroupProfileRemoteDatasource({required this.dio});

  Future<GroupProfileModel> fetchGroupProfile(
    String groupId, {
    required String language,
  }) async {
    try {
      final response = await dio.get(
        '/author/groups/$groupId',
        queryParameters: {'language': language},
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return GroupProfileModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        _logger.error(
          'Failed to load group profile $groupId: ${response.statusCode}',
        );
        throw _statusToException(
          response.statusCode,
          'Failed to load group profile',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupProfile', e);
      throw _dioToException(e, 'Failed to load group profile');
    }
  }

  Future<void> followGroup(String groupId, GroupType groupType) async {
    final action = groupType.isPage ? 'follow' : 'join';
    try {
      final response = await dio.post('/author/groups/$groupId/$action');
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw _statusToException(
          response.statusCode,
          groupType.isPage ? 'Failed to follow group' : 'Failed to join group',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in followGroup', e);
      throw _dioToException(
        e,
        groupType.isPage ? 'Failed to follow group' : 'Failed to join group',
      );
    }
  }

  static String _notificationPreferencesPath(String groupId) =>
      '/users/me/notification-preferences/groups/$groupId';

  /// `GET /users/me/notification-preferences/groups/{groupId}`.
  ///
  /// 404 means the caller is not a member; the repository maps it to
  /// [NotFoundFailure] so the UI can fall back to defaults. The `PUSH`
  /// channel is the backend default, so it is not sent.
  Future<GroupNotificationPreferencesModel> fetchGroupNotificationPreferences(
    String groupId,
  ) async {
    try {
      final response = await dio.get(
        _notificationPreferencesPath(groupId),
        options: Options(extra: {'no_cache': true}),
      );
      if (response.statusCode == 200) {
        return GroupNotificationPreferencesModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw _statusToException(
        response.statusCode,
        'Failed to load group notification preferences',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupNotificationPreferences', e);
      throw _dioToException(e, 'Failed to load group notification preferences');
    }
  }

  /// `PATCH /users/me/notification-preferences/groups/{groupId}`.
  ///
  /// The body is a merge: only the types behind the toggles that were passed
  /// are sent, so flipping one toggle never overwrites the other. Returns
  /// the full per-group state the backend now holds.
  Future<GroupNotificationPreferencesModel> updateGroupNotificationPreferences(
    String groupId, {
    bool? chat,
    bool? content,
  }) async {
    try {
      final response = await dio.patch(
        _notificationPreferencesPath(groupId),
        data: GroupNotificationPreferencesModel.toRequestJson(
          chat: chat,
          content: content,
        ),
      );
      if (response.statusCode == 200) {
        return GroupNotificationPreferencesModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw _statusToException(
        response.statusCode,
        'Failed to update group notification preferences',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in updateGroupNotificationPreferences', e);
      throw _dioToException(
        e,
        'Failed to update group notification preferences',
      );
    }
  }

  Future<bool> checkFollowStatus(String groupId, GroupType groupType) async {
    final path =
        groupType.isPage
            ? '/users/me/following/author/groups'
            : '/users/me/joined/author/groups';
    try {
      final response = await dio.get(
        path,
        queryParameters: {'group_id': groupId, 'skip': 0, 'limit': 20},
        options: Options(
          extra: {'no_cache': true},
          validateStatus: (status) => status == 200 || status == 404,
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      _logger.error('Dio error in checkFollowStatus', e);
      throw _dioToException(
        e,
        groupType.isPage
            ? 'Failed to check follow status'
            : 'Failed to check join status',
      );
    }
  }

  Future<GroupPracticesPageModel> fetchPractices({
    String? groupId,
    required bool includeUnfollowed,
    required String language,
    required int skip,
    required int limit,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'language': language,
        'skip': skip,
        'limit': limit,
      };
      if (groupId != null) {
        queryParameters['group_id'] = groupId;
      }
      if (includeUnfollowed) {
        queryParameters['include_unfollowed'] = true;
      }

      final response = await dio.get(
        '/author/groups/practices',
        queryParameters: queryParameters,
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return GroupPracticesPageModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      _logger.error(
        'Failed to load practices${groupId != null ? ' for $groupId' : ''}: ${response.statusCode}',
      );
      throw _statusToException(
        response.statusCode,
        'Failed to load group practices',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchPractices', e);
      throw _dioToException(e, 'Failed to load group practices');
    }
  }

  Future<GroupRecitationCollectionModel> fetchRecitationCollectionDetail({
    required String collectionId,
  }) async {
    try {
      final response = await dio.get(
        '/author/groups/recitation-collections/$collectionId',
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return GroupRecitationCollectionModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      _logger.error(
        'Failed to load recitation collection $collectionId: ${response.statusCode}',
      );
      throw _statusToException(
        response.statusCode,
        'Failed to load recitation collection',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchRecitationCollectionDetail', e);
      throw _dioToException(e, 'Failed to load recitation collection');
    }
  }

  Future<Set<String>> fetchTodayRecitationCollectionCompletions({
    required String collectionId,
  }) async {
    try {
      final response = await dio.get(
        '/users/me/groups/recitation-collections/$collectionId/complete/today',
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return (data['completed_chant_ids'] as List<dynamic>?)
                ?.whereType<String>()
                .toSet() ??
            const {};
      }

      throw _statusToException(
        response.statusCode,
        'Failed to load completed recitations',
      );
    } on DioException catch (e) {
      // Only members may track completions. A follower can still open the
      // collection, so treat the rejection as "nothing completed" instead of
      // failing the screen.
      if (e.response?.statusCode == 403) {
        _logger.info(
          'No membership for collection $collectionId — no completion ticks to show',
        );
        return const {};
      }

      _logger.error(
        'Dio error in fetchTodayRecitationCollectionCompletions',
        e,
      );
      throw _dioToException(e, 'Failed to load completed recitations');
    }
  }

  Future<int> fetchRecitationCollectionCompletionDaysCount({
    required String collectionId,
  }) async {
    try {
      final response = await dio.get(
        '/users/me/groups/recitation-collections/$collectionId/complete/days-count',
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return (data['day_count'] as num?)?.toInt() ?? 0;
      }

      throw _statusToException(
        response.statusCode,
        'Failed to load completion day count',
      );
    } on DioException catch (e) {
      _logger.error(
        'Dio error in fetchRecitationCollectionCompletionDaysCount',
        e,
      );
      throw _dioToException(e, 'Failed to load completion day count');
    }
  }

  Future<void> completeRecitationCollectionChant({
    required String collectionId,
    required String chantId,
  }) async {
    try {
      final response = await dio.post(
        '/users/me/groups/recitation-collections/$collectionId/complete',
        data: {'chant_id': chantId},
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw _statusToException(
          response.statusCode,
          'Failed to complete recitation',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        _logger.info(
          'Recitation $chantId already completed (409) — treating as success',
        );
        return;
      }

      // Followers can read a collection but only members can log completions.
      if (e.response?.statusCode == 403) {
        _logger.info(
          'Completion rejected for collection $collectionId — membership required',
        );
        throw const AuthorizationException(noGroupMembershipCode);
      }

      _logger.error('Dio error in completeRecitationCollectionChant', e);
      throw _dioToException(e, 'Failed to complete recitation');
    }
  }

  Future<GroupMembersPageModel> fetchGroupMembers(
    String groupId, {
    required int skip,
    required int limit,
  }) async {
    try {
      final response = await dio.get(
        '/author/groups/$groupId/members',
        queryParameters: {'skip': skip, 'limit': limit},
      );

      if (response.statusCode == 200) {
        return GroupMembersPageModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        _logger.error(
          'Failed to load group members $groupId: ${response.statusCode}',
        );
        throw _statusToException(
          response.statusCode,
          'Failed to load group members',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupMembers', e);
      throw _dioToException(e, 'Failed to load group members');
    }
  }

  Future<GroupEventsPageModel> fetchConnectEvents({
    required bool includeUnfollowed,
    required String language,
    int skip = 0,
    int limit = 20,
    String? eventFormat,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'skip': skip,
        'limit': limit,
        'language': language,
      };
      if (includeUnfollowed) {
        queryParameters['include_unfollowed'] = true;
      }
      if (eventFormat != null) {
        queryParameters['event_format'] = eventFormat;
      }

      final response = await dio.get(
        '/events',
        queryParameters: queryParameters,
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return GroupEventsPageModel.fromJson(
          response.data as Map<String, dynamic>,
          language: language,
        );
      } else {
        _logger.error('Failed to load connect events: ${response.statusCode}');
        throw _statusToException(response.statusCode, 'Failed to load events');
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchConnectEvents', e);
      throw _dioToException(e, 'Failed to load events');
    }
  }

  Future<GroupEventsPageModel> fetchGroupEvents(String groupId) async {
    try {
      final response = await dio.get(
        '/events',
        queryParameters: {'group_id': groupId},
        // Participant counts and join state change frequently; always fetch fresh.
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return GroupEventsPageModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        _logger.error(
          'Failed to load group events $groupId: ${response.statusCode}',
        );
        throw _statusToException(
          response.statusCode,
          'Failed to load group events',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupEvents', e);
      throw _dioToException(e, 'Failed to load group events');
    }
  }

  Future<GroupEventModel> fetchGroupEventDetail(
    String eventId, {
    required String language,
  }) async {
    try {
      final response = await dio.get(
        '/events/$eventId',
        queryParameters: {'language': language},
        // `is_joined` and `participant_count` change on every attend/leave;
        // always fetch fresh rather than risk a stale cache hit.
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return GroupEventModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        _logger.error(
          'Failed to load group event $eventId: ${response.statusCode}',
        );
        throw _statusToException(
          response.statusCode,
          'Failed to load group event',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupEventDetail', e);
      throw _dioToException(e, 'Failed to load group event');
    }
  }

  Future<GroupEventParticipantsPageModel> fetchGroupEventParticipants(
    String eventId, {
    required int skip,
    required int limit,
  }) async {
    try {
      final response = await dio.get(
        '/events/$eventId/participants',
        queryParameters: {'skip': skip, 'limit': limit},
        // Membership changes on every attend/leave; always fetch fresh.
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return GroupEventParticipantsPageModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        _logger.error(
          'Failed to load group event participants $eventId: ${response.statusCode}',
        );
        throw _statusToException(
          response.statusCode,
          'Failed to load group event participants',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupEventParticipants', e);
      throw _dioToException(e, 'Failed to load group event participants');
    }
  }

  /// Also switches an existing participation when [participationType] is set.
  Future<void> joinGroupEvent(
    String eventId, {
    GroupEventParticipationType? participationType,
  }) async {
    try {
      final response = await dio.post(
        '/events/$eventId/participants',
        data:
            participationType == null
                ? null
                : {'participation_type': participationType.apiValue},
      );
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw _statusToException(response.statusCode, 'Failed to attend event');
      }
    } on DioException catch (e) {
      _logger.error('Dio error in joinGroupEvent', e);
      throw _dioToException(e, 'Failed to attend event');
    }
  }

  Future<void> leaveGroupEvent(String eventId) async {
    try {
      final response = await dio.delete(
        '/events/$eventId/participants/me',
        options: Options(
          validateStatus: (status) => status == 204 || status == 404,
        ),
      );

      if (response.statusCode == 204) return;
      if (response.statusCode == 404 &&
          _isAlreadyNotParticipant(response.data)) {
        return;
      }

      throw _statusToException(response.statusCode, 'Failed to leave event');
    } on DioException catch (e) {
      _logger.error('Dio error in leaveGroupEvent', e);
      throw _dioToException(e, 'Failed to leave event');
    }
  }

  Future<void> submitJoinRequest(
    String groupId, {
    required String message,
  }) async {
    try {
      final response = await dio.post(
        '/author/groups/$groupId/join-requests',
        data: {'message': message},
      );
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw _statusToException(
          response.statusCode,
          'Failed to submit join request',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in submitJoinRequest', e);
      throw _dioToException(e, 'Failed to submit join request');
    }
  }

  Future<void> unfollowGroup(String groupId, GroupType groupType) async {
    final action = groupType.isPage ? 'follow' : 'join';
    try {
      final response = await dio.delete('/author/groups/$groupId/$action');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _statusToException(
          response.statusCode,
          groupType.isPage
              ? 'Failed to unfollow group'
              : 'Failed to leave group',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in unfollowGroup', e);
      throw _dioToException(
        e,
        groupType.isPage ? 'Failed to unfollow group' : 'Failed to leave group',
      );
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Group not found');
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

  bool _isAlreadyNotParticipant(Object? data) {
    if (data is! Map<String, dynamic>) return false;
    final detail = data['detail'];
    return detail is String && detail.contains('You have not joined event');
  }
}
