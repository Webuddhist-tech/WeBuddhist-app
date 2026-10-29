import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
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
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';

final groupAccumulatorRemoteDatasourceProvider =
    Provider<GroupAccumulatorRemoteDatasource>((ref) {
      return GroupAccumulatorRemoteDatasource(dio: ref.watch(dioProvider));
    });

final groupAccumulatorRepositoryProvider =
    Provider<GroupAccumulatorRepositoryInterface>((ref) {
      return GroupAccumulatorRepositoryImpl(
        remote: ref.watch(groupAccumulatorRemoteDatasourceProvider),
        store: ref.watch(screenCacheStoreProvider),
      );
    });

typedef GroupAccumulatorsNotifier =
    AutoDisposeScreenCacheFamilyNotifier<
      GroupAccumulatorsPage,
      Either<Failure, GroupAccumulatorsPage>,
      String
    >;

/// Stored page is the first state, refreshed in the background.
final groupAccumulatorsProvider = AsyncNotifierProvider.autoDispose.family<
  GroupAccumulatorsNotifier,
  Either<Failure, GroupAccumulatorsPage>,
  String
>(() {
  return GroupAccumulatorsNotifier((ref, groupId, bind) {
    ref.watch(authProvider);
    final language = ref.watch(contentLanguageProvider);
    final repository = ref.watch(groupAccumulatorRepositoryProvider);
    return bind.source(
      repository.groupAccumulatorsSource(
        groupId,
        limit: 20,
        language: language,
      ),
    );
  });
});

typedef GroupAccumulatorDetailNotifier =
    AutoDisposeScreenCacheFamilyNotifier<
      GroupAccumulatorDetail,
      Either<Failure, GroupAccumulatorDetail>,
      String
    >;

/// `.future` resolves with the stored detail; use `refreshGroupAccumulator`
/// when the server copy is required.
final groupAccumulatorDetailProvider = AsyncNotifierProvider.autoDispose.family<
  GroupAccumulatorDetailNotifier,
  Either<Failure, GroupAccumulatorDetail>,
  String
>(() {
  return GroupAccumulatorDetailNotifier((ref, accumulatorId, bind) {
    ref.watch(authProvider);
    final language = ref.watch(contentLanguageProvider);
    final repository = ref.watch(groupAccumulatorRepositoryProvider);
    return bind.source(
      repository.groupAccumulatorDetailSource(
        accumulatorId,
        language: language,
      ),
    );
  });
});

/// The server's detail, for anything that hands the user's count on (the
/// reader mirrors it exactly). The stored copy can be behind chants made
/// elsewhere, so it is only used, with [allowStored], when the fetch fails.
Future<GroupAccumulatorDetail?> fetchFreshGroupAccumulatorDetail(
  ProviderContainer container,
  String accumulatorId, {
  bool allowStored = true,
}) async {
  final repository = container.read(groupAccumulatorRepositoryProvider);
  final language = container.read(contentLanguageProvider);
  final fresh = await repository.refreshGroupAccumulator(
    accumulatorId,
    language: language,
  );
  final detail = fresh.fold((_) => null, (d) => d);
  if (detail != null || !allowStored) return detail;
  final stored = await container.read(
    groupAccumulatorDetailProvider(accumulatorId).future,
  );
  return stored.fold((_) => null, (d) => d);
}

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
    GroupAccumulatorMembersPage? stored,
  }) : _repository = repository,
       super(const GroupAccumulatorMembersState()) {
    // The stored page is the first state, so the first frame never spins.
    if (stored != null) {
      state = state.copyWith(
        hasLoadedOnce: true,
        members: stored.members,
        total: stored.total,
      );
    }
  }

  final GroupAccumulatorRepositoryInterface _repository;
  final String accumulatorId;
  final GroupAccumulatorMemberSort sortBy;
  static const _pageSize = 20;
  bool _hasLoaded = false;
  // A page-two request must not run from the stored offset while page one is
  // still being refreshed, nor land on a list that page one has replaced.
  bool _firstPageInFlight = false;
  int _pageEpoch = 0;

  /// Stored first page shows at once; the server copy replaces it.
  Future<void> loadInitial({bool force = false}) async {
    if (_hasLoaded && !force) return;
    _hasLoaded = true;
    state = state.copyWith(
      isLoading: state.members.isEmpty,
      clearError: true,
    );

    _firstPageInFlight = true;
    final Either<Failure, GroupAccumulatorMembersPage> result;
    try {
      result = await _repository.getGroupAccumulatorMembers(
        accumulatorId,
        skip: 0,
        limit: _pageSize,
        sortBy: sortBy,
      );
    } finally {
      _firstPageInFlight = false;
    }
    if (!mounted) return;

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        hasLoadedOnce: true,
        error: state.members.isEmpty ? failure : null,
      ),
      (page) {
        _pageEpoch++;
        state = state.copyWith(
          isLoading: false,
          hasLoadedOnce: true,
          members: page.members,
          total: page.total,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (_firstPageInFlight) return;

    final epoch = _pageEpoch;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final result = await _repository.getGroupAccumulatorMembers(
      accumulatorId,
      skip: state.members.length,
      limit: _pageSize,
      sortBy: sortBy,
    );
    if (!mounted) return;
    if (epoch != _pageEpoch) {
      // Page one was replaced meanwhile; this page was computed against it.
      state = state.copyWith(isLoadingMore: false);
      return;
    }

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
      final repository = ref.watch(groupAccumulatorRepositoryProvider);
      return GroupAccumulatorMembersNotifier(
        repository: repository,
        accumulatorId: key.accumulatorId,
        sortBy: key.sortBy,
        stored: repository.readStoredGroupAccumulatorMembers(
          key.accumulatorId,
          sortBy: key.sortBy,
        ),
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

/// Takes the app's [ProviderContainer] rather than a [WidgetRef] because it
/// runs after awaits, when the screen that asked for it may be gone.
void refreshGroupAccumulatorData(
  ProviderContainer container, {
  required String accumulatorId,
  String? groupId,
}) {
  container.invalidate(groupAccumulatorDetailProvider(accumulatorId));
  // Reload live member lists in place so they keep showing the current rows
  // instead of resetting to a spinner; unmounted ones load fresh on demand.
  for (final sort in GroupAccumulatorMemberSort.values) {
    final provider = groupAccumulatorMembersProvider(
      GroupAccumulatorMembersKey(accumulatorId: accumulatorId, sortBy: sort),
    );
    if (container.exists(provider)) {
      container.read(provider.notifier).loadInitial(force: true);
    }
  }
  if (groupId != null && groupId.isNotEmpty) {
    refreshGroupPracticesIn(container, groupId);
  }
}

/// Joins on the server, then updates the app's join state.
///
/// Takes the app's [ProviderContainer] (`ProviderScope.containerOf(context,
/// listen: false)`) rather than a [WidgetRef]. The user can leave the screen
/// while the request runs. A disposed screen's `ref` throws, and skipping the
/// updates would leave other screens showing the accumulator as not joined.
Future<bool> joinGroupAccumulator({
  required ProviderContainer container,
  required String accumulatorId,
  required String groupId,
  GroupProfile? group,
  bool awaitRefresh = true,
}) async {
  final repository = container.read(groupAccumulatorRepositoryProvider);
  final result = await repository.joinGroupAccumulator(accumulatorId);

  if (result.isLeft()) return false;

  container
      .read(groupAccumulatorJoinCacheProvider(groupId).notifier)
      .markJoined(accumulatorId);

  GroupProfile? resolvedGroup = group;
  if (resolvedGroup == null) {
    final profileResult = await container.read(
      groupProfileProvider(groupId).future,
    );
    resolvedGroup = profileResult.fold((_) => null, (profile) => profile);
  }

  if (resolvedGroup != null) {
    final followKey = GroupFollowKey(
      groupId: groupId,
      groupType: resolvedGroup.groupType,
    );
    container
        .read(groupFollowProvider(followKey).notifier)
        .markAutoJoinedFromPracticeEnrollment(group: resolvedGroup);
  }

  refreshGroupAccumulatorData(
    container,
    accumulatorId: accumulatorId,
    groupId: groupId,
  );

  final refreshFuture = Future.wait([
    container.read(groupAccumulatorDetailProvider(accumulatorId).future),
    container.read(groupPracticesProvider(groupId).notifier).loadInitial(),
  ]);

  if (awaitRefresh) {
    await refreshFuture;
  }

  return true;
}

/// Ends a group accumulation chant session by flushing pending counts and
/// refreshing accumulator data. Does not delete or reset local/server counts;
/// per-visit session display in the reader is handled separately via a baseline.
///
/// Takes the app's [ProviderContainer] because the reader is usually closing
/// while the flush runs, and its `ref` is unusable once it is disposed.
Future<bool> finishGroupAccumulatorSession({
  required ProviderContainer container,
  required String groupAccumulatorId,
  required String presetId,
  String? groupId,
}) async {
  try {
    await container.read(malaSyncManagerProvider).flush(SyncReason.screenLeave);
  } catch (_) {
    // Leaving the reader should still succeed even if flush fails.
  }

  refreshGroupAccumulatorData(
    container,
    accumulatorId: groupAccumulatorId,
    groupId: groupId,
  );
  container.invalidate(joinedGroupUserCountsProvider(presetId));
  container.invalidate(joinedAccumulatorGroupsProvider(presetId));

  return true;
}
