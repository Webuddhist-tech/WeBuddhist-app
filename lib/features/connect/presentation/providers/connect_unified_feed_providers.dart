import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/utils/loaded_window.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_feed_merge_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';

class UnifiedConnectFeedState {
  final List<ConnectFeedItem> feedItems;
  final List<GroupPractice> practices;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool feedHasMore;
  final bool practicesHasMore;
  final int feedSkip;
  final int practicesSkip;
  final bool hasLoaded;

  const UnifiedConnectFeedState({
    this.feedItems = const [],
    this.practices = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.feedHasMore = true,
    this.practicesHasMore = true,
    this.feedSkip = 0,
    this.practicesSkip = 0,
    this.hasLoaded = false,
  });

  List<ConnectFeedItem> get mergedItems =>
      ConnectFeedMergeUtils.merge(feedItems: feedItems, practices: practices);

  bool get hasMore => feedHasMore || practicesHasMore;

  UnifiedConnectFeedState copyWith({
    List<ConnectFeedItem>? feedItems,
    List<GroupPractice>? practices,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? feedHasMore,
    bool? practicesHasMore,
    int? feedSkip,
    int? practicesSkip,
    bool? hasLoaded,
    bool clearError = false,
  }) {
    return UnifiedConnectFeedState(
      feedItems: feedItems ?? this.feedItems,
      practices: practices ?? this.practices,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      feedHasMore: feedHasMore ?? this.feedHasMore,
      practicesHasMore: practicesHasMore ?? this.practicesHasMore,
      feedSkip: feedSkip ?? this.feedSkip,
      practicesSkip: practicesSkip ?? this.practicesSkip,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class UnifiedConnectFeedNotifier extends StateNotifier<UnifiedConnectFeedState> {
  UnifiedConnectFeedNotifier({
    required this.ref,
    required this.includeUnfollowed,
    required this.language,
    required ScreenCacheSource<ConnectFeedPage>? feedSource,
    required ScreenCacheSource<GroupPracticesPage>? practicesSource,
  }) : _feedSource = feedSource,
       _practicesSource = practicesSource,
       super(_seed(feedSource, practicesSource));

  // The stored pages are the first state, so the first frame never spins.
  static UnifiedConnectFeedState _seed(
    ScreenCacheSource<ConnectFeedPage>? feedSource,
    ScreenCacheSource<GroupPracticesPage>? practicesSource,
  ) {
    final feed = feedSource?.read();
    if (feed == null) return const UnifiedConnectFeedState();
    final practices = practicesSource?.read();
    return UnifiedConnectFeedState(
      feedItems: feed.items,
      practices: practices?.practices ?? const [],
      feedHasMore: feed.hasMore,
      practicesHasMore: practices?.hasMore ?? false,
      feedSkip: feed.items.length,
      practicesSkip: practices?.practices.length ?? 0,
      hasLoaded: true,
    );
  }

  final Ref ref;
  final bool includeUnfollowed;
  final String language;
  final ScreenCacheSource<ConnectFeedPage>? _feedSource;
  final ScreenCacheSource<GroupPracticesPage>? _practicesSource;
  static const int _limit = 20;

  // Blocks paging while page one is being read again; stale pages are dropped.
  bool _firstPageInFlight = false;
  int _pageEpoch = 0;
  bool _loadRequested = false;

  /// The API's largest page, for re-reading loaded cards in few calls.
  static const int _windowLimit = 100;

  /// Bumped when a refresh replaces the feed cards, so a feed page computed
  /// against the old ones is dropped. Practices page on regardless.
  int _feedEpoch = 0;

  /// Posts edited here while a refresh was out; its read predates them.
  Map<String, ConnectPost>? _updatedDuringRefresh;
  bool _refreshing = false;

  /// A signal came while a read was out, so one more runs once it lands.
  bool _refreshAgain = false;

  void ensureLoaded() {
    if (_loadRequested) return;
    _loadRequested = true;
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;

    final authState = ref.read(authProvider);
    if (!includeUnfollowed && (authState.isGuest || !authState.isLoggedIn)) {
      state = const UnifiedConnectFeedState(
        feedHasMore: false,
        practicesHasMore: false,
        hasLoaded: true,
      );
      return;
    }

    final feedSource = _feedSource;
    final practicesSource = _practicesSource;
    if (feedSource == null || practicesSource == null) {
      state = const UnifiedConnectFeedState(
        feedHasMore: false,
        practicesHasMore: false,
        hasLoaded: true,
      );
      return;
    }
    // Only an empty feed shows the loader; a seeded one refreshes silently.
    state = state.copyWith(
      isLoading: state.feedItems.isEmpty,
      clearError: true,
    );

    final cachedFeed = state.feedItems.isEmpty ? feedSource.read() : null;
    final cachedPractices = practicesSource.read();
    if (cachedFeed != null) {
      state = state.copyWith(
        feedItems: cachedFeed.items,
        practices: cachedPractices?.practices ?? const [],
        isLoading: false,
        feedHasMore: cachedFeed.hasMore,
        practicesHasMore: cachedPractices?.hasMore ?? false,
        feedSkip: cachedFeed.items.length,
        practicesSkip: cachedPractices?.practices.length ?? 0,
        hasLoaded: true,
        clearError: true,
      );
    }

    _firstPageInFlight = true;
    final feedResult = await feedSource.refresh();
    final practicesResult = await practicesSource.refresh();
    _firstPageInFlight = false;

    if (!mounted) return;
    // Runs after this load lands, so a signal during it is not lost.
    scheduleMicrotask(_runPendingRefresh);

    feedResult.fold(
      (failure) {
        if (cachedFeed != null || state.feedItems.isNotEmpty) return;
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
          hasLoaded: true,
        );
      },
      (page) {
        _pageEpoch++;
        practicesResult.fold(
          (failure) {
            state = state.copyWith(
              feedItems: page.items,
              isLoading: false,
              feedHasMore: page.hasMore,
              feedSkip: page.items.length,
              practicesHasMore: false,
              hasLoaded: true,
              clearError: true,
            );
          },
          (practicesPage) {
            state = state.copyWith(
              feedItems: page.items,
              practices: practicesPage.practices,
              isLoading: false,
              feedHasMore: page.hasMore,
              practicesHasMore: practicesPage.hasMore,
              feedSkip: page.items.length,
              practicesSkip: practicesPage.practices.length,
              hasLoaded: true,
              clearError: true,
            );
          },
        );
      },
    );
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
    final feedEpoch = _feedEpoch;

    final futures = <Future<void>>[];

    if (state.feedHasMore) {
      futures.add(_loadMoreFeed(epoch, feedEpoch));
    }
    if (state.practicesHasMore) {
      futures.add(_loadMorePractices(epoch));
    }

    await Future.wait(futures);

    if (!mounted) return;
    state = state.copyWith(isLoadingMore: false);
  }

  Future<void> _loadMoreFeed(int epoch, int feedEpoch) async {
    final result = await ref.read(connectRepositoryProvider).getConnectFeeds(
      includeUnfollowed: includeUnfollowed,
      language: language,
      skip: state.feedSkip,
      limit: _limit,
    );

    // Page one was replaced meanwhile; this page belongs to the old list.
    if (!mounted || epoch != _pageEpoch || feedEpoch != _feedEpoch) return;

    result.fold(
      (failure) {
        state = state.copyWith(error: failure.message, feedHasMore: false);
      },
      (page) {
        state = state.copyWith(
          feedItems: [...state.feedItems, ...page.items],
          feedHasMore: page.hasMore,
          feedSkip: state.feedSkip + page.items.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> _loadMorePractices(int epoch) async {
    final result = await ref
        .read(groupProfileRepositoryProvider)
        .getConnectPractices(
          includeUnfollowed: includeUnfollowed,
          language: language,
          skip: state.practicesSkip,
          limit: _limit,
        );

    // Page one was replaced meanwhile; this page belongs to the old list.
    if (!mounted || epoch != _pageEpoch) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message,
          practicesHasMore: false,
        );
      },
      (page) {
        state = state.copyWith(
          practices: [...state.practices, ...page.practices],
          practicesHasMore: page.hasMore,
          practicesSkip: state.practicesSkip + page.practices.length,
          clearError: true,
        );
      },
    );
  }

  /// Re-reads every loaded feed card after a followed group posts or
  /// changes an event, keeping the pages already loaded and where paging
  /// stands. Practices are left as they are.
  Future<void> refreshLatest() async {
    if (_feedSource == null || !state.hasLoaded) return;
    if (state.isLoading || _firstPageInFlight || _refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    final updated = _updatedDuringRefresh = {};
    final LoadedWindow<ConnectFeedItem>? read;
    try {
      read = await readLoadedWindow(
        window: () => math.max(_limit, state.feedSkip),
        fetch:
            (skip, limit) async => (await ref
                    .read(connectRepositoryProvider)
                    .getConnectFeeds(
                      includeUnfollowed: includeUnfollowed,
                      language: language,
                      skip: skip,
                      limit: limit,
                    ))
                .map((page) => (page.items, page.total)),
        idOf: (item) => item.dedupeKey,
        isCurrent: () => mounted,
        pageLimit: _windowLimit,
      );
    } finally {
      _refreshing = false;
      _updatedDuringRefresh = null;
    }
    if (read != null) {
      _feedEpoch++;
      state = state.copyWith(
        feedItems: [
          for (final item in read.rows)
            switch (updated[item.post?.id]) {
              final post? => item.copyWithPost(post),
              null => item,
            },
        ],
        feedSkip: read.rows.length,
        feedHasMore: read.rows.length < read.total,
        clearError: true,
      );
    }
    _runPendingRefresh();
  }

  void _runPendingRefresh() {
    if (!_refreshAgain || !mounted) return;
    _refreshAgain = false;
    unawaited(refreshLatest());
  }

  /// Keeps the feed on screen while the first pages are read again.
  Future<void> refresh() async {
    _loadRequested = true;
    await loadInitial();
  }

  void retry() {
    if (state.mergedItems.isEmpty) {
      _loadRequested = false;
      ensureLoaded();
    } else {
      loadMore();
    }
  }

  void updatePost(ConnectPost updatedPost) {
    _updatedDuringRefresh?[updatedPost.id] = updatedPost;
    final index = state.feedItems.indexWhere(
      (item) =>
          item.type == ConnectFeedItemType.post &&
          item.post?.id == updatedPost.id,
    );
    if (index == -1) return;

    final item = state.feedItems[index];
    if (item.post == null) return;

    final updatedFeedItems = [...state.feedItems];
    updatedFeedItems[index] = item.copyWithPost(updatedPost);
    state = state.copyWith(feedItems: updatedFeedItems);
  }
}

final myUnifiedConnectFeedProvider = StateNotifierProvider.autoDispose<
  UnifiedConnectFeedNotifier,
  UnifiedConnectFeedState
>((ref) {
  final language = ref.watch(contentLanguageProvider);
  final signedIn = ref.watch(
    authProvider.select((a) => a.isLoggedIn && !a.isGuest),
  );
  final repository = ref.watch(connectRepositoryProvider);
  return UnifiedConnectFeedNotifier(
    ref: ref,
    includeUnfollowed: false,
    language: language,
    feedSource:
        signedIn
            ? repository.connectFeedFirstPage(
              includeUnfollowed: false,
              language: language,
              limit: UnifiedConnectFeedNotifier._limit,
            )
            : null,
    practicesSource:
        signedIn
            ? repository.connectPracticesFirstPage(
              includeUnfollowed: false,
              language: language,
              limit: UnifiedConnectFeedNotifier._limit,
            )
            : null,
  );
});

final discoverUnifiedConnectFeedProvider = StateNotifierProvider.autoDispose<
  UnifiedConnectFeedNotifier,
  UnifiedConnectFeedState
>((ref) {
  final language = ref.watch(contentLanguageProvider);
  final repository = ref.watch(connectRepositoryProvider);
  return UnifiedConnectFeedNotifier(
    ref: ref,
    includeUnfollowed: true,
    language: language,
    feedSource: repository.connectFeedFirstPage(
      includeUnfollowed: true,
      language: language,
      limit: UnifiedConnectFeedNotifier._limit,
    ),
    practicesSource: repository.connectPracticesFirstPage(
      includeUnfollowed: true,
      language: language,
      limit: UnifiedConnectFeedNotifier._limit,
    ),
  );
});
