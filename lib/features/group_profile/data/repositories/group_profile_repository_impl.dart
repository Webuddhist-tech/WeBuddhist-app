import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_profile_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_members_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';

class GroupProfileRepositoryImpl implements GroupProfileRepositoryInterface {
  final GroupProfileRemoteDatasource remote;

  GroupProfileRepositoryImpl({required this.remote});

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
    String groupId,
  ) async {
    try {
      final model = await remote.fetchGroupEvents(groupId);
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
    } catch (e) {
      return Left(UnknownFailure('Failed to submit join request: $e'));
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
