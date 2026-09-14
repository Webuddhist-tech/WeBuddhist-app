import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_accumulator_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_accumulator_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_accumulator_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final groupAccumulatorRemoteDatasourceProvider =
    Provider<GroupAccumulatorRemoteDatasource>((ref) {
      return GroupAccumulatorRemoteDatasource(dio: ref.watch(dioProvider));
    });

final groupAccumulatorRepositoryProvider =
    Provider<GroupAccumulatorRepositoryInterface>((ref) {
      return GroupAccumulatorRepositoryImpl(
        remote: ref.watch(groupAccumulatorRemoteDatasourceProvider),
      );
    });

final groupAccumulatorsProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupAccumulatorsPage>, String>((
      ref,
      groupId,
    ) async {
      ref.watch(authProvider);
      final repository = ref.watch(groupAccumulatorRepositoryProvider);
      return repository.getGroupAccumulators(groupId, skip: 0, limit: 20);
    });

final groupAccumulatorDetailProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupAccumulatorDetail>, String>((
      ref,
      accumulatorId,
    ) async {
      ref.watch(authProvider);
      final repository = ref.watch(groupAccumulatorRepositoryProvider);
      return repository.getGroupAccumulator(accumulatorId);
    });

@immutable
class GroupAccumulatorMembersKey {
  final String accumulatorId;
  final GroupAccumulatorMemberSort sortBy;

  const GroupAccumulatorMembersKey({
    required this.accumulatorId,
    this.sortBy = GroupAccumulatorMemberSort.total,
  });

  @override
  bool operator ==(Object other) {
    return other is GroupAccumulatorMembersKey &&
        other.accumulatorId == accumulatorId &&
        other.sortBy == sortBy;
  }

  @override
  int get hashCode => Object.hash(accumulatorId, sortBy);
}

List<GroupAccumulatorMember> sortAccumulatorMembers(
  List<GroupAccumulatorMember> members,
  GroupAccumulatorMemberSort sort,
) {
  final sorted = List<GroupAccumulatorMember>.from(members);
  sorted.sort((a, b) {
    final aCount =
        sort == GroupAccumulatorMemberSort.today ? a.todayCount : a.totalCount;
    final bCount =
        sort == GroupAccumulatorMemberSort.today ? b.todayCount : b.totalCount;
    return bCount.compareTo(aCount);
  });
  return sorted;
}

class GroupAccumulatorMembersState {
  final List<GroupAccumulatorMember> members;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasLoadedOnce;
  final Failure? error;

  const GroupAccumulatorMembersState({
    this.members = const [],
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasLoadedOnce = false,
    this.error,
  });

  bool get hasMore => members.length < total;

  GroupAccumulatorMembersState copyWith({
    List<GroupAccumulatorMember>? members,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasLoadedOnce,
    Failure? error,
    bool clearError = false,
  }) {
    return GroupAccumulatorMembersState(
      members: members ?? this.members,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GroupAccumulatorMembersNotifier
    extends StateNotifier<GroupAccumulatorMembersState> {
  GroupAccumulatorMembersNotifier({
    required GroupAccumulatorRepositoryInterface repository,
    required this.accumulatorId,
    required this.sortBy,
  }) : _repository = repository,
       super(const GroupAccumulatorMembersState());

  final GroupAccumulatorRepositoryInterface _repository;
  final String accumulatorId;
  final GroupAccumulatorMemberSort sortBy;
  static const _pageSize = 20;
  bool _hasLoaded = false;

  Future<void> loadInitial({bool force = false}) async {
    if (_hasLoaded && !force) return;
    _hasLoaded = true;
    state = state.copyWith(
      isLoading: state.members.isEmpty,
      clearError: true,
    );

    final result = await _repository.getGroupAccumulatorMembers(
      accumulatorId,
      skip: 0,
      limit: _pageSize,
      sortBy: sortBy,
    );
    if (!mounted) return;

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        hasLoadedOnce: true,
        error: failure,
      ),
      (page) => state = state.copyWith(
        isLoading: false,
        hasLoadedOnce: true,
        members: page.members,
        total: page.total,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final result = await _repository.getGroupAccumulatorMembers(
      accumulatorId,
      skip: state.members.length,
      limit: _pageSize,
      sortBy: sortBy,
    );
    if (!mounted) return;

    result.fold(
      (failure) => state = state.copyWith(isLoadingMore: false, error: failure),
      (page) => state = state.copyWith(
        isLoadingMore: false,
        members: [...state.members, ...page.members],
        total: page.total,
      ),
    );
  }

  Future<void> retry() async {
    _hasLoaded = false;
    await loadInitial(force: true);
  }
}

final groupAccumulatorMembersProvider = StateNotifierProvider.autoDispose
    .family<
      GroupAccumulatorMembersNotifier,
      GroupAccumulatorMembersState,
      GroupAccumulatorMembersKey
    >((ref, key) {
      return GroupAccumulatorMembersNotifier(
        repository: ref.watch(groupAccumulatorRepositoryProvider),
        accumulatorId: key.accumulatorId,
        sortBy: key.sortBy,
      );
    });

class GroupAccumulatorJoinCacheNotifier extends StateNotifier<Set<String>> {
  GroupAccumulatorJoinCacheNotifier() : super(const {});

  void markJoined(String accumulatorId) {
    state = {...state, accumulatorId};
  }

  void markUnjoined(String accumulatorId) {
    if (!state.contains(accumulatorId)) return;
    state = {...state}..remove(accumulatorId);
  }

  void clear() => state = const {};

  void syncFromApi(List<GroupAccumulator> accumulators) {
    final joinedIds =
        accumulators
            .where((accumulator) => accumulator.isJoined == true)
            .map((accumulator) => accumulator.id)
            .toSet();
    final notJoinedIds =
        accumulators
            .where((accumulator) => accumulator.isJoined == false)
            .map((accumulator) => accumulator.id)
            .toSet();

    state = {...state, ...joinedIds}..removeAll(notJoinedIds);
  }
}

final groupAccumulatorJoinCacheProvider = StateNotifierProvider.autoDispose
    .family<GroupAccumulatorJoinCacheNotifier, Set<String>, String>((
      ref,
      groupId,
    ) {
      return GroupAccumulatorJoinCacheNotifier();
    });

bool accumulatorHasJoined(
  GroupAccumulator accumulator, {
  Set<String> localJoinedIds = const {},
}) {
  if (localJoinedIds.contains(accumulator.id)) return true;
  return accumulator.isJoined == true;
}

void refreshGroupAccumulatorData(
  WidgetRef ref, {
  required String accumulatorId,
  String? groupId,
}) {
  ref.invalidate(groupAccumulatorDetailProvider(accumulatorId));
  // Reload live member lists in place so they keep showing the current rows
  // instead of resetting to a spinner; unmounted ones load fresh on demand.
  for (final sort in GroupAccumulatorMemberSort.values) {
    final provider = groupAccumulatorMembersProvider(
      GroupAccumulatorMembersKey(accumulatorId: accumulatorId, sortBy: sort),
    );
    if (ref.exists(provider)) {
      ref.read(provider.notifier).loadInitial(force: true);
    }
  }
  if (groupId != null && groupId.isNotEmpty) {
    refreshGroupPractices(ref, groupId);
  }
}

Future<bool> joinGroupAccumulator({
  required WidgetRef ref,
  required String accumulatorId,
  required String groupId,
  GroupProfile? group,
  bool awaitRefresh = true,
}) async {
  final repository = ref.read(groupAccumulatorRepositoryProvider);
  final result = await repository.joinGroupAccumulator(accumulatorId);

  if (result.isLeft()) return false;

  ref
      .read(groupAccumulatorJoinCacheProvider(groupId).notifier)
      .markJoined(accumulatorId);

  GroupProfile? resolvedGroup = group;
  if (resolvedGroup == null) {
    final profileResult = await ref.read(groupProfileProvider(groupId).future);
    resolvedGroup = profileResult.fold((_) => null, (profile) => profile);
  }

  if (resolvedGroup != null) {
    final followKey = GroupFollowKey(
      groupId: groupId,
      groupType: resolvedGroup.groupType,
    );
    ref
        .read(groupFollowProvider(followKey).notifier)
        .markAutoJoinedFromPracticeEnrollment(group: resolvedGroup);
  }

  refreshGroupAccumulatorData(
    ref,
    accumulatorId: accumulatorId,
    groupId: groupId,
  );

  final refreshFuture = Future.wait([
    ref.read(groupAccumulatorDetailProvider(accumulatorId).future),
    ref.read(groupPracticesProvider(groupId).notifier).loadInitial(),
  ]);

  if (awaitRefresh) {
    await refreshFuture;
  }

  return true;
}

/// Ends a group accumulation chant session by flushing pending counts and
/// refreshing accumulator data. Does not delete or reset local/server counts;
/// per-visit session display in the reader is handled separately via a baseline.
Future<bool> finishGroupAccumulatorSession({
  required WidgetRef ref,
  required String groupAccumulatorId,
  required String presetId,
  String? groupId,
}) async {
  try {
    await ref.read(malaSyncManagerProvider).flush(SyncReason.screenLeave);
  } catch (_) {
    // Leaving the reader should still succeed even if flush fails.
  }

  refreshGroupAccumulatorData(
    ref,
    accumulatorId: groupAccumulatorId,
    groupId: groupId,
  );
  ref.invalidate(joinedGroupUserCountsProvider(presetId));
  ref.invalidate(joinedAccumulatorGroupsProvider(presetId));

  return true;
}
