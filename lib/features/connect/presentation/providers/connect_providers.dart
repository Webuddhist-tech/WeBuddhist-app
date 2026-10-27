import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/connect/data/datasource/connect_remote_datasource.dart';
import 'package:flutter_pecha/features/connect/data/repositories/connect_repository_impl.dart';
import 'package:flutter_pecha/features/connect/domain/entities/discover_groups_page.dart';
import 'package:flutter_pecha/features/connect/domain/repositories/connect_repository.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/cached_first_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectRemoteDatasourceProvider = Provider<ConnectRemoteDatasource>((
  ref,
) {
  return ConnectRemoteDatasource(dio: ref.watch(dioProvider));
});

final connectRepositoryProvider = Provider<ConnectRepository>((ref) {
  return ConnectRepositoryImpl(
    remote: ref.watch(connectRemoteDatasourceProvider),
    store: ref.watch(screenCacheStoreProvider),
  );
});

class DiscoverGroupsState {
  final List<GroupProfile> groups;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  /// False until the first load settles, so the UI can tell "not fetched yet"
  /// apart from "fetched and genuinely empty".
  final bool hasLoaded;

  const DiscoverGroupsState({
    this.groups = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.hasLoaded = false,
  });

  DiscoverGroupsState copyWith({
    List<GroupProfile>? groups,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    bool? hasLoaded,
    bool clearError = false,
  }) {
    return DiscoverGroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class DiscoverGroupsNotifier extends StateNotifier<DiscoverGroupsState> {
  DiscoverGroupsNotifier({
    required this.repository,
    required this.language,
  }) : super(const DiscoverGroupsState());

  final ConnectRepository repository;
  final String language;
  static const int _limit = 20;
  bool _loadRequested = false;

  void ensureLoaded() {
    if (_loadRequested) return;
    _loadRequested = true;
    loadInitial();
  }

  /// Stored first page shows at once; the server's replaces it if changed.
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);
    final source = await repository.discoverGroupsFirstPage(
      language: language,
      limit: _limit,
    );
    if (!mounted) return;

    await loadCachedFirstPage(
      source,
      isCurrent: () => mounted,
      seed: state.groups.isEmpty,
      apply:
          (page) =>
              state = state.copyWith(
                groups: page.groups,
                isLoading: false,
                hasMore: page.hasMore,
                skip: page.groups.length,
                hasLoaded: true,
                clearError: true,
              ),
      fail:
          (failure) =>
              state = state.copyWith(
                isLoading: false,
                error: failure.message,
                hasLoaded: true,
              ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await repository.getDiscoverGroups(
      language: language,
      skip: state.skip,
      limit: _limit,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          groups: [...state.groups, ...page.groups],
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.groups.length,
          clearError: true,
        );
      },
    );
  }

  /// Keeps the list on screen while the first page is read again.
  Future<void> refresh() async {
    _loadRequested = true;
    await loadInitial();
  }

  void removeGroups(Set<String> groupIds) {
    if (groupIds.isEmpty || state.groups.isEmpty) return;

    final filtered =
        state.groups.where((group) => !groupIds.contains(group.id)).toList();
    if (filtered.length == state.groups.length) return;

    state = state.copyWith(groups: filtered);
  }

  void retry() {
    if (state.groups.isEmpty) {
      _loadRequested = false;
      ensureLoaded();
    } else {
      loadMore();
    }
  }
}

final discoverGroupsProvider =
    StateNotifierProvider.autoDispose<DiscoverGroupsNotifier, DiscoverGroupsState>(
      (ref) {
        final language = ref.watch(contentLanguageProvider);
        return DiscoverGroupsNotifier(
          repository: ref.watch(connectRepositoryProvider),
          language: language,
        );
      },
    );

/// Groups joined this session before the my-groups API reflects them.
final pendingJoinedGroupsProvider =
    StateProvider<List<GroupProfile>>((ref) => const []);

/// Groups unfollowed this session while the my-groups API still returns them.
final pendingUnjoinedGroupIdsProvider =
    StateProvider<Set<String>>((ref) => const {});

/// Stored page first, refreshed in the background; pull-to-refresh goes
/// through `refreshMyGroups`, not `ref.refresh`, so the UI keeps its data.
final myGroupsProvider = StreamProvider<DiscoverGroupsPage>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.isGuest || !authState.isLoggedIn) {
    return Stream.value(
      const DiscoverGroupsPage(groups: [], skip: 0, limit: 20, total: 0),
    );
  }

  final language = ref.watch(contentLanguageProvider);
  final repo = ref.watch(connectRepositoryProvider);
  return repo.watchMyGroups(language: language).map((result) {
    return result.fold(
      (failure) => throw Exception(failure.message),
      (page) {
        syncPendingGroupsWithApi(
          ref: ref,
          apiGroupIds: page.groups.map((g) => g.id).toSet(),
        );
        return page;
      },
    );
  });
});

List<GroupProfile> filterDiscoverGroups({
  required List<GroupProfile> discoverGroups,
  required Set<String> joinedGroupIds,
}) {
  if (joinedGroupIds.isEmpty) return discoverGroups;

  return discoverGroups
      .where((group) => !joinedGroupIds.contains(group.id))
      .toList();
}

List<GroupProfile> mergeMyGroupsWithPending({
  required List<GroupProfile> apiGroups,
  required List<GroupProfile> pendingGroups,
  Set<String> pendingUnjoinedIds = const {},
}) {
  final merged = () {
    if (pendingGroups.isEmpty) return apiGroups;

    final apiIds = apiGroups.map((g) => g.id).toSet();
    final pendingOnly =
        pendingGroups.where((g) => !apiIds.contains(g.id)).toList();
    if (pendingOnly.isEmpty) return apiGroups;

    return [...pendingOnly, ...apiGroups];
  }();

  if (pendingUnjoinedIds.isEmpty) return merged;

  return merged.where((g) => !pendingUnjoinedIds.contains(g.id)).toList();
}

void syncPendingGroupsWithApi({
  required Ref ref,
  required Set<String> apiGroupIds,
}) {
  ref.read(pendingJoinedGroupsProvider.notifier).update(
    (pending) =>
        pending.where((group) => !apiGroupIds.contains(group.id)).toList(),
  );

  ref.read(pendingUnjoinedGroupIdsProvider.notifier).update(
    (unjoined) => unjoined.intersection(apiGroupIds),
  );
}
