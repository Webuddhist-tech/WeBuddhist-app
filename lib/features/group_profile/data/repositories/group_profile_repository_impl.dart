import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_profile_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_join_request_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_member_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_practice_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_profile_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_report_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_join_request.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_join_requests_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_members_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_notification_preferences.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_report.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_reports_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';

class GroupProfileRepositoryImpl implements GroupProfileRepositoryInterface {
  final GroupProfileRemoteDatasource remote;
  final ScreenCacheStore store;

  GroupProfileRepositoryImpl({required this.remote, required this.store});

  @override
  Stream<Either<Failure, GroupProfile>> watchGroupProfile(
    String groupId, {
    required String language,
  }) async* {
    final userId = await store.currentUserId();
    yield* _profileSource(groupId, userId: userId, language: language).watch();
  }

  @override
  Future<Either<Failure, GroupProfile>> refreshGroupProfile(
    String groupId, {
    required String language,
  }) async {
    final userId = await store.currentUserId();
    return _profileSource(groupId, userId: userId, language: language).refresh();
  }

  // Guests can view profiles, so a missing user id falls back to `anon`.
  ScreenCacheSource<GroupProfile> _profileSource(
    String groupId, {
    required String? userId,
    required String language,
  }) {
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.user(
        'group_profile',
        userId: userId,
        language: language,
        params: [groupId],
      ),
      fetchJson: () => remote.fetchGroupProfileJson(groupId, language: language),
      fromJson:
          (json) =>
              GroupProfileModel.fromJson(json as Map<String, dynamic>).toEntity(),
      failureMessage: 'Failed to load group profile',
    );
  }

  /// User-scoped source keyed by the signed-in user (or `anon`).
  Future<ScreenCacheSource<T>> _userSource<T extends Object>(
    String screen, {
    String language = '',
    List<String> params = const [],
    required Future<Map<String, dynamic>> Function() fetchJson,
    required T Function(Map<String, dynamic> json) parse,
    required String failureMessage,
  }) async {
    final userId = await store.currentUserId();
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.user(
        screen,
        userId: userId,
        language: language,
        params: params,
      ),
      fetchJson: fetchJson,
      fromJson: (json) => parse(json as Map<String, dynamic>),
      failureMessage: failureMessage,
    );
  }

  Future<ScreenCacheSource<GroupEventsPage>> _eventsSource(
    String groupId,
    String language,
  ) {
    return _userSource(
      'group_events',
      language: language,
      params: [groupId],
      fetchJson: () => remote.fetchGroupEventsJson(groupId, language: language),
      parse:
          (json) =>
              GroupEventsPageModel.fromJson(json, language: language).toEntity(),
      failureMessage: 'Failed to load group events',
    );
  }

  @override
  Stream<Either<Failure, GroupEventsPage>> watchGroupEvents(
    String groupId, {
    required String language,
  }) async* {
    yield* (await _eventsSource(groupId, language)).watch();
  }

  @override
  Future<Either<Failure, GroupEventsPage>> refreshGroupEvents(
    String groupId, {
    required String language,
  }) async {
    return (await _eventsSource(groupId, language)).refresh();
  }

  Future<ScreenCacheSource<GroupEvent>> _eventDetailSource(
    String eventId,
    String language,
  ) {
    return _userSource(
      'group_event',
      language: language,
      params: [eventId],
      fetchJson:
          () => remote.fetchGroupEventDetailJson(eventId, language: language),
      parse: (json) => GroupEventModel.fromJson(json).toEntity(),
      failureMessage: 'Failed to load group event',
    );
  }

  @override
  Stream<Either<Failure, GroupEvent>> watchGroupEventDetail(
    String eventId, {
    required String language,
  }) async* {
    yield* (await _eventDetailSource(eventId, language)).watch();
  }

  @override
  Future<Either<Failure, GroupEvent>> refreshGroupEventDetail(
    String eventId, {
    required String language,
  }) async {
    return (await _eventDetailSource(eventId, language)).refresh();
  }

  @override
  Stream<Either<Failure, GroupRecitationCollection>>
  watchRecitationCollectionDetail({required String collectionId}) async* {
    final source = await _userSource(
      'group_recitation_collection',
      params: [collectionId],
      fetchJson:
          () => remote.fetchRecitationCollectionDetailJson(
            collectionId: collectionId,
          ),
      parse: (json) => GroupRecitationCollectionModel.fromJson(json).toEntity(),
      failureMessage: 'Failed to load recitation collection',
    );
    yield* source.watch();
  }

  Future<ScreenCacheSource<GroupPracticesPage>> _practicesSource(
    String groupId, {
    required String language,
    required int limit,
  }) {
    return _userSource(
      'group_practices',
      language: language,
      params: [groupId],
      fetchJson:
          () => remote.fetchPracticesJson(
            groupId: groupId,
            includeUnfollowed: true,
            language: language,
            skip: 0,
            limit: limit,
          ),
      parse: (json) => GroupPracticesPageModel.fromJson(json).toEntity(),
      failureMessage: 'Failed to load group practices',
    );
  }

  Future<ScreenCacheSource<GroupMembersPage>> _membersSource(
    String groupId, {
    required int limit,
  }) {
    return _userSource(
      'group_members',
      params: [groupId],
      fetchJson:
          () => remote.fetchGroupMembersJson(groupId, skip: 0, limit: limit),
      parse: (json) => GroupMembersPageModel.fromJson(json).toEntity(),
      failureMessage: 'Failed to load group members',
    );
  }

  Future<ScreenCacheSource<GroupEventParticipantsPage>> _participantsSource(
    String eventId, {
    required int limit,
  }) {
    return _userSource(
      'group_event_participants',
      params: [eventId],
      fetchJson:
          () => remote.fetchGroupEventParticipantsJson(
            eventId,
            skip: 0,
            limit: limit,
          ),
      parse:
          (json) => GroupEventParticipantsPageModel.fromJson(json).toEntity(),
      failureMessage: 'Failed to load group event participants',
    );
  }

  Future<ScreenCacheSource<GroupJoinRequestsPage>> _joinRequestsSource(
    String groupId, {
    required int limit,
  }) {
    return _userSource(
      'group_join_requests',
      params: [groupId],
      fetchJson:
          () => remote.fetchGroupJoinRequestsJson(
            groupId,
            skip: 0,
            limit: limit,
          ),
      parse: (json) => GroupJoinRequestsPageModel.fromJson(json).toEntity(),
      failureMessage: 'Failed to load join requests',
    );
  }

  Future<ScreenCacheSource<GroupReportsPage>> _reportsSource(
    String groupId, {
    required int limit,
  }) {
    return _userSource(
      'group_reports',
      params: [groupId],
      fetchJson:
          () => remote.fetchGroupReportsJson(
            groupId,
            resolved: false,
            skip: 0,
            limit: limit,
          ),
      parse: (json) => GroupReportsPageModel.fromJson(json).toEntity(),
      failureMessage: 'Failed to load reports',
    );
  }

  static const int _firstPageLimit = 20;

  @override
  Future<GroupPracticesPage?> readStoredGroupPractices(
    String groupId, {
    required String language,
  }) async {
    final source = await _practicesSource(
      groupId,
      language: language,
      limit: _firstPageLimit,
    );
    return source.read();
  }

  @override
  Future<GroupMembersPage?> readStoredGroupMembers(String groupId) async {
    return (await _membersSource(groupId, limit: _firstPageLimit)).read();
  }

  @override
  Future<GroupEventParticipantsPage?> readStoredGroupEventParticipants(
    String eventId,
  ) async {
    return (await _participantsSource(eventId, limit: _firstPageLimit)).read();
  }

  @override
  Future<GroupJoinRequestsPage?> readStoredGroupJoinRequests(
    String groupId,
  ) async {
    return (await _joinRequestsSource(groupId, limit: _firstPageLimit)).read();
  }

  @override
  Future<GroupReportsPage?> readStoredGroupReports(String groupId) async {
    return (await _reportsSource(groupId, limit: _firstPageLimit)).read();
  }

  @override
  Future<Either<Failure, GroupProfile>> getGroupProfile(
    String groupId, {
    required String language,
  }) async {
    try {
      final model = await remote.fetchGroupProfile(groupId, language: language);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load group profile: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkFollowStatus(
    String groupId,
    GroupType groupType,
  ) async {
    try {
      final isFollowing = await remote.checkFollowStatus(groupId, groupType);
      return Right(isFollowing);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure(
          groupType.isPage
              ? 'Failed to check follow status: $e'
              : 'Failed to check join status: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> followGroup(
    String groupId,
    GroupType groupType,
  ) async {
    try {
      await remote.followGroup(groupId, groupType);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure(
          groupType.isPage
              ? 'Failed to follow group: $e'
              : 'Failed to join group: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, GroupPracticesPage>> getGroupPractices(
    String groupId, {
    required String language,
    required int skip,
    required int limit,
  }) async {
    if (skip == 0) {
      final source = await _practicesSource(
        groupId,
        language: language,
        limit: limit,
      );
      return source.refresh();
    }
    return _loadPractices(
      groupId: groupId,
      includeUnfollowed: true,
      language: language,
      skip: skip,
      limit: limit,
    );
  }

  @override
  Future<Either<Failure, GroupPracticesPage>> getConnectPractices({
    required bool includeUnfollowed,
    required String language,
    required int skip,
    required int limit,
  }) async {
    return _loadPractices(
      includeUnfollowed: includeUnfollowed,
      language: language,
      skip: skip,
      limit: limit,
    );
  }

  @override
  Future<Either<Failure, GroupRecitationCollection>>
  getRecitationCollectionDetail({required String collectionId}) async {
    try {
      final model = await remote.fetchRecitationCollectionDetail(
        collectionId: collectionId,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load recitation collection: $e'));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getTodayRecitationCollectionCompletions({
    required String collectionId,
  }) async {
    try {
      final completedChantIds = await remote
          .fetchTodayRecitationCollectionCompletions(
            collectionId: collectionId,
          );
      return Right(completedChantIds);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load completed recitations: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> completeRecitationCollectionChant({
    required String collectionId,
    required String chantId,
  }) async {
    try {
      await remote.completeRecitationCollectionChant(
        collectionId: collectionId,
        chantId: chantId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to complete recitation: $e'));
    }
  }

  Future<Either<Failure, GroupPracticesPage>> _loadPractices({
    String? groupId,
    required bool includeUnfollowed,
    required String language,
    required int skip,
    required int limit,
  }) async {
    try {
      final model = await remote.fetchPractices(
        groupId: groupId,
        includeUnfollowed: includeUnfollowed,
        language: language,
        skip: skip,
        limit: limit,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load group practices: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getRecitationCollectionCompletionDaysCount({
    required String collectionId,
  }) async {
    try {
      final dayCount = await remote
          .fetchRecitationCollectionCompletionDaysCount(
            collectionId: collectionId,
          );
      return Right(dayCount);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load completion day count: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupMembersPage>> getGroupMembers(
    String groupId, {
    required int skip,
    required int limit,
  }) async {
    if (skip == 0) return (await _membersSource(groupId, limit: limit)).refresh();
    try {
      final model = await remote.fetchGroupMembers(
        groupId,
        skip: skip,
        limit: limit,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load group members: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeJoinedUser(
    String groupId, {
    required String userId,
    required int banDurationDays,
    String? reason,
  }) async {
    try {
      await remote.removeJoinedUser(
        groupId,
        userId: userId,
        banDurationDays: banDurationDays,
        reason: reason,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to remove group member: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEventsPage>> getConnectEvents({
    required bool includeUnfollowed,
    required String language,
    int skip = 0,
    int limit = 20,
    String? eventFormat,
  }) async {
    try {
      final model = await remote.fetchConnectEvents(
        includeUnfollowed: includeUnfollowed,
        language: language,
        skip: skip,
        limit: limit,
        eventFormat: eventFormat,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load events: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEventsPage>> getGroupEvents(
    String groupId, {
    required String language,
  }) async {
    try {
      final model = await remote.fetchGroupEvents(groupId, language: language);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load group events: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEvent>> getGroupEventDetail(
    String eventId, {
    required String language,
  }) async {
    try {
      final model = await remote.fetchGroupEventDetail(
        eventId,
        language: language,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load group event: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupEventParticipantsPage>> getGroupEventParticipants(
    String eventId, {
    required int skip,
    required int limit,
  }) async {
    if (skip == 0) {
      return (await _participantsSource(eventId, limit: limit)).refresh();
    }
    try {
      final model = await remote.fetchGroupEventParticipants(
        eventId,
        skip: skip,
        limit: limit,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Failed to load group event participants: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> joinGroupEvent(
    String eventId, {
    GroupEventParticipationType? participationType,
  }) async {
    try {
      await remote.joinGroupEvent(
        eventId,
        participationType: participationType,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to attend event: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveGroupEvent(String eventId) async {
    try {
      await remote.leaveGroupEvent(eventId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to leave event: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupJoinRequestDecision>> approveGroupJoinRequest(
    String groupId, {
    required String requestId,
  }) async {
    try {
      final model = await remote.approveGroupJoinRequest(
        groupId,
        requestId: requestId,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to approve join request: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupJoinRequestDecision>> rejectGroupJoinRequest(
    String groupId, {
    required String requestId,
  }) async {
    try {
      final model = await remote.rejectGroupJoinRequest(
        groupId,
        requestId: requestId,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to reject join request: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupJoinRequestsPage>> getGroupJoinRequests(
    String groupId, {
    GroupJoinRequestStatus status = GroupJoinRequestStatus.pending,
    required int skip,
    required int limit,
  }) async {
    if (skip == 0 && status == GroupJoinRequestStatus.pending) {
      return (await _joinRequestsSource(groupId, limit: limit)).refresh();
    }
    try {
      final model = await remote.fetchGroupJoinRequests(
        groupId,
        status: status,
        skip: skip,
        limit: limit,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load join requests: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupReportsPage>> getGroupReports(
    String groupId, {
    GroupReportKind? kind,
    bool? resolved,
    required int skip,
    required int limit,
  }) async {
    if (skip == 0 && kind == null && resolved == false) {
      return (await _reportsSource(groupId, limit: limit)).refresh();
    }
    try {
      final model = await remote.fetchGroupReports(
        groupId,
        kind: kind,
        resolved: resolved,
        skip: skip,
        limit: limit,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to load reports: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resolveGroupReport(
    String groupId, {
    required String reportId,
  }) async {
    try {
      await remote.resolveGroupReport(groupId, reportId: reportId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to resolve report: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroupChatMessage(
    String groupId, {
    required String messageId,
  }) async {
    try {
      await remote.deleteGroupChatMessage(groupId, messageId: messageId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to delete message: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> submitJoinRequest(
    String groupId, {
    required String message,
  }) async {
    try {
      await remote.submitJoinRequest(groupId, message: message);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to submit join request: $e'));
    }
  }

  @override
  Future<Either<Failure, GroupNotificationPreferences>>
  getGroupNotificationPreferences(String groupId) async {
    try {
      final model = await remote.fetchGroupNotificationPreferences(groupId);
      return Right(model.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Failed to load group notification preferences: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, GroupNotificationPreferences>>
  updateGroupNotificationPreferences(
    String groupId, {
    bool? chat,
    bool? content,
  }) async {
    try {
      final model = await remote.updateGroupNotificationPreferences(
        groupId,
        chat: chat,
        content: content,
      );
      return Right(model.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Failed to update group notification preferences: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> unfollowGroup(
    String groupId,
    GroupType groupType,
  ) async {
    try {
      await remote.unfollowGroup(groupId, groupType);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure(
          groupType.isPage
              ? 'Failed to unfollow group: $e'
              : 'Failed to leave group: $e',
        ),
      );
    }
  }
}
