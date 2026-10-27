import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_feed_merge_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }) : super(const UnifiedConnectFeedState());

  final Ref ref;
  final bool includeUnfollowed;
  final String language;
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
      state = const UnifiedConnectFeedState(
        feedHasMore: false,
        practicesHasMore: false,
        hasLoaded: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    // Stored first pages show at once; the server's replace them if changed.
    final repository = ref.read(connectRepositoryProvider);
    final feedSource = await repository.connectFeedFirstPage(
      includeUnfollowed: includeUnfollowed,
      language: language,
      limit: _limit,
    );
    final practicesSource = await repository.connectPracticesFirstPage(
      includeUnfollowed: includeUnfollowed,
      language: language,
      limit: _limit,
    );
    if (!mounted) return;

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

    final feedResult = await feedSource.refresh();
    final practicesResult = await practicesSource.refresh();

    if (!mounted) return;

    feedResult.fold(
      (failure) {
        if (cachedFeed != null) return;
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
          hasLoaded: true,
        );
      },
      (page) {
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
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    final futures = <Future<void>>[];

    if (state.feedHasMore) {
      futures.add(_loadMoreFeed());
    }
    if (state.practicesHasMore) {
      futures.add(_loadMorePractices());
    }

    await Future.wait(futures);

    if (!mounted) return;
    state = state.copyWith(isLoadingMore: false);
  }

  Future<void> _loadMoreFeed() async {
    final result = await ref.read(connectRepositoryProvider).getConnectFeeds(
      includeUnfollowed: includeUnfollowed,
      language: language,
      skip: state.feedSkip,
      limit: _limit,
    );

    if (!mounted) return;

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

  Future<void> _loadMorePractices() async {
    final result = await ref
        .read(groupProfileRepositoryProvider)
        .getConnectPractices(
          includeUnfollowed: includeUnfollowed,
          language: language,
          skip: state.practicesSkip,
          limit: _limit,
        );

    if (!mounted) return;

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
  return UnifiedConnectFeedNotifier(
    ref: ref,
    includeUnfollowed: false,
    language: language,
  );
});

final discoverUnifiedConnectFeedProvider = StateNotifierProvider.autoDispose<
  UnifiedConnectFeedNotifier,
  UnifiedConnectFeedState
>((ref) {
  final language = ref.watch(contentLanguageProvider);
  return UnifiedConnectFeedNotifier(
    ref: ref,
    includeUnfollowed: true,
    language: language,
  );
});
