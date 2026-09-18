import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_members_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

abstract class GroupProfileRepositoryInterface {
  Future<Either<Failure, GroupProfile>> getGroupProfile(
    String groupId, {
    required String language,
  });

  Future<Either<Failure, bool>> checkFollowStatus(
    String groupId,
    GroupType groupType,
  );

  Future<Either<Failure, void>> followGroup(
    String groupId,
    GroupType groupType,
  );

  Future<Either<Failure, void>> unfollowGroup(
    String groupId,
    GroupType groupType,
  );

  Future<Either<Failure, GroupPracticesPage>> getGroupPractices(
    String groupId, {
    required String language,
    required int skip,
    required int limit,
  });

  Future<Either<Failure, GroupPracticesPage>> getConnectPractices({
    required bool includeUnfollowed,
    required String language,
    required int skip,
    required int limit,
  });

  Future<Either<Failure, GroupRecitationCollection>>
  getRecitationCollectionDetail({required String collectionId});

  Future<Either<Failure, Set<String>>> getTodayRecitationCollectionCompletions({
    required String collectionId,
  });

  Future<Either<Failure, void>> completeRecitationCollectionChant({
    required String collectionId,
    required String chantId,
  });

  /// Number of days the user has completed this recitation collection,
  /// per `GET /users/me/groups/recitation-collections/{id}/complete/days-count`.
  Future<Either<Failure, int>> getRecitationCollectionCompletionDaysCount({
    required String collectionId,
  });

  Future<Either<Failure, GroupMembersPage>> getGroupMembers(
    String groupId, {
    required int skip,
    required int limit,
  });

  Future<Either<Failure, GroupEventsPage>> getGroupEvents(String groupId);

  Future<Either<Failure, GroupEventsPage>> getConnectEvents({
    required bool includeUnfollowed,
    required String language,
    int skip = 0,
    int limit = 20,
    String? eventFormat,
  });

  Future<Either<Failure, GroupEvent>> getGroupEventDetail(
    String eventId, {
    required String language,
  });

  Future<Either<Failure, GroupEventParticipantsPage>> getGroupEventParticipants(
    String eventId, {
    required int skip,
    required int limit,
  });

  Future<Either<Failure, void>> joinGroupEvent(
    String eventId, {
    GroupEventParticipationType? participationType,
  });

  Future<Either<Failure, void>> leaveGroupEvent(String eventId);

  Future<Either<Failure, void>> submitJoinRequest(
    String groupId, {
    required String message,
  });
}
