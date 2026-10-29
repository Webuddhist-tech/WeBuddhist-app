import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/cached_first_page.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';

class ConnectEventsState {
  final List<GroupEvent> events;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  /// False until the first load settles, so the UI can tell "not fetched yet"
  /// apart from "fetched and genuinely empty".
  final bool hasLoaded;

  const ConnectEventsState({
    this.events = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.hasLoaded = false,
  });

  ConnectEventsState copyWith({
    List<GroupEvent>? events,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    bool? hasLoaded,
    bool clearError = false,
  }) {
    return ConnectEventsState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class ConnectEventsNotifier extends StateNotifier<ConnectEventsState> {
  ConnectEventsNotifier({
    required this.ref,
    required this.includeUnfollowed,
    required this.language,
    required ScreenCacheSource<GroupEventsPage>? source,
    this.eventFormat,
  }) : _source = source,
       super(_seed(source));

  // The stored page is the first state, so the first frame never spins.
  static ConnectEventsState _seed(ScreenCacheSource<GroupEventsPage>? source) {
    final page = source?.read();
    if (page == null) return const ConnectEventsState();
    return ConnectEventsState(
      events: page.events,
      hasMore: page.hasMore,
      skip: page.events.length,
      hasLoaded: true,
    );
  }

  final Ref ref;
  final bool includeUnfollowed;
  final String language;
  final ScreenCacheSource<GroupEventsPage>? _source;

  /// `event_format` query value, or null to list every format.
  final String? eventFormat;
  static const int _limit = 20;

  // Blocks paging while page one is being read again; stale pages are dropped.
  bool _firstPageInFlight = false;
  int _pageEpoch = 0;
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
      state = const ConnectEventsState(hasMore: false, hasLoaded: true);
      return;
    }

    final source = _source;
    if (source == null) {
      state = const ConnectEventsState(hasMore: false, hasLoaded: true);
      return;
    }
    // Only an empty list shows the loader; a seeded one refreshes silently.
    state = state.copyWith(isLoading: state.events.isEmpty, clearError: true);

    _firstPageInFlight = true;
    try {
      await loadCachedFirstPage(
        source,
        isCurrent: () => mounted,
        seed: state.events.isEmpty,
        apply: (page) {
          _pageEpoch++;
          state = state.copyWith(
            events: page.events,
            isLoading: false,
            hasMore: page.hasMore,
            skip: page.events.length,
            hasLoaded: true,
            clearError: true,
          );
        },
        fail:
            (failure) =>
                state = state.copyWith(
                  isLoading: false,
                  error: failure.message,
                  hasLoaded: true,
                ),
      );
    } finally {
      _firstPageInFlight = false;
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.isLoading ||
        _firstPageInFlight) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final epoch = _pageEpoch;

    final result = await ref.read(groupProfileRepositoryProvider).getConnectEvents(
      includeUnfollowed: includeUnfollowed,
      language: language,
      skip: state.skip,
      limit: _limit,
      eventFormat: eventFormat,
    );

    if (!mounted) return;
    // Page one was replaced meanwhile; this page belongs to the old list.
    if (epoch != _pageEpoch) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          events: [...state.events, ...page.events],
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.events.length,
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
    if (state.events.isEmpty) {
      _loadRequested = false;
      ensureLoaded();
    } else {
      loadMore();
    }
  }
}

final myConnectEventsProvider = StateNotifierProvider.autoDispose
    .family<ConnectEventsNotifier, ConnectEventsState, ConnectEventFormatFilter>(
      (ref, filter) {
        final language = ref.watch(contentLanguageProvider);
        final signedIn = ref.watch(
          authProvider.select((a) => a.isLoggedIn && !a.isGuest),
        );
        return ConnectEventsNotifier(
          ref: ref,
          includeUnfollowed: false,
          language: language,
          eventFormat: filter.apiValue,
          source:
              signedIn
                  ? ref
                      .watch(connectRepositoryProvider)
                      .connectEventsFirstPage(
                        includeUnfollowed: false,
                        language: language,
                        limit: ConnectEventsNotifier._limit,
                        eventFormat: filter.apiValue,
                      )
                  : null,
        );
      },
    );

final discoverConnectEventsProvider =
    StateNotifierProvider.autoDispose<ConnectEventsNotifier, ConnectEventsState>((
      ref,
    ) {
      final language = ref.watch(contentLanguageProvider);
      return ConnectEventsNotifier(
        ref: ref,
        includeUnfollowed: true,
        language: language,
        source: ref
            .watch(connectRepositoryProvider)
            .connectEventsFirstPage(
              includeUnfollowed: true,
              language: language,
              limit: ConnectEventsNotifier._limit,
            ),
      );
    });
