import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_unified_feed_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_card_layout.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_item_view.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/home/presentation/providers/home_community_feed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The whole feed behind Home's "From the community", paged as it scrolls.
class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  static const _paginationThreshold = 200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMember = ref.watch(
      authProvider.select((auth) => auth.isLoggedIn && !auth.isGuest),
    );
    final feed = ref.watch(homeCommunityFeedProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (isMember) {
        ref.read(myUnifiedConnectFeedProvider.notifier).ensureLoaded();
      }
      if (feed == HomeCommunityFeed.discover) {
        ref.read(discoverUnifiedConnectFeedProvider.notifier).ensureLoaded();
      }
    });

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(context.l10n.home_community_feed),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(AppAssets.arrowLeft),
        ),
      ),
      body:
          feed == null
              ? _buildMyFeedPending(ref)
              : _buildFeed(context, ref, feed),
    );
  }

  /// The member's own feed has not decided between itself and Discover yet.
  Widget _buildMyFeedPending(WidgetRef ref) {
    final my = ref.watch(myUnifiedConnectFeedProvider);
    return ConnectPaginatedListView(
      items: const [],
      isLoading: my.isLoading,
      isLoadingMore: false,
      error: my.error,
      hasMore: false,
      hasLoaded: my.hasLoaded,
      onRetry: () => ref.read(myUnifiedConnectFeedProvider.notifier).retry(),
      itemBuilder: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildFeed(
    BuildContext context,
    WidgetRef ref,
    HomeCommunityFeed feed,
  ) {
    final state = ref.watch(feed.provider);
    final notifier = ref.read(feed.provider.notifier);
    final items = state.mergedItems;

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - _paginationThreshold) {
            notifier.loadMore();
          }
          return false;
        },
        child: ConnectPaginatedListView(
          scrollViewKey: PageStorageKey<String>('home_community_${feed.name}'),
          useHairlineDividers: false,
          separatorHeight: ConnectFeedCardLayout.listItemGap,
          items: items,
          isLoading: state.isLoading,
          isLoadingMore: state.isLoadingMore,
          error: state.error,
          hasMore: state.hasMore,
          hasLoaded: state.hasLoaded,
          onRetry: notifier.retry,
          emptyDiscoverMessage: context.l10n.connect_empty_discover_feed,
          itemBuilder:
              (context, index) => ConnectFeedItemView(
                item: items[index],
                includeUnfollowed: feed.includeUnfollowed,
              ),
        ),
      ),
    );
  }
}
