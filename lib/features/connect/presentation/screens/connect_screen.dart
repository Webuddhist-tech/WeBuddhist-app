import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/screens/group_search_screen.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_events_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_groups_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_posts_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_practices_tab.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/followed_groups_row.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/chat_rooms_providers.dart';
import 'package:flutter_pecha/shared/widgets/main_tab_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _onGroupsRefresh() async {
    await Future.wait([
      ref.refresh(myGroupsProvider.future),
      ref.read(discoverGroupsProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final myGroupsAsync = ref.watch(myGroupsProvider);
    final pendingGroups = ref.watch(pendingJoinedGroupsProvider);
    final pendingUnjoinedIds = ref.watch(pendingUnjoinedGroupIdsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeTabIndex = _tabController.index;

    final apiGroups = myGroupsAsync.valueOrNull?.groups ?? const [];
    final displayedMyGroups = mergeMyGroupsWithPending(
      apiGroups: apiGroups,
      pendingGroups: pendingGroups,
      pendingUnjoinedIds: pendingUnjoinedIds,
    );
    final myGroupsLoading =
        myGroupsAsync.isLoading && displayedMyGroups.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: MainTabAppBar(
        title: context.l10n.nav_connect,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GroupSearchScreen(),
                ),
              );
            },
            icon: Icon(
              AppAssets.exploreUnselected,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: context.l10n.text_search,
          ),
          const _ChatsAction(),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: FollowedGroupsRow(
                  groups: displayedMyGroups,
                  isLoading: myGroupsLoading,
                ),
              ),
              SliverToBoxAdapter(
                child: _ConnectMainTabBar(
                  controller: _tabController,
                  isDark: isDark,
                ),
              ),
            ],
        body: TabBarView(
          controller: _tabController,
          children: [
            ConnectFeedTab(
              myGroups: displayedMyGroups,
              isActive: activeTabIndex == 0,
            ),
            ConnectEventsTab(
              myGroups: displayedMyGroups,
              isActive: activeTabIndex == 1,
            ),
            ConnectPostsTab(isActive: activeTabIndex == 2),
            ConnectPracticesTab(isActive: activeTabIndex == 3),
            ConnectGroupsTab(
              myGroups: displayedMyGroups,
              onRefresh: _onGroupsRefresh,
              isActive: activeTabIndex == 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectMainTabBar extends StatelessWidget {
  const _ConnectMainTabBar({required this.controller, required this.isDark});

  final TabController controller;
  final bool isDark;

  static const _labelStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final unselectedColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final labels = [
      context.l10n.connect_tab_feed,
      context.l10n.connect_tab_events,
      context.l10n.connect_tab_posts,
      context.l10n.connect_tab_practices,
      context.l10n.connect_tab_groups,
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: false,
        tabAlignment: TabAlignment.fill,
        padding: EdgeInsets.zero,
        labelColor: labelColor,
        unselectedLabelColor: unselectedColor,
        indicatorColor: labelColor,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: _labelStyle,
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          for (final label in labels)
            Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label))),
        ],
      ),
    );
  }
}

/// Opens the chats list, with a dot when anything is unread.
///
/// Watching `chatRoomsProvider` here is what loads it: there is no unread
/// endpoint, so the dot can only come from the rooms list (the notifier scans
/// past the page it shows, so the dot answers for every room) — and having
/// Connect hold that subscription means the Chats screen usually opens on data it
/// already has rather than fetching again.
class _ChatsAction extends ConsumerWidget {
  const _ChatsAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Members only, like every other action on this screen: a guest has no
    // rooms and no token to list them with, and the route is guest-blocked.
    // Decided before anything below is watched, so a guest never brings the
    // rooms list — and its requests — into being.
    final isMember = ref.watch(
      authProvider.select((auth) => auth.isLoggedIn && !auth.isGuest),
    );
    if (!isMember) return const SizedBox.shrink();

    // Keeps the push listener alive for as long as the dot is on screen.
    ref.watch(chatRoomsPushRefreshProvider);
    final hasUnread = ref.watch(chatRoomsProvider).hasUnread;
    final theme = Theme.of(context);

    return IconButton(
      onPressed: () => context.push(AppRoutes.chats),
      tooltip: context.l10n.chats_title,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(AppAssets.chatCircleDots, color: theme.colorScheme.onSurface),
          if (hasUnread)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  // Rings the dot in the bar's own colour so it stays legible
                  // where it overlaps the glyph.
                  border: Border.all(color: theme.scaffoldBackgroundColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
