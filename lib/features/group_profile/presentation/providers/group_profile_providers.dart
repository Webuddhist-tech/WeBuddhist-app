import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_profile_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_profile_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_member.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/usecases/get_group_profile_usecase.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_post_providers.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final groupProfileRemoteDatasourceProvider =
    Provider<GroupProfileRemoteDatasource>((ref) {
      return GroupProfileRemoteDatasource(dio: ref.watch(dioProvider));
    });

final groupProfileRepositoryProvider =
    Provider<GroupProfileRepositoryInterface>((ref) {
      return GroupProfileRepositoryImpl(
        remote: ref.watch(groupProfileRemoteDatasourceProvider),
      );
    });

final getGroupProfileUseCaseProvider = Provider<GetGroupProfileUseCase>((ref) {
  final repository = ref.watch(groupProfileRepositoryProvider);
  return GetGroupProfileUseCase(repository.getGroupProfile);
});

final groupProfileProvider = FutureProvider.autoDispose.family<
  Either<Failure, GroupProfile>,
  String
>((ref, groupId) async {
  // Refetch when auth changes so user-specific fields (e.g. is_group_enrolled)
  // are loaded with the Bearer token attached.
  ref.watch(authProvider);
  final language = ref.watch(contentLanguageProvider);
  final useCase = ref.watch(getGroupProfileUseCaseProvider);
  return useCase(GetGroupProfileParams(groupId: groupId, language: language));
});

class GroupPracticesState {
  final List<GroupPractice> practices;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  const GroupPracticesState({
    this.practices = const [],
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
  });

  GroupPracticesState copyWith({
    List<GroupPractice>? practices,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    bool clearError = false,
  }) {
    return GroupPracticesState(
      practices: practices ?? this.practices,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
    );
  }
}

class GroupPracticesNotifier extends StateNotifier<GroupPracticesState> {
  GroupPracticesNotifier({
    required GroupProfileRepositoryInterface repository,
    required Ref ref,
    required String groupId,
  }) : _repository = repository,
       _ref = ref,
       _groupId = groupId,
       super(const GroupPracticesState());

  final GroupProfileRepositoryInterface _repository;
  final Ref _ref;
  final String _groupId;
  static const int _limit = 20;
  int _requestGeneration = 0;

  Future<void> loadInitial() async {
    if (state.isLoading || state.isLoadingMore) return;

    final generation = ++_requestGeneration;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getGroupPractices(
      _groupId,
      language: _ref.read(contentLanguageProvider),
      skip: 0,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          practices: page.practices,
          total: page.total,
          isLoading: false,
          hasMore: page.hasMore,
          skip: page.practices.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    final generation = _requestGeneration;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await _repository.getGroupPractices(
      _groupId,
      language: _ref.read(contentLanguageProvider),
      skip: state.skip,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          practices: [...state.practices, ...page.practices],
          total: page.total,
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.practices.length,
          clearError: true,
        );
      },
    );
  }

  void retry() {
    if (state.practices.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }
}

final groupPracticesProvider = StateNotifierProvider.autoDispose
    .family<GroupPracticesNotifier, GroupPracticesState, String>((
      ref,
      groupId,
    ) {
      ref.watch(authProvider);
      ref.watch(contentLanguageProvider);
      final notifier = GroupPracticesNotifier(
        repository: ref.watch(groupProfileRepositoryProvider),
        ref: ref,
        groupId: groupId,
      );
      notifier.loadInitial();
      return notifier;
    });

void refreshGroupPractices(WidgetRef ref, String groupId) {
  if (!ref.exists(groupPracticesProvider(groupId))) return;
  ref.read(groupPracticesProvider(groupId).notifier).loadInitial();
}

void refreshGroupPracticesFromRef(Ref ref, String groupId) {
  if (!ref.exists(groupPracticesProvider(groupId))) return;
  ref.read(groupPracticesProvider(groupId).notifier).loadInitial();
}

@immutable
class GroupRecitationCollectionKey {
  final String groupId;
  final String collectionId;

  const GroupRecitationCollectionKey({
    required this.groupId,
    required this.collectionId,
  });

  @override
  bool operator ==(Object other) {
    return other is GroupRecitationCollectionKey &&
        other.groupId == groupId &&
        other.collectionId == collectionId;
  }

  @override
  int get hashCode => Object.hash(groupId, collectionId);
}

final groupRecitationCollectionDetailProvider = FutureProvider.autoDispose
    .family<
      Either<Failure, GroupRecitationCollection>,
      GroupRecitationCollectionKey
    >((ref, key) async {
      ref.watch(authProvider);
      final repository = ref.watch(groupProfileRepositoryProvider);
      return repository.getRecitationCollectionDetail(
        collectionId: key.collectionId,
      );
    });

/// Outcome of logging one chant as completed.
enum GroupChantCompletionResult {
  completed,

  /// Rejected because the user follows the group but has not joined it.
  membershipRequired,

  /// Skipped (guest, empty id, already in flight) or the call failed.
  failed,
}

class GroupRecitationCollectionCompletionState {
  final Set<String> completedChantIds;
  final Set<String> submittingChantIds;

  /// True once the user has completed at least one chant through this
  /// notifier instance (as opposed to completions loaded from the server).
  /// Distinguishes "the user just finished the collection" from "it was
  /// already finished before they arrived".
  final bool hasCompletedChantThisSession;
  final bool isLoading;
  final String? error;

  const GroupRecitationCollectionCompletionState({
    this.completedChantIds = const {},
    this.submittingChantIds = const {},
    this.hasCompletedChantThisSession = false,
    this.isLoading = false,
    this.error,
  });

  bool isCompleted(String chantId) =>
      completedChantIds.contains(chantId.trim());

  bool isSubmitting(String chantId) =>
      submittingChantIds.contains(chantId.trim());

  GroupRecitationCollectionCompletionState copyWith({
    Set<String>? completedChantIds,
    Set<String>? submittingChantIds,
    bool? hasCompletedChantThisSession,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GroupRecitationCollectionCompletionState(
      completedChantIds: completedChantIds ?? this.completedChantIds,
      submittingChantIds: submittingChantIds ?? this.submittingChantIds,
      hasCompletedChantThisSession:
          hasCompletedChantThisSession ?? this.hasCompletedChantThisSession,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class GroupRecitationCollectionCompletionNotifier
    extends StateNotifier<GroupRecitationCollectionCompletionState> {
  GroupRecitationCollectionCompletionNotifier({
    required GroupProfileRepositoryInterface repository,
    required GroupRecitationCollectionKey key,
    required bool isAuthenticated,
  }) : _repository = repository,
       _key = key,
       _isAuthenticated = isAuthenticated,
       super(const GroupRecitationCollectionCompletionState());

  final GroupProfileRepositoryInterface _repository;
  final GroupRecitationCollectionKey _key;
  final bool _isAuthenticated;
  int _requestGeneration = 0;

  Future<void> loadToday() async {
    if (!_isAuthenticated || state.isLoading) return;

    final generation = ++_requestGeneration;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getTodayRecitationCollectionCompletions(
      collectionId: _key.collectionId,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (completedChantIds) {
        // Merge rather than replace: a chant completed locally while this
        // fetch was in flight may not be in the server snapshot yet.
        state = state.copyWith(
          completedChantIds: {...state.completedChantIds, ...completedChantIds},
          isLoading: false,
          clearError: true,
        );
      },
    );
  }

  Future<GroupChantCompletionResult> completeChant(String chantId) async {
    final trimmedChantId = chantId.trim();
    if (!_isAuthenticated || trimmedChantId.isEmpty) {
      return GroupChantCompletionResult.failed;
    }
    if (state.completedChantIds.contains(trimmedChantId)) {
      return GroupChantCompletionResult.completed;
    }
    if (state.submittingChantIds.contains(trimmedChantId)) {
      return GroupChantCompletionResult.failed;
    }

    state = state.copyWith(
      submittingChantIds: {...state.submittingChantIds, trimmedChantId},
      clearError: true,
    );

    final result = await _repository.completeRecitationCollectionChant(
      collectionId: _key.collectionId,
      chantId: trimmedChantId,
    );

    if (!mounted) return GroupChantCompletionResult.failed;

    final submitting = {...state.submittingChantIds}..remove(trimmedChantId);

    return result.fold(
      (failure) {
        state = state.copyWith(
          submittingChantIds: submitting,
          error: failure.message,
        );
        return failure is AuthorizationFailure &&
                failure.message == noGroupMembershipCode
            ? GroupChantCompletionResult.membershipRequired
            : GroupChantCompletionResult.failed;
      },
      (_) {
        state = state.copyWith(
          completedChantIds: {...state.completedChantIds, trimmedChantId},
          submittingChantIds: submitting,
          hasCompletedChantThisSession: true,
          clearError: true,
        );
        return GroupChantCompletionResult.completed;
      },
    );
  }
}

final groupRecitationCollectionCompletionProvider = StateNotifierProvider
    .autoDispose
    .family<
      GroupRecitationCollectionCompletionNotifier,
      GroupRecitationCollectionCompletionState,
      GroupRecitationCollectionKey
    >((ref, key) {
      final authState = ref.watch(authProvider);
      final notifier = GroupRecitationCollectionCompletionNotifier(
        repository: ref.watch(groupProfileRepositoryProvider),
        key: key,
        isAuthenticated: authState.isLoggedIn && !authState.isGuest,
      );
      notifier.loadToday();
      return notifier;
    });

/// Number of days the user has completed [key]'s recitation collection.
///
/// Fetched on demand (e.g. right after the last chant of the day is
/// checked off) rather than eagerly, since it's only needed to populate the
/// completion celebration sheet.
final groupRecitationCollectionDaysCountProvider = FutureProvider.autoDispose
    .family<Either<Failure, int>, GroupRecitationCollectionKey>((
      ref,
      key,
    ) async {
      final repository = ref.watch(groupProfileRepositoryProvider);
      return repository.getRecitationCollectionCompletionDaysCount(
        collectionId: key.collectionId,
      );
    });

@immutable
class GroupFollowKey {
  final String groupId;
  final GroupType groupType;
  final bool loadInitialStatus;

  const GroupFollowKey({
    required this.groupId,
    required this.groupType,
    this.loadInitialStatus = true,
  });

  @override
  bool operator ==(Object other) {
    return other is GroupFollowKey &&
        other.groupId == groupId &&
        other.groupType == groupType &&
        other.loadInitialStatus == loadInitialStatus;
  }

  @override
  int get hashCode => Object.hash(groupId, groupType, loadInitialStatus);
}

sealed class GroupFollowState {
  const GroupFollowState();
}

class GroupFollowLoading extends GroupFollowState {
  final bool isInitialCheck;

  const GroupFollowLoading({this.isInitialCheck = false});
}

class GroupFollowSuccess extends GroupFollowState {
  final bool isFollowing;
  final int countDelta;

  const GroupFollowSuccess({required this.isFollowing, this.countDelta = 0});
}

class GroupFollowFailure extends GroupFollowState {
  final Failure failure;
  const GroupFollowFailure(this.failure);
}

/// Whether the initial join-status check for a private group is still in flight.
bool isPrivateGroupMembershipLoading(GroupFollowState followState) {
  return followState is GroupFollowLoading && followState.isInitialCheck;
}

/// Whether the current user is an active member of a private community group.
///
/// Only a resolved follow check counts; never infer membership from join-request
/// status alone (avoids flashing joined UI for stale APPROVED responses).
bool isPrivateGroupMember({required GroupFollowState followState}) {
  return switch (followState) {
    GroupFollowSuccess(isFollowing: final isFollowing) => isFollowing,
    _ => false,
  };
}

class GroupFollowNotifier extends StateNotifier<GroupFollowState> {
  final GroupProfileRepositoryInterface _repository;
  final Ref _ref;
  final GroupFollowKey _key;
  final bool _isAuthenticated;

  GroupFollowNotifier({
    required GroupProfileRepositoryInterface repository,
    required Ref ref,
    required GroupFollowKey key,
    required bool isAuthenticated,
  }) : _repository = repository,
       _ref = ref,
       _key = key,
       _isAuthenticated = isAuthenticated,
       super(
         key.loadInitialStatus
             ? const GroupFollowLoading(isInitialCheck: true)
             : const GroupFollowSuccess(isFollowing: false),
       ) {
    if (key.loadInitialStatus) {
      _loadInitialStatus();
    }
  }

  int _currentCountDelta() {
    final current = state;
    return current is GroupFollowSuccess ? current.countDelta : 0;
  }

  void _invalidateGroupProfile() {
    _ref.invalidate(groupProfileProvider(_key.groupId));
    refreshGroupPracticesFromRef(_ref, _key.groupId);
  }

  void _refreshGroupMembers() {
    final groupId = _key.groupId;
    if (!_ref.exists(groupMembersProvider(groupId))) return;

    if (_ref.read(groupMembersTabActiveProvider(groupId))) {
      _ref.read(groupMembersProvider(groupId).notifier).loadInitial();
    } else {
      _ref.read(groupMembersNeedsRefreshProvider(groupId).notifier).state =
          true;
    }
  }

  void _invalidateConnectProviders() {
    _ref.invalidate(myGroupsProvider);
  }

  void _refreshDiscoverGroupsIfLoaded() {
    if (!_ref.exists(discoverGroupsProvider)) return;

    final discoverState = _ref.read(discoverGroupsProvider);
    if (!discoverState.hasLoaded) return;

    _ref.read(discoverGroupsProvider.notifier).refresh();
  }

  void _addPendingJoinedGroup(GroupProfile group) {
    final updatedGroup = group.withMemberCountDelta(1);
    _ref.read(pendingJoinedGroupsProvider.notifier).update((groups) {
      if (groups.any((g) => g.id == group.id)) return groups;
      return [updatedGroup, ...groups];
    });
    _clearPendingUnjoined(group.id);
  }

  void _removePendingJoinedGroup(String groupId) {
    _ref
        .read(pendingJoinedGroupsProvider.notifier)
        .update((groups) => groups.where((g) => g.id != groupId).toList());
  }

  void _markPendingUnjoined(String groupId) {
    _ref
        .read(pendingUnjoinedGroupIdsProvider.notifier)
        .update((ids) => {...ids, groupId});
  }

  void _clearPendingUnjoined(String groupId) {
    _ref
        .read(pendingUnjoinedGroupIdsProvider.notifier)
        .update((ids) => {...ids}..remove(groupId));
  }

  Future<void> _loadInitialStatus() async {
    if (!_isAuthenticated) {
      if (mounted) state = const GroupFollowSuccess(isFollowing: false);
      return;
    }

    final result = await _repository.checkFollowStatus(
      _key.groupId,
      _key.groupType,
    );
    if (!mounted) return;

    result.fold(
      (_) => state = const GroupFollowSuccess(isFollowing: false),
      (isFollowing) => state = GroupFollowSuccess(isFollowing: isFollowing),
    );
  }

  Future<bool> follow({GroupProfile? connectGroup}) async {
    if (state is GroupFollowLoading) return false;
    state = const GroupFollowLoading();

    final result = await _repository.followGroup(_key.groupId, _key.groupType);
    if (!mounted) return false;

    return await result.fold(
      (failure) async {
        state = GroupFollowFailure(failure);
        return false;
      },
      (_) async {
        _applyJoinedState(connectGroup: connectGroup, incrementCount: true);
        return true;
      },
    );
  }

  /// Backend auto-joins the group when enrolling in a series via group_id.
  /// Updates join UI immediately without a manual refresh.
  void markAutoJoinedFromPracticeEnrollment({required GroupProfile group}) {
    if (!_isAuthenticated) return;

    final alreadyFollowing = switch (state) {
      GroupFollowSuccess(isFollowing: final isFollowing) => isFollowing,
      _ => false,
    };
    if (alreadyFollowing) return;

    _applyJoinedState(connectGroup: group, incrementCount: true);
  }

  /// Re-sync join status after returning from a flow that may have auto-joined.
  Future<void> syncJoinStatusFromServer({GroupProfile? connectGroup}) async {
    if (!_isAuthenticated) return;

    final result = await _repository.checkFollowStatus(
      _key.groupId,
      _key.groupType,
    );
    if (!mounted) return;

    result.fold((_) {}, (isFollowing) {
      if (!isFollowing) return;

      final alreadyFollowing = switch (state) {
        GroupFollowSuccess(isFollowing: final following) => following,
        _ => false,
      };
      _applyJoinedState(
        connectGroup: connectGroup,
        incrementCount: !alreadyFollowing,
      );
    });
  }

  void _applyJoinedState({
    required GroupProfile? connectGroup,
    required bool incrementCount,
  }) {
    final previousDelta = _currentCountDelta();
    state = GroupFollowSuccess(
      isFollowing: true,
      countDelta: incrementCount ? previousDelta + 1 : previousDelta,
    );
    _invalidateGroupProfile();
    _refreshGroupMembers();
    _invalidateConnectProviders();
    if (connectGroup != null) {
      _addPendingJoinedGroup(connectGroup);
      _ref.read(discoverGroupsProvider.notifier).removeGroups({
        connectGroup.id,
      });
    }
  }

  Future<bool> unfollow({GroupProfile? connectGroup}) async {
    if (state is GroupFollowLoading) return false;
    final previousDelta = _currentCountDelta();
    state = const GroupFollowLoading();

    final result = await _repository.unfollowGroup(
      _key.groupId,
      _key.groupType,
    );
    if (!mounted) return false;

    return await result.fold(
      (failure) async {
        state = GroupFollowFailure(failure);
        return false;
      },
      (_) async {
        state = GroupFollowSuccess(
          isFollowing: false,
          countDelta: previousDelta - 1,
        );
        _invalidateGroupProfile();
        _refreshGroupMembers();
        _invalidateConnectProviders();
        if (connectGroup != null) {
          _removePendingJoinedGroup(connectGroup.id);
          _markPendingUnjoined(connectGroup.id);
          _refreshDiscoverGroupsIfLoaded();
        }
        return true;
      },
    );
  }
}

final groupFollowProvider = StateNotifierProvider.autoDispose
    .family<GroupFollowNotifier, GroupFollowState, GroupFollowKey>((ref, key) {
      final authState = ref.watch(authProvider);
      final isAuthenticated = !authState.isGuest && authState.isLoggedIn;

      return GroupFollowNotifier(
        repository: ref.watch(groupProfileRepositoryProvider),
        ref: ref,
        key: key,
        isAuthenticated: isAuthenticated,
      );
    });

bool isSeriesGroupEnrolledInProfile(GroupProfile profile, String seriesId) {
  return profile.series.any(
    (series) => series.id == seriesId && series.isGroupEnrolled == true,
  );
}

/// Returns the tri-state group enrollment status for a series.
/// - `true`: enrolled with this group
/// - `false`: enrolled with a different group
/// - `null`: not group-enrolled
bool? seriesGroupEnrollmentStatus(
  GroupProfileSeries series, {
  Set<String> localEnrolledSeriesIds = const {},
}) {
  if (localEnrolledSeriesIds.contains(series.id)) return true;
  return series.isGroupEnrolled;
}

bool? seriesGroupEnrollmentStatusFromProfile(
  GroupProfile profile,
  String seriesId, {
  Set<String> localEnrolledSeriesIds = const {},
}) {
  for (final series in profile.series) {
    if (series.id == seriesId) {
      return seriesGroupEnrollmentStatus(
        series,
        localEnrolledSeriesIds: localEnrolledSeriesIds,
      );
    }
  }
  return null;
}

/// Shows the change-group confirmation dialog when [enrollmentStatus] is false.
Future<bool> confirmGroupPracticeChangeIfNeeded(
  BuildContext context,
  bool? enrollmentStatus,
) async {
  if (enrollmentStatus != false) return true;

  final l10n = context.l10n;
  final confirmed = await showConfirmationDialog(
    context,
    title: l10n.group_change_practice_title,
    message: l10n.group_change_practice_message,
    confirmLabel: l10n.ai_confirm,
  );
  return confirmed == true;
}

bool? seriesGroupEnrollmentStatusFromPractices(
  GroupPracticesPage page,
  String seriesId, {
  Set<String> localEnrolledSeriesIds = const {},
}) {
  for (final practice in page.practices) {
    final series = practice.series;
    if (series != null && series.id == seriesId) {
      return seriesGroupEnrollmentStatus(
        series,
        localEnrolledSeriesIds: localEnrolledSeriesIds,
      );
    }
  }
  return null;
}

/// Enrolls in a series via [groupId] and updates group join UI optimistically.
Future<bool> enrollSeriesThroughGroup({
  required WidgetRef ref,
  required String seriesId,
  required String groupId,
  required GroupType groupType,
}) async {
  final notifier = ref.read(seriesEnrollmentProvider(seriesId).notifier);
  final ok = await notifier.enroll(groupId: groupId);
  if (!ok) return false;

  final followKey = GroupFollowKey(groupId: groupId, groupType: groupType);
  final profileResult = await ref.read(groupProfileProvider(groupId).future);
  profileResult.fold(
    (_) {},
    (profile) => ref
        .read(groupFollowProvider(followKey).notifier)
        .markAutoJoinedFromPracticeEnrollment(group: profile),
  );
  ref.invalidate(groupProfileProvider(groupId));
  refreshGroupPractices(ref, groupId);
  return true;
}

/// Syncs join state after returning from the post-enrollment routine editor.
Future<void> completeGroupPracticeEnrollmentFlow({
  required WidgetRef ref,
  required String groupId,
  required GroupType groupType,
}) async {
  final followKey = GroupFollowKey(groupId: groupId, groupType: groupType);
  final profileResult = await ref.read(groupProfileProvider(groupId).future);
  await profileResult.fold(
    (_) async {},
    (profile) => ref
        .read(groupFollowProvider(followKey).notifier)
        .syncJoinStatusFromServer(connectGroup: profile),
  );
  ref.invalidate(groupProfileProvider(groupId));
  refreshGroupPractices(ref, groupId);
}

class GroupMembersState {
  final List<GroupMember> members;
  final int totalMembers;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  const GroupMembersState({
    this.members = const [],
    this.totalMembers = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
  });

  GroupMembersState copyWith({
    List<GroupMember>? members,
    int? totalMembers,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    bool clearError = false,
  }) {
    return GroupMembersState(
      members: members ?? this.members,
      totalMembers: totalMembers ?? this.totalMembers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
    );
  }
}

class GroupMembersNotifier extends StateNotifier<GroupMembersState> {
  GroupMembersNotifier({
    required GroupProfileRepositoryInterface repository,
    required String groupId,
  }) : _repository = repository,
       _groupId = groupId,
       super(const GroupMembersState());

  final GroupProfileRepositoryInterface _repository;
  final String _groupId;
  static const int _limit = 20;
  int _requestGeneration = 0;

  Future<void> loadInitial() async {
    if (state.isLoading || state.isLoadingMore) return;

    final generation = ++_requestGeneration;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getGroupMembers(
      _groupId,
      skip: 0,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          members: page.members,
          totalMembers: page.totalMembers,
          isLoading: false,
          hasMore: page.hasMore,
          skip: page.members.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    final generation = _requestGeneration;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await _repository.getGroupMembers(
      _groupId,
      skip: state.skip,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          members: [...state.members, ...page.members],
          totalMembers: page.totalMembers,
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.members.length,
          clearError: true,
        );
      },
    );
  }

  void retry() {
    if (state.members.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }
}

/// True when the group profile header title has scrolled out of view.
final groupProfileAppBarTitleVisibleProvider = StateProvider.autoDispose
    .family<bool, String>((ref, groupId) => false);

/// True while the group profile members tab is the selected tab.
final groupMembersTabActiveProvider = StateProvider.autoDispose
    .family<bool, String>((ref, groupId) => false);

/// Set when join/unjoin happens while the members tab is not selected.
final groupMembersNeedsRefreshProvider = StateProvider.autoDispose
    .family<bool, String>((ref, groupId) => false);

final groupMembersProvider = StateNotifierProvider.autoDispose
    .family<GroupMembersNotifier, GroupMembersState, String>((ref, groupId) {
      return GroupMembersNotifier(
        repository: ref.watch(groupProfileRepositoryProvider),
        groupId: groupId,
      );
    });

final groupEventsProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupEventsPage>, String>((ref, groupId) async {
      final repository = ref.watch(groupProfileRepositoryProvider);
      return repository.getGroupEvents(groupId);
    });

final groupEventDetailProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupEvent>, String>((ref, eventId) async {
      final language = ref.watch(contentLanguageProvider);
      final repository = ref.watch(groupProfileRepositoryProvider);
      return repository.getGroupEventDetail(eventId, language: language);
    });

typedef GroupEventLanguageKey = ({String eventId, String language});

/// Event detail in an explicit language, for the live stream language toggle.
final groupEventInLanguageProvider = FutureProvider.autoDispose.family<
  Either<Failure, GroupEvent>,
  GroupEventLanguageKey
>((ref, key) async {
  final repository = ref.watch(groupProfileRepositoryProvider);
  return repository.getGroupEventDetail(key.eventId, language: key.language);
});

class GroupEventParticipantsState {
  final List<GroupEventParticipant> participants;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  const GroupEventParticipantsState({
    this.participants = const [],
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
  });

  GroupEventParticipantsState copyWith({
    List<GroupEventParticipant>? participants,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    bool clearError = false,
  }) {
    return GroupEventParticipantsState(
      participants: participants ?? this.participants,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
    );
  }
}

class GroupEventParticipantsNotifier
    extends StateNotifier<GroupEventParticipantsState> {
  GroupEventParticipantsNotifier({
    required GroupProfileRepositoryInterface repository,
    required String eventId,
  }) : _repository = repository,
       _eventId = eventId,
       super(const GroupEventParticipantsState());

  final GroupProfileRepositoryInterface _repository;
  final String _eventId;
  static const int _limit = 20;
  int _requestGeneration = 0;

  Future<void> loadInitial() async {
    if (state.isLoading || state.isLoadingMore) return;

    final generation = ++_requestGeneration;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getGroupEventParticipants(
      _eventId,
      skip: 0,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          participants: page.participants,
          total: page.total,
          isLoading: false,
          hasMore: page.hasMore,
          skip: page.participants.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    final generation = _requestGeneration;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await _repository.getGroupEventParticipants(
      _eventId,
      skip: state.skip,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          participants: [...state.participants, ...page.participants],
          total: page.total,
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.participants.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> refresh() async {
    final generation = ++_requestGeneration;
    state = const GroupEventParticipantsState(isLoading: true);

    final result = await _repository.getGroupEventParticipants(
      _eventId,
      skip: 0,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          participants: page.participants,
          total: page.total,
          isLoading: false,
          hasMore: page.hasMore,
          skip: page.participants.length,
          clearError: true,
        );
      },
    );
  }

  void retry() {
    if (state.participants.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }
}

final groupEventParticipantsProvider = StateNotifierProvider.autoDispose.family<
  GroupEventParticipantsNotifier,
  GroupEventParticipantsState,
  String
>((ref, eventId) {
  final notifier = GroupEventParticipantsNotifier(
    repository: ref.watch(groupProfileRepositoryProvider),
    eventId: eventId,
  );
  // Load on creation so the first watch already has participants.
  notifier.loadInitial();
  return notifier;
});

Future<bool> submitGroupJoinRequest({
  required WidgetRef ref,
  required String groupId,
  String message = '',
}) async {
  final result = await ref
      .read(groupProfileRepositoryProvider)
      .submitJoinRequest(groupId, message: message);
  return result.fold((_) => false, (_) {
    ref.invalidate(groupProfileProvider(groupId));
    return true;
  });
}

Future<void> refreshGroupProfilePage({
  required WidgetRef ref,
  required String groupId,
  required GroupType groupType,
}) async {
  final followKey = GroupFollowKey(groupId: groupId, groupType: groupType);
  ref.invalidate(groupFollowProvider(followKey));

  final refreshTasks = <Future<void>>[
    ref.refresh(groupProfileProvider(groupId).future).then((_) {}),
  ];

  if (ref.exists(groupPracticesProvider(groupId))) {
    refreshGroupPractices(ref, groupId);
  }
  if (ref.exists(groupEventsProvider(groupId))) {
    refreshTasks.add(
      ref.refresh(groupEventsProvider(groupId).future).then((_) {}),
    );
  }
  if (ref.exists(groupMembersProvider(groupId))) {
    ref.read(groupMembersProvider(groupId).notifier).loadInitial();
  }
  refreshGroupPosts(ref, groupId);

  await Future.wait(refreshTasks);
}
