import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_events_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_event_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_paginated_list_view.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupEventsScreen extends ConsumerStatefulWidget {
  const GroupEventsScreen({super.key});

  @override
  ConsumerState<GroupEventsScreen> createState() => _GroupEventsScreenState();
}

class _GroupEventsScreenState extends ConsumerState<GroupEventsScreen>
    with SingleTickerProviderStateMixin {
  static const _paginationThreshold = 200.0;
  static const _filters = ConnectEventFormatFilter.values;

  late TabController _tabController;
  late final List<ScrollController> _scrollControllers;
  late final List<VoidCallback> _scrollListeners;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _scrollControllers = List.generate(
      _filters.length,
      (_) => ScrollController(),
    );
    _scrollListeners = List.generate(
      _filters.length,
      (index) => () => _onScroll(index),
    );
    for (var i = 0; i < _scrollControllers.length; i++) {
      _scrollControllers[i].addListener(_scrollListeners[i]);
    }
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    for (var i = 0; i < _scrollControllers.length; i++) {
      _scrollControllers[i].removeListener(_scrollListeners[i]);
      _scrollControllers[i].dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll(int tabIndex) {
    final controller = _scrollControllers[tabIndex];
    if (!controller.hasClients) return;
    if (controller.position.pixels <
        controller.position.maxScrollExtent - _paginationThreshold) {
      return;
    }
    ref.read(myConnectEventsProvider(_filters[tabIndex]).notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(l10n.home_group_events),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(AppAssets.arrowLeft),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GroupEventsTabBar(controller: _tabController, isDark: isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (var i = 0; i < _filters.length; i++)
                  _GroupEventsTabContent(
                    filter: _filters[i],
                    scrollController: _scrollControllers[i],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupEventsTabContent extends ConsumerWidget {
  const _GroupEventsTabContent({
    required this.filter,
    required this.scrollController,
  });

  final ConnectEventFormatFilter filter;
  final ScrollController scrollController;

  String? _emptyMessage(BuildContext context) {
    final l10n = context.l10n;
    return switch (filter) {
      ConnectEventFormatFilter.all => null,
      ConnectEventFormatFilter.online =>
        l10n.connect_events_filter_empty_online,
      ConnectEventFormatFilter.offline =>
        l10n.connect_events_filter_empty_in_person,
      ConnectEventFormatFilter.hybrid =>
        l10n.connect_events_filter_empty_hybrid,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = myConnectEventsProvider(filter);
    final state = ref.watch(provider);

    // Each tab fetches its own `event_format` listing the first time it builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(provider.notifier).ensureLoaded();
    });

    return RefreshIndicator(
      onRefresh: () => ref.read(provider.notifier).refresh(),
      child: ConnectPaginatedListView<GroupEvent>(
        items: state.events,
        isLoading: state.isLoading,
        isLoadingMore: state.isLoadingMore,
        error: state.error,
        hasMore: state.hasMore,
        hasLoaded: state.hasLoaded,
        scrollController: scrollController,
        onRetry: () => ref.read(provider.notifier).retry(),
        emptyDiscoverMessage: _emptyMessage(context),
        myEmptyState:
            filter == ConnectEventFormatFilter.all
                ? _GroupEventsEmptyState()
                : null,
        itemBuilder:
            (context, index) => ConnectEventCard(event: state.events[index]),
      ),
    );
  }
}

class _GroupEventsTabBar extends StatelessWidget {
  const _GroupEventsTabBar({required this.controller, required this.isDark});

  final TabController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final unselectedColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.grey800 : AppColors.grey300;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: TabBar(
        controller: controller,
        tabAlignment: TabAlignment.fill,
        labelColor: labelColor,
        unselectedLabelColor: unselectedColor,
        indicatorColor: labelColor,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        labelStyle: context.tabLabelStyle(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        unselectedLabelStyle: context.tabLabelStyle(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        tabs: [
          Tab(text: l10n.connect_events_filter_all),
          Tab(text: l10n.connect_online),
          Tab(text: l10n.connect_events_filter_in_person),
          Tab(text: l10n.connect_events_filter_hybrid),
        ],
      ),
    );
  }
}

class _GroupEventsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final subtitleColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.connect_my_empty_events_title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: titleColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.connect_my_empty_events_subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: subtitleColor, height: 1.5),
          ),
        ],
      ),
    );
  }
}
