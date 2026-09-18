import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/discover_group_card.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Groups tab content showing discover groups.
class ConnectGroupsTab extends ConsumerStatefulWidget {
  const ConnectGroupsTab({
    super.key,
    required this.myGroups,
    required this.onRefresh,
    this.isActive = true,
  });

  final List<GroupProfile> myGroups;
  final Future<void> Function() onRefresh;
  final bool isActive;

  @override
  ConsumerState<ConnectGroupsTab> createState() => _ConnectGroupsTabState();
}

class _ConnectGroupsTabState extends ConsumerState<ConnectGroupsTab> {
  static const _paginationThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _scheduleLoad();
    }
  }

  @override
  void didUpdateWidget(covariant ConnectGroupsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _scheduleLoad();
    }
  }

  void _scheduleLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isActive) return;
      ref.read(discoverGroupsProvider.notifier).ensureLoaded();
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.isActive) return false;
    if (notification.metrics.pixels <
        notification.metrics.maxScrollExtent - _paginationThreshold) {
      return false;
    }
    ref.read(discoverGroupsProvider.notifier).loadMore();
    return false;
  }

  List<GroupProfile> _discoverGroups(DiscoverGroupsState discoverState) {
    final joinedGroupIds = widget.myGroups.map((group) => group.id).toSet();
    return filterDiscoverGroups(
      discoverGroups: discoverState.groups,
      joinedGroupIds: joinedGroupIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverGroupsProvider);
    final discoverGroups = _discoverGroups(discoverState);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: ConnectPaginatedListView(
          scrollViewKey: const PageStorageKey<String>('connect_groups'),
          items: discoverGroups,
          isLoading: discoverState.isLoading,
          isLoadingMore: discoverState.isLoadingMore,
          error: discoverState.error,
          hasMore: discoverState.hasMore,
          hasLoaded: discoverState.hasLoaded,
          onRetry: () => ref.read(discoverGroupsProvider.notifier).retry(),
          emptyDiscoverMessage: context.l10n.connect_empty_discover_groups,
          useHairlineDividers: false,
          separatorHeight: 4,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemBuilder:
              (context, index) => DiscoverGroupCard(
                group: discoverGroups[index],
                showJoinButton: true,
              ),
        ),
      ),
    );
  }
}
