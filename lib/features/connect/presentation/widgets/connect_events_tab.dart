import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_events_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_event_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_lazy_segment_mixin.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_discover_tab_gate.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_empty_state.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Connect events list is unfiltered; format tabs live on the group
/// events screen.
final _myEventsProvider = myConnectEventsProvider(ConnectEventFormatFilter.all);

/// Events tab content with My / Discover sub-tabs.
class ConnectEventsTab extends ConsumerStatefulWidget {
  const ConnectEventsTab({
    super.key,
    required this.myGroups,
    this.isActive = true,
  });

  final List<GroupProfile> myGroups;
  final bool isActive;

  @override
  ConsumerState<ConnectEventsTab> createState() => _ConnectEventsTabState();
}

class _ConnectEventsTabState extends ConsumerState<ConnectEventsTab>
    with ConnectLazyMyDiscoverTabMixin<ConnectEventsTab> {
  @override
  bool readTabActive(ConnectEventsTab widget) => widget.isActive;

  @override
  void loadActiveSegment() {
    if (!isTabActive) return;
    if (selectedSegment == 0) {
      ref.read(_myEventsProvider.notifier).ensureLoaded();
    } else {
      ref.read(discoverConnectEventsProvider.notifier).ensureLoaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch both providers unconditionally so they stay alive across
    // My/Discover segment switches; only `loadActiveSegment()` decides
    // when to actually fetch.
    final myState = ref.watch(_myEventsProvider);
    final discoverState = ref.watch(discoverConnectEventsProvider);

    return ConnectMyDiscoverTabGate(
      myHasLoaded: myState.hasLoaded,
      myIsEmpty: myState.events.isEmpty,
      myHasError: myState.error != null,
      onSegmentChanged: handleSegmentChanged,
      onMyRefresh: () => ref.read(_myEventsProvider.notifier).refresh(),
      onDiscoverRefresh:
          () => ref.read(discoverConnectEventsProvider.notifier).refresh(),
      onMyLoadMore: () => ref.read(_myEventsProvider.notifier).loadMore(),
      onDiscoverLoadMore:
          () => ref.read(discoverConnectEventsProvider.notifier).loadMore(),
      myBuilder: (context, switchToDiscover, scrollHeader) {
        return ConnectPaginatedListView(
          scrollViewKey: const PageStorageKey<String>('connect_events_my'),
          header: scrollHeader,
          useHairlineDividers: false,
          items: myState.events,
          isLoading: myState.isLoading,
          isLoadingMore: myState.isLoadingMore,
          error: myState.error,
          hasMore: myState.hasMore,
          hasLoaded: myState.hasLoaded,
          onRetry: () => ref.read(_myEventsProvider.notifier).retry(),
          myEmptyState: ConnectMyEmptyState(
            type: ConnectMyEmptyStateType.events,
            onBrowseTap: switchToDiscover,
          ),
          itemBuilder:
              (context, index) =>
                  ConnectEventCard(event: myState.events[index]),
        );
      },
      discoverBuilder: (context, _, scrollHeader) {
        return ConnectPaginatedListView(
          scrollViewKey: const PageStorageKey<String>(
            'connect_events_discover',
          ),
          header: scrollHeader,
          useHairlineDividers: false,
          items: discoverState.events,
          isLoading: discoverState.isLoading,
          isLoadingMore: discoverState.isLoadingMore,
          error: discoverState.error,
          hasMore: discoverState.hasMore,
          hasLoaded: discoverState.hasLoaded,
          onRetry:
              () => ref.read(discoverConnectEventsProvider.notifier).retry(),
          emptyDiscoverMessage: context.l10n.connect_empty_discover_events,
          itemBuilder:
              (context, index) =>
                  ConnectEventCard(event: discoverState.events[index]),
        );
      },
    );
  }
}
