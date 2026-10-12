import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Returns true when the event has already ended (or its start is in the past
/// when no end date is available). Events without dates are treated as upcoming.
bool isGroupEventPast(GroupEvent event, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final reference = event.endDate ?? event.startDate;
  if (reference == null) return false;
  return reference.toLocal().isBefore(current);
}

typedef _ProviderRead = T Function<T>(ProviderListenable<T> provider);

bool isUserInGroup(WidgetRef ref, String groupId) =>
    _isUserInGroup(ref.read, groupId);

bool _isUserInGroup(_ProviderRead read, String groupId) {
  if (groupId.isEmpty) return true;

  if (read(pendingUnjoinedGroupIdsProvider).contains(groupId)) {
    return false;
  }

  final pendingJoined = read(pendingJoinedGroupsProvider);
  if (pendingJoined.any((group) => group.id == groupId)) {
    return true;
  }

  final myGroups = read(myGroupsProvider).valueOrNull?.groups ?? const [];
  if (myGroups.any((group) => group.id == groupId)) {
    return true;
  }

  final profileEither = read(groupProfileProvider(groupId)).valueOrNull;
  return profileEither?.fold((_) => false, (profile) => profile.isFollowing) ??
      false;
}

/// Joins the event, first joining its group if needed.
///
/// Takes the app's [ProviderContainer] (`ProviderScope.containerOf(context,
/// listen: false)`) rather than a [WidgetRef]. The user can leave the event
/// screen while the requests run. A disposed screen's `ref` throws, and
/// skipping the follow-state update would leave other screens showing the
/// group as not joined.
Future<Either<Failure, void>> joinGroupEventEnsuringGroupMembership({
  required ProviderContainer container,
  required GroupEvent event,
  GroupEventParticipationType? participationType,
}) async {
  final repository = container.read(groupProfileRepositoryProvider);

  if (event.groupId.isNotEmpty &&
      !_isUserInGroup(container.read, event.groupId)) {
    final profileResult = await container.read(
      groupProfileProvider(event.groupId).future,
    );
    final groupProfile = profileResult.fold<GroupProfile?>(
      (_) => null,
      (profile) => profile,
    );

    if (groupProfile == null) {
      return const Left(UnknownFailure('Unable to load group'));
    }

    if (!groupProfile.isFollowing) {
      final joinResult = await repository.followGroup(
        event.groupId,
        groupProfile.groupType,
      );

      final joinFailure = joinResult.fold<Failure?>(
        (failure) => failure,
        (_) => null,
      );
      if (joinFailure != null) {
        return Left(joinFailure);
      }

      final followKey = GroupFollowKey(
        groupId: event.groupId,
        groupType: groupProfile.groupType,
        loadInitialStatus: false,
      );
      container
          .read(groupFollowProvider(followKey).notifier)
          .markAutoJoinedFromPracticeEnrollment(group: groupProfile);
    }
  }

  return repository.joinGroupEvent(
    event.id,
    participationType: participationType,
  );
}
