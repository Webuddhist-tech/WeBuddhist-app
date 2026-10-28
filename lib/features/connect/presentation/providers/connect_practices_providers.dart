import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/cached_first_page.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectPracticesState {
  final List<GroupPractice> practices;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;
  final bool hasLoaded;

  const ConnectPracticesState({
    this.practices = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.hasLoaded = false,
  });

  ConnectPracticesState copyWith({
    List<GroupPractice>? practices,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    bool? hasLoaded,
    bool clearError = false,
  }) {
    return ConnectPracticesState(
      practices: practices ?? this.practices,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class ConnectPracticesNotifier extends StateNotifier<ConnectPracticesState> {
  ConnectPracticesNotifier({
    required this.ref,
    required this.includeUnfollowed,
    required this.language,
    required ScreenCacheSource<GroupPracticesPage>? source,
  }) : _source = source,
       super(_seed(source));

  // The stored page is the first state, so the first frame never spins.
  static ConnectPracticesState _seed(
    ScreenCacheSource<GroupPracticesPage>? source,
  ) {
    final page = source?.read();
    if (page == null) return const ConnectPracticesState();
    return ConnectPracticesState(
      practices: page.practices,
      hasMore: page.hasMore,
      skip: page.practices.length,
      hasLoaded: true,
    );
  }

  final Ref ref;
  final bool includeUnfollowed;
  final String language;
  final ScreenCacheSource<GroupPracticesPage>? _source;
  static const int _limit = 20;
  bool _loadRequested = false;

  void ensureLoaded() {
    if (_loadRequested) return;
    _loadRequested = true;
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;

    final authState = ref.read(authProvider);
    if (!includeUnfollowed && (authState.isGuest || !authState.isLoggedIn)) {
      state = const ConnectPracticesState(hasMore: false, hasLoaded: true);
      return;
    }

    final source = _source;
    if (source == null) {
      state = const ConnectPracticesState(hasMore: false, hasLoaded: true);
      return;
    }
    // Only an empty list shows the loader; a seeded one refreshes silently.
    state = state.copyWith(isLoading: state.practices.isEmpty, clearError: true);

    await loadCachedFirstPage(
      source,
      isCurrent: () => mounted,
      seed: state.practices.isEmpty,
      apply:
          (page) =>
              state = state.copyWith(
                practices: page.practices,
                isLoading: false,
                hasMore: page.hasMore,
                skip: page.practices.length,
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

    final result = await ref.read(groupProfileRepositoryProvider).getConnectPractices(
      includeUnfollowed: includeUnfollowed,
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
          practices: [...state.practices, ...page.practices],
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.practices.length,
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

  void retry() {
    if (state.practices.isEmpty) {
      _loadRequested = false;
      ensureLoaded();
    } else {
      loadMore();
    }
  }
}

final myConnectPracticesProvider =
    StateNotifierProvider.autoDispose<
      ConnectPracticesNotifier,
      ConnectPracticesState
    >((ref) {
      final language = ref.watch(contentLanguageProvider);
      final signedIn = ref.watch(
        authProvider.select((a) => a.isLoggedIn && !a.isGuest),
      );
      return ConnectPracticesNotifier(
        ref: ref,
        includeUnfollowed: false,
        language: language,
        source:
            signedIn
                ? ref
                    .watch(connectRepositoryProvider)
                    .connectPracticesFirstPage(
                      includeUnfollowed: false,
                      language: language,
                      limit: ConnectPracticesNotifier._limit,
                    )
                : null,
      );
    });

final discoverConnectPracticesProvider =
    StateNotifierProvider.autoDispose<
      ConnectPracticesNotifier,
      ConnectPracticesState
    >((ref) {
      final language = ref.watch(contentLanguageProvider);
      return ConnectPracticesNotifier(
        ref: ref,
        includeUnfollowed: true,
        language: language,
        source: ref
            .watch(connectRepositoryProvider)
            .connectPracticesFirstPage(
              includeUnfollowed: true,
              language: language,
              limit: ConnectPracticesNotifier._limit,
            ),
      );
    });
