import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_unified_feed_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_event_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_lazy_segment_mixin.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_discover_tab_gate.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_empty_state.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_card_layout.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_practice_card.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feed tab content with My / Discover sub-tabs.
class ConnectFeedTab extends ConsumerStatefulWidget {
  const ConnectFeedTab({
    super.key,
    required this.myGroups,
    this.isActive = true,
  });

  final List<GroupProfile> myGroups;
  final bool isActive;

  @override
  ConsumerState<ConnectFeedTab> createState() => _ConnectFeedTabState();
}

class _ConnectFeedTabState extends ConsumerState<ConnectFeedTab>
    with ConnectLazyMyDiscoverTabMixin<ConnectFeedTab> {
  @override
  bool readTabActive(ConnectFeedTab widget) => widget.isActive;

  @override
  void loadActiveSegment() {
    if (!isTabActive) return;
    if (selectedSegment == 0) {
      ref.read(myUnifiedConnectFeedProvider.notifier).ensureLoaded();
    } else {
      ref.read(discoverUnifiedConnectFeedProvider.notifier).ensureLoaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final myState = ref.watch(myUnifiedConnectFeedProvider);
    final discoverState = ref.watch(discoverUnifiedConnectFeedProvider);
    final myItems = myState.mergedItems;
    final discoverItems = discoverState.mergedItems;

    return ConnectMyDiscoverTabGate(
      myHasLoaded: myState.hasLoaded,
      myIsEmpty: myItems.isEmpty,
      myHasError: myState.error != null,
      onSegmentChanged: handleSegmentChanged,
      onMyRefresh:
          () => ref.read(myUnifiedConnectFeedProvider.notifier).refresh(),
      onDiscoverRefresh:
          () =>
              ref.read(discoverUnifiedConnectFeedProvider.notifier).refresh(),
      onMyLoadMore:
          () => ref.read(myUnifiedConnectFeedProvider.notifier).loadMore(),
      onDiscoverLoadMore:
          () =>
              ref.read(discoverUnifiedConnectFeedProvider.notifier).loadMore(),
      myBuilder: (context, switchToDiscover, scrollHeader) {
        return ConnectPaginatedListView(
          scrollViewKey: const PageStorageKey<String>('connect_feed_my'),
          header: scrollHeader,
          useHairlineDividers: false,
          separatorHeight: ConnectFeedCardLayout.listItemGap,
          items: myItems,
          isLoading: myState.isLoading,
          isLoadingMore: myState.isLoadingMore,
          error: myState.error,
          hasMore: myState.hasMore,
          hasLoaded: myState.hasLoaded,
          onRetry: () => ref.read(myUnifiedConnectFeedProvider.notifier).retry(),
          myEmptyState: ConnectMyEmptyState(
            type: ConnectMyEmptyStateType.feed,
            onBrowseTap: switchToDiscover,
          ),
          itemBuilder:
              (context, index) => _buildFeedItem(
                context,
                myItems[index],
                includeUnfollowed: false,
              ),
        );
      },
      discoverBuilder: (context, _, scrollHeader) {
        return ConnectPaginatedListView(
          scrollViewKey: const PageStorageKey<String>('connect_feed_discover'),
          header: scrollHeader,
          useHairlineDividers: false,
          separatorHeight: ConnectFeedCardLayout.listItemGap,
          items: discoverItems,
          isLoading: discoverState.isLoading,
          isLoadingMore: discoverState.isLoadingMore,
          error: discoverState.error,
          hasMore: discoverState.hasMore,
          hasLoaded: discoverState.hasLoaded,
          onRetry:
              () => ref.read(discoverUnifiedConnectFeedProvider.notifier).retry(),
          emptyDiscoverMessage: context.l10n.connect_empty_discover_feed,
          itemBuilder:
              (context, index) => _buildFeedItem(
                context,
                discoverItems[index],
                includeUnfollowed: true,
              ),
        );
      },
    );
  }

  Widget _buildFeedItem(
    BuildContext context,
    ConnectFeedItem item, {
    required bool includeUnfollowed,
  }) {
    if (item.type == ConnectFeedItemType.post && item.post != null) {
      return ConnectPostCard(
        post: item.post!,
        includeUnfollowed: includeUnfollowed,
      );
    }

    if (item.type == ConnectFeedItemType.event && item.event != null) {
      return ConnectEventCard(event: item.event!);
    }

    if (item.type == ConnectFeedItemType.practice && item.practice != null) {
      return ConnectPracticeCard(practice: item.practice!);
    }

    return const SizedBox.shrink();
  }
}
