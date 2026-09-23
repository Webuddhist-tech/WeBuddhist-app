import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/core/utils/url_opener.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_card_layout.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_practice_card.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_post_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_about_screen.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_post_composer_screen.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_join_request_drawer.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_join_requests_row.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_notification_settings_drawer.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_events_tab.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_profile_link_utils.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_links_drawer.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_members_tab.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_nested_tab_scroll_view.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_posts_tab.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class GroupProfileBody extends ConsumerStatefulWidget {
  final GroupProfile profile;
  final bool isDark;
  final VoidCallback? onSeriesTap;

  const GroupProfileBody({
    super.key,
    required this.profile,
    required this.isDark,
    this.onSeriesTap,
  });

  @override
  ConsumerState<GroupProfileBody> createState() => _GroupProfileBodyState();
}

enum _GroupProfileTab { posts, events, practices, members }

/// Matches the back-button row height in [GroupProfileScreen].
const _groupProfileAppBarHeight = 56.0;

class _GroupProfileBodyState extends ConsumerState<GroupProfileBody>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<_GroupProfileTab> _visibleTabs = const [];
  final GlobalKey _profileTitleKey = GlobalKey();
  String? _enrollingSeriesId;
  String? _joiningAccumulatorId;
  final Set<String> _localGroupEnrolledSeriesIds = {};
  ProviderSubscription<bool>? _membersTabActiveSub;
  ProviderSubscription<bool>? _membersNeedsRefreshSub;

  bool _isCommunityGroup(GroupProfile profile) => !profile.groupType.isPage;

  bool _canAccessPrivateGroupContent(GroupProfile profile) {
    if (!profile.isPrivateCommunity) return true;

    return isPrivateGroupMember(followState: _privateGroupFollowState(profile));
  }

  GroupFollowState _privateGroupFollowState(GroupProfile profile) {
    final followKey = GroupFollowKey(
      groupId: profile.id,
      groupType: profile.groupType,
    );
    return ref.watch(groupFollowProvider(followKey));
  }

  bool _isPrivateMembershipLoading(GroupProfile profile) {
    if (!profile.isPrivateCommunity) return false;
    return isPrivateGroupMembershipLoading(_privateGroupFollowState(profile));
  }

  bool _isContentRestricted(GroupProfile profile) {
    return profile.isPrivateCommunity &&
        !_canAccessPrivateGroupContent(profile);
  }

  Future<void> _onRefresh(GroupProfile profile) {
    return refreshGroupProfilePage(
      ref: ref,
      groupId: profile.id,
      groupType: profile.groupType,
    );
  }

  bool _hasBanner(GroupProfile profile) =>
      profile.bannerUrl != null && profile.bannerUrl!.isNotEmpty;

  String? _aboutDescription(GroupProfile profile) {
    final descriptionLong = profile.descriptionLong?.trim();
    if (descriptionLong != null && descriptionLong.isNotEmpty) {
      return descriptionLong;
    }

    final description = profile.description?.trim();
    if (description != null && description.isNotEmpty) {
      return description;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    if (_isCommunityGroup(widget.profile)) {
      // The tab set depends on which sections actually have content, so the
      // controller is created in build() once that data is known.

      final groupId = widget.profile.id;
      // Keep tab/refresh flags alive while this screen is mounted so join/unjoin
      // refresh logic can set and consume them reliably, without rebuilding
      // this widget when the flags change.
      _membersTabActiveSub = ref.listenManual(
        groupMembersTabActiveProvider(groupId),
        (_, _) {},
      );
      _membersNeedsRefreshSub = ref.listenManual(
        groupMembersNeedsRefreshProvider(groupId),
        (_, _) {},
      );
    }
  }

  /// Rebuilds the tab controller whenever the visible tab set changes, keeping
  /// the currently selected tab selected when it is still present.
  void _syncTabController(List<_GroupProfileTab> tabs) {
    final previous = _tabController;
    if (previous != null && listEquals(_visibleTabs, tabs)) return;

    final selectedTab =
        previous != null && previous.index < _visibleTabs.length
            ? _visibleTabs[previous.index]
            : null;
    var initialIndex = selectedTab == null ? -1 : tabs.indexOf(selectedTab);
    if (initialIndex < 0) initialIndex = tabs.indexOf(_GroupProfileTab.posts);
    if (initialIndex < 0) {
      initialIndex = tabs.indexOf(_GroupProfileTab.practices);
    }
    if (initialIndex < 0) initialIndex = 0;

    final controller = TabController(
      length: tabs.length,
      initialIndex: initialIndex,
      vsync: this,
    );
    controller.addListener(_onTabChanged);

    _visibleTabs = tabs;
    _tabController = controller;

    if (previous != null) {
      previous.removeListener(_onTabChanged);
      // The old TabBar/TabBarView still reference it for the current frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  void _onTabChanged() {
    final controller = _tabController;
    if (controller == null || controller.indexIsChanging) return;
    if (!mounted) return;

    final groupId = widget.profile.id;
    final isMembersTab =
        controller.index < _visibleTabs.length &&
        _visibleTabs[controller.index] == _GroupProfileTab.members;
    ref.read(groupMembersTabActiveProvider(groupId).notifier).state =
        isMembersTab;

    if (isMembersTab && ref.read(groupMembersNeedsRefreshProvider(groupId))) {
      ref.read(groupMembersNeedsRefreshProvider(groupId).notifier).state =
          false;
      if (ref.exists(groupMembersProvider(groupId))) {
        ref.read(groupMembersProvider(groupId).notifier).loadInitial();
      }
    }
  }

  bool _onTabScrollLoadMore(
    ScrollNotification notification,
    VoidCallback loadMore,
  ) {
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 200) {
      loadMore();
    }
    return false;
  }

  void _syncPracticeEnrollmentFromList(List<GroupPractice> practices) {
    final accumulators =
        practices
            .where((practice) => practice.type == GroupPracticeType.accumulator)
            .map((practice) => practice.accumulator)
            .whereType<GroupAccumulator>()
            .toList();
    ref
        .read(groupAccumulatorJoinCacheProvider(widget.profile.id).notifier)
        .syncFromApi(accumulators);

    final apiEnrolledIds =
        practices
            .where(
              (practice) =>
                  practice.series != null &&
                  practice.series!.isGroupEnrolled == true,
            )
            .map((practice) => practice.series!.id)
            .toSet();
    final apiNotEnrolledIds = practices
        .where(
          (practice) =>
              practice.series != null &&
              practice.series!.isGroupEnrolled == null,
        )
        .map((practice) => practice.series!.id);
    setState(() {
      _localGroupEnrolledSeriesIds.addAll(apiEnrolledIds);
      _localGroupEnrolledSeriesIds.removeAll(apiNotEnrolledIds);
    });
  }

  @override
  void deactivate() {
    super.deactivate();
    // Popping this route deactivates the widget during the Navigator rebuild.
    // Riverpod forbids provider writes in that window, so reset the collapsed
    // title after the current frame. Capture the container because `ref` is
    // invalid once dispose() runs at the end of the same frame.
    final String groupId = widget.profile.id;
    final ProviderContainer container = ProviderScope.containerOf(context);
    Future<void>(() {
      final provider = groupProfileAppBarTitleVisibleProvider(groupId);
      if (!container.exists(provider)) return;
      container.read(provider.notifier).state = false;
    });
  }

  @override
  void dispose() {
    _membersTabActiveSub?.close();
    _membersNeedsRefreshSub?.close();
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  void _syncAppBarTitleVisibility() {
    if (!mounted) return;

    final titleContext = _profileTitleKey.currentContext;
    if (titleContext == null) return;

    final renderBox = titleContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final titleBottom =
        renderBox.localToGlobal(Offset(0, renderBox.size.height)).dy;
    final collapseThreshold =
        MediaQuery.paddingOf(titleContext).top + _groupProfileAppBarHeight;
    final shouldShow = titleBottom <= collapseThreshold;

    final groupId = widget.profile.id;
    final current = ref.read(groupProfileAppBarTitleVisibleProvider(groupId));
    if (current != shouldShow) {
      ref.read(groupProfileAppBarTitleVisibleProvider(groupId).notifier).state =
          shouldShow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final followKey = GroupFollowKey(
      groupId: widget.profile.id,
      groupType: widget.profile.groupType,
    );
    ref.listen(groupFollowProvider(followKey), (previous, next) {
      if (next case GroupFollowSuccess(isFollowing: false)) {
        setState(_localGroupEnrolledSeriesIds.clear);
        ref
            .read(groupAccumulatorJoinCacheProvider(widget.profile.id).notifier)
            .clear();
        refreshGroupPractices(ref, widget.profile.id);
      }
    });

    final locale = Localizations.localeOf(context);
    final lineHeight = getLineHeight(locale.languageCode);
    final profile = _resolveProfile();
    final isDark = widget.isDark;

    if (_isCommunityGroup(profile) &&
        !_isPrivateMembershipLoading(profile) &&
        !_isContentRestricted(profile)) {
      ref.listen(groupPracticesProvider(widget.profile.id), (previous, next) {
        if (next.isLoading && next.practices.isEmpty) return;
        _syncPracticeEnrollmentFromList(next.practices);
      });
    }

    final enrollingId = _enrollingSeriesId;
    if (enrollingId != null) {
      // Keep the autoDispose enrollment provider alive while the request is
      // in flight — otherwise it can be disposed before the API returns.
      ref.watch(seriesEnrollmentProvider(enrollingId));
    }

    final orderedLinks = GroupProfileLinkUtils.orderedLinks(
      profile.socialLinks,
    );

    if (_isCommunityGroup(profile)) {
      return _buildCommunityProfileBody(
        profile,
        isDark,
        lineHeight,
        orderedLinks,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(profile),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasBanner(profile)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildProfileBanner(profile, isDark),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _buildProfileHeader(
                    profile,
                    isDark,
                    lineHeight,
                    orderedLinks,
                  ),
                  const SizedBox(height: 20),
                  _buildDescriptionLongContent(profile),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommunityProfileBody(
    GroupProfile profile,
    bool isDark,
    double? lineHeight,
    List<GroupProfileSocialLink> orderedLinks,
  ) {
    if (_isPrivateMembershipLoading(profile)) {
      return _buildPrivateMembershipLoadingProfile(
        profile,
        isDark,
        lineHeight,
        orderedLinks,
      );
    }

    if (_isContentRestricted(profile)) {
      return _buildRestrictedCommunityProfile(
        profile,
        isDark,
        lineHeight,
        orderedLinks,
      );
    }

    final (hasPractices, isPracticesLoading) = ref.watch(
      groupPracticesProvider(profile.id).select(
        (state) => (
          state.practices.isNotEmpty,
          state.isLoading && state.practices.isEmpty,
        ),
      ),
    );
    final eventsAsync = ref.watch(groupEventsProvider(profile.id));
    // Keep the events tab when loading failed so its retry action stays
    // reachable.
    final hasEvents = eventsAsync.maybeWhen(
      data:
          (either) =>
              either.fold((_) => true, (page) => page.events.isNotEmpty),
      error: (_, _) => true,
      orElse: () => false,
    );
    final isEventsLoading =
        eventsAsync.isLoading && !eventsAsync.hasValue && !eventsAsync.hasError;

    final postsState = ref.watch(groupPostsProvider(profile.id));
    final permissionAsync = ref.watch(groupPostPermissionProvider(profile.id));
    final canPost = permissionAsync.valueOrNull ?? false;
    // Keep the posts tab when loading failed so its retry action stays
    // reachable, and for anyone allowed to publish so the Post button shows.
    final hasPosts =
        postsState.posts.isNotEmpty ||
        (postsState.hasLoaded && postsState.error != null);
    final isPostsLoading =
        !postsState.hasLoaded ||
        (permissionAsync.isLoading &&
            !permissionAsync.hasValue &&
            !permissionAsync.hasError);

    // Wait for every section before laying out the tabs, otherwise tabs would
    // pop in and out as each request settles.
    final isTabDataLoading =
        isPracticesLoading || isEventsLoading || isPostsLoading;
    final tabs = <_GroupProfileTab>[
      if (hasPosts || canPost) _GroupProfileTab.posts,
      if (hasEvents) _GroupProfileTab.events,
      if (hasPractices) _GroupProfileTab.practices,
      _GroupProfileTab.members,
    ];
    if (!isTabDataLoading) _syncTabController(tabs);
    final controller = _tabController;

    return RefreshIndicator(
      onRefresh: () => _onRefresh(profile),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification ||
              notification is ScrollEndNotification) {
            _syncAppBarTitleVisibility();
          }
          return false;
        },
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, _) {
            final slivers = <Widget>[
              SliverToBoxAdapter(
                child: _buildCommunityHeaderSection(
                  profile,
                  isDark,
                  lineHeight,
                  orderedLinks,
                ),
              ),
            ];

            if (controller != null) {
              slivers.add(
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                  sliver: SliverPersistentHeader(
                    pinned: true,
                    delegate: _GroupProfileTabBarDelegate(
                      tabBar: _buildTabBar(isDark, profile),
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),
              );
            }

            return slivers;
          },
          body:
              controller == null
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                    controller: controller,
                    children: [
                      for (final tab in _visibleTabs)
                        _buildTabContent(tab, profile, isDark, lineHeight),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildRestrictedCommunityProfile(
    GroupProfile profile,
    bool isDark,
    double? lineHeight,
    List<GroupProfileSocialLink> orderedLinks,
  ) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(profile),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification ||
              notification is ScrollEndNotification) {
            _syncAppBarTitleVisibility();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildCommunityHeaderSection(
                profile,
                isDark,
                lineHeight,
                orderedLinks,
                bottomSpacing: 0,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildRestrictedMessage(
                  isDark,
                  lineHeight,
                  profile.myJoinRequestStatus,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateMembershipLoadingProfile(
    GroupProfile profile,
    bool isDark,
    double? lineHeight,
    List<GroupProfileSocialLink> orderedLinks,
  ) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(profile),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification ||
              notification is ScrollEndNotification) {
            _syncAppBarTitleVisibility();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildCommunityHeaderSection(
                profile,
                isDark,
                lineHeight,
                orderedLinks,
                bottomSpacing: 0,
              ),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityHeaderSection(
    GroupProfile profile,
    bool isDark,
    double? lineHeight,
    List<GroupProfileSocialLink> orderedLinks, {
    double bottomSpacing = 24,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasBanner(profile)) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildProfileBanner(profile, isDark),
          ),
          const SizedBox(height: 14),
        ],
        _buildProfileHeader(profile, isDark, lineHeight, orderedLinks),
        const SizedBox(height: 20),
        _GroupFollowButton(profile: profile, isDark: isDark),
        SizedBox(
          height:
              _showsAdminJoinRequestsRow(profile) ? 8 : bottomSpacing,
        ),
      ],
    );
  }

  bool _showsAdminJoinRequestsRow(GroupProfile profile) {
    if (!profile.isPrivateCommunity || _isContentRestricted(profile)) {
      return false;
    }
    return ref
            .watch(groupMyPermissionProvider(profile.id))
            .valueOrNull
            ?.isGroupAdmin ??
        false;
  }

  Widget _buildRestrictedMessage(
    bool isDark,
    double? lineHeight,
    GroupJoinRequestStatus? joinRequestStatus,
  ) {
    final isPending = joinRequestStatus == GroupJoinRequestStatus.pending;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPending ? AppAssets.homeTimer : AppAssets.lock,
            size: 28,
            color: titleColor,
          ),
          const SizedBox(height: 16),
          Text(
            isPending
                ? context.l10n.group_join_request_waiting_title
                : context.l10n.group_members_only_title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
              height: lineHeight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? context.l10n.group_join_request_waiting_message
                : context.l10n.group_members_only_message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: secondaryColor,
              height: lineHeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    _GroupProfileTab tab,
    GroupProfile profile,
    bool isDark,
    double? lineHeight,
  ) {
    final pageStorageKey = '${profile.id}-${tab.name}';

    return switch (tab) {
      _GroupProfileTab.posts => GroupProfilePostsTab(
        groupId: profile.id,
        isDark: isDark,
        lineHeight: lineHeight,
        pageStorageKey: pageStorageKey,
        canPost: ref.watch(
          groupPostPermissionProvider(
            profile.id,
          ).select((async) => async.valueOrNull ?? false),
        ),
        onCreatePost: () => _onCreatePost(profile),
        onEditPost: (post) => _onEditPost(profile, post),
      ),
      _GroupProfileTab.events => GroupProfileEventsTab(
        groupId: profile.id,
        isDark: isDark,
        lineHeight: lineHeight,
        pageStorageKey: pageStorageKey,
      ),
      _GroupProfileTab.practices => _buildPracticesTab(
        profile,
        isDark,
        pageStorageKey: pageStorageKey,
      ),
      _GroupProfileTab.members => GroupProfileMembersTab(
        groupId: profile.id,
        groupType: profile.groupType,
        isDark: isDark,
        lineHeight: lineHeight,
        pageStorageKey: pageStorageKey,
      ),
    };
  }

  Future<void> _onCreatePost(GroupProfile profile) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final result = await GroupPostComposerScreen.show(context, profile);
    if (result == null || !mounted) return;

    final notifier = ref.read(groupPostsProvider(profile.id).notifier);
    notifier.prependPost(_withGroupFields(result.post, profile));
    notifier.loadInitial();
    if (result.saved) _showPostSnackBar(context.l10n.group_post_published);
  }

  Future<void> _onEditPost(GroupProfile profile, ConnectPost post) async {
    final result = await GroupPostComposerScreen.show(
      context,
      profile,
      post: post,
    );
    if (result == null || !mounted) return;

    // CMS responses don't carry the viewer's like state; keep what we had.
    final merged = _withGroupFields(result.post, profile).copyWith(
      likeCount: post.likeCount,
      commentCount: post.commentCount,
      likedByMe: post.likedByMe,
    );
    final notifier = ref.read(groupPostsProvider(profile.id).notifier);
    notifier.updatePost(merged);
    notifier.loadInitial();
    // A partial save already showed its error inside the composer.
    if (result.saved) _showPostSnackBar(context.l10n.group_post_updated);
  }

  /// CMS responses may omit group fields the card needs; fill them from the
  /// profile. The list is refetched right after so it reflects the server.
  ConnectPost _withGroupFields(ConnectPost post, GroupProfile profile) {
    return ConnectPost(
      id: post.id,
      groupId: post.groupId.isNotEmpty ? post.groupId : profile.id,
      groupName:
          post.groupName.trim().isNotEmpty ? post.groupName : profile.title,
      groupAvatarUrl: post.groupAvatarUrl ?? profile.avatarUrl,
      caption: post.caption,
      status: post.status,
      publishedAt: post.publishedAt ?? DateTime.now(),
      media: post.media,
      links: post.links,
      creatorName: post.creatorName,
      creatorImageUrl: post.creatorImageUrl,
      likeCount: post.likeCount,
      commentCount: post.commentCount,
      createdAt: post.createdAt ?? DateTime.now(),
      updatedAt: post.updatedAt,
      likedByMe: post.likedByMe,
    );
  }

  void _showPostSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  GroupProfile _resolveProfile() {
    final freshProfile = ref.watch(groupProfileProvider(widget.profile.id));
    return freshProfile.maybeWhen(
      data:
          (either) => either.fold((_) => widget.profile, (profile) => profile),
      orElse: () => widget.profile,
    );
  }

  bool? _seriesGroupEnrollmentStatus(GroupProfileSeries series) {
    return seriesGroupEnrollmentStatus(
      series,
      localEnrolledSeriesIds: _localGroupEnrolledSeriesIds,
    );
  }

  Widget _buildProfileHeader(
    GroupProfile profile,
    bool isDark,
    double? lineHeight,
    List<GroupProfileSocialLink> orderedLinks,
  ) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final memberCount = profile.memberOrFollowerCount;
    final memberLabel =
        profile.groupType.isPage
            ? (memberCount == 1
                ? context.l10n.group_follower
                : context.l10n.group_followers)
            : (memberCount == 1
                ? context.l10n.group_member
                : context.l10n.group_members);
    final formattedCount = _formatCompactCount(
      memberCount,
      intlFormatLocaleOf(context),
    );
    final countLabel =
        context.isTibetanLocale
            ? '$memberLabel ${toTibetanDigits(formattedCount)}'
            : '$formattedCount $memberLabel';
    final aboutDescription =
        _isCommunityGroup(profile) ? _aboutDescription(profile) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child:
                      profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageWidget(
                            key: ValueKey(profile.avatarUrl),
                            imageUrl: profile.avatarUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorWidget: _buildAvatarFallback(isDark),
                          )
                          : _buildAvatarFallback(isDark),
                ),
              ),
              const SizedBox(width: 12),
              if (profile.title.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.title,
                        key: _profileTitleKey,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                          height: lineHeight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        countLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                          height: lineHeight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (aboutDescription != null) ...[
            const SizedBox(height: 8),
            _buildHeaderAboutDescription(
              profile,
              aboutDescription,
              orderedLinks,
              isDark,
              lineHeight,
            ),
          ] else if (profile.subTitle != null &&
              profile.subTitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.subTitle!,
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
                height: lineHeight,
              ),
            ),
          ],
          if (orderedLinks.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildLinksEntryRow(profile, orderedLinks, isDark, lineHeight),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderAboutDescription(
    GroupProfile profile,
    String description,
    List<GroupProfileSocialLink> orderedLinks,
    bool isDark,
    double? lineHeight,
  ) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = TextStyle(
          fontSize: 13,
          color: secondaryColor,
          height: lineHeight,
        );
        final textDirection = Directionality.of(context);
        final textScaler = MediaQuery.textScalerOf(context);

        bool exceedsTwoLines(InlineSpan span) {
          final painter = TextPainter(
            text: span,
            maxLines: 2,
            textDirection: textDirection,
            textScaler: textScaler,
          );
          painter.layout(maxWidth: constraints.maxWidth);
          return painter.didExceedMaxLines;
        }

        void openAboutScreen() {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => GroupAboutScreen(
                    title: profile.title,
                    description: description,
                    links: orderedLinks,
                  ),
            ),
          );
        }

        Widget tappableDescription({required bool truncate}) {
          return GestureDetector(
            onTap: openAboutScreen,
            behavior: HitTestBehavior.opaque,
            child: Text(
              description,
              maxLines: 2,
              overflow: truncate ? TextOverflow.ellipsis : TextOverflow.clip,
              style: style,
              textScaler: textScaler,
            ),
          );
        }

        final textSpan = TextSpan(text: description, style: style);
        if (!exceedsTwoLines(textSpan)) {
          return tappableDescription(truncate: false);
        }

        return tappableDescription(truncate: true);
      },
    );
  }

  Widget _buildAvatarFallback(bool isDark) {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.usersThree,
        size: 22,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }

  Widget _buildLinksEntryRow(
    GroupProfile profile,
    List<GroupProfileSocialLink> links,
    bool isDark,
    double? lineHeight,
  ) {
    final primaryLink = links.first;
    final moreCount = links.length - 1;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return GestureDetector(
      onTap: () {
        if (moreCount > 0) {
          GroupProfileLinksDrawer.show(context, links);
        } else {
          _launchUrl(primaryLink.url);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(AppAssets.linkSimple, size: 18, color: secondaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                  height: lineHeight,
                ),
                children: [
                  TextSpan(text: primaryLink.url),
                  if (moreCount > 0)
                    TextSpan(
                      text: ' ${context.l10n.group_and_more_links(moreCount)}',
                      style: TextStyle(color: secondaryColor),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark, GroupProfile profile) {
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final dividerColor = isDark ? AppColors.grey800 : AppColors.grey300;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabController!,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: labelColor,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            for (final tab in _visibleTabs) Tab(text: _tabLabel(tab, profile)),
          ],
        ),
        Divider(height: 1, thickness: 1, color: dividerColor),
      ],
    );
  }

  String _tabLabel(_GroupProfileTab tab, GroupProfile profile) {
    return switch (tab) {
      _GroupProfileTab.posts => context.l10n.group_tab_posts,
      _GroupProfileTab.events => context.l10n.group_tab_events,
      _GroupProfileTab.practices => context.l10n.tab_practices,
      _GroupProfileTab.members =>
        profile.groupType.isPage
            ? context.l10n.group_tab_followers
            : context.l10n.group_tab_members,
    };
  }

  Widget _buildPracticesTab(
    GroupProfile profile,
    bool isDark, {
    required String pageStorageKey,
  }) {
    final practicesState = ref.watch(groupPracticesProvider(profile.id));

    if (practicesState.isLoading && practicesState.practices.isEmpty) {
      return GroupProfileNestedTabScrollView.centered(
        pageStorageKey: pageStorageKey,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (practicesState.practices.isEmpty) {
      return GroupProfileNestedTabScrollView(
        pageStorageKey: pageStorageKey,
        slivers: const [SliverToBoxAdapter(child: SizedBox.shrink())],
      );
    }

    final itemCount =
        practicesState.practices.length +
        (practicesState.isLoadingMore ? 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification:
          (notification) => _onTabScrollLoadMore(
            notification,
            () =>
                ref
                    .read(groupPracticesProvider(profile.id).notifier)
                    .loadMore(),
          ),
      child: GroupProfileNestedTabScrollView(
        pageStorageKey: pageStorageKey,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(
              top: ConnectFeedCardLayout.listItemGap,
              bottom: 32,
            ),
            sliver: SliverList.separated(
              itemCount: itemCount,
              separatorBuilder:
                  (context, _) => ColoredBox(
                    color: ConnectFeedCardLayout.listGapColor(isDark),
                    child: const SizedBox(
                      height: ConnectFeedCardLayout.listItemGap,
                    ),
                  ),
              itemBuilder: (context, index) {
                if (index >= practicesState.practices.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return _buildPracticeCard(
                  profile,
                  practicesState.practices[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeCard(GroupProfile profile, GroupPractice practice) {
    final withGroup = practice.copyWith(
      groupId: profile.id,
      groupName: practice.groupName ?? profile.title,
      groupAvatarUrl: practice.groupAvatarUrl ?? profile.avatarUrl,
    );
    final series = practice.series;
    final accumulator = practice.accumulator;

    return ConnectPracticeCard(
      practice: withGroup,
      showGroupLink: false,
      isSeriesEnrolled:
          series != null ? _seriesGroupEnrollmentStatus(series) == true : null,
      isEnrollingSeries:
          series != null ? _enrollingSeriesId == series.id : null,
      onSeriesTap:
          series != null ? () => _navigateToSeriesDetail(profile, series) : null,
      onSeriesJoinTap:
          series != null ? () => _onPracticeWithUsTap(profile, series) : null,
      isJoiningAccumulator:
          accumulator != null
              ? _joiningAccumulatorId == accumulator.id
              : null,
      onAccumulatorTap:
          accumulator != null
              ? () => _navigateToAccumulatorDetail(accumulator.id)
              : null,
      onAccumulatorJoinTap:
          accumulator != null
              ? () => _onJoinAccumulatorTap(profile, accumulator)
              : null,
    );
  }

  void _navigateToAccumulatorDetail(String accumulatorId) {
    context.push(
      '/home/group-accumulator/$accumulatorId',
      extra: {'groupTitle': _resolveProfile().title},
    );
  }

  Future<void> _onJoinAccumulatorTap(
    GroupProfile profile,
    GroupAccumulator accumulator,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() => _joiningAccumulatorId = accumulator.id);
    final ok = await joinGroupAccumulator(
      ref: ref,
      accumulatorId: accumulator.id,
      groupId: profile.id,
      group: profile,
      awaitRefresh: false,
    );

    if (!mounted) return;
    setState(() => _joiningAccumulatorId = null);

    if (ok) {
      _navigateToAccumulatorDetail(accumulator.id);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.group_accumulator_join_error),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildProfileBanner(GroupProfile profile, bool isDark) {
    if (!_hasBanner(profile)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 3.5,
          child: CachedNetworkImageWidget(
            key: ValueKey(profile.bannerUrl),
            imageUrl: profile.bannerUrl,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionLongContent(GroupProfile profile) {
    final content = _aboutDescription(profile);
    if (content == null) {
      return const SizedBox.shrink();
    }

    final bodyFontSize = getLocalizedFontSize(AppTextSize.body);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: PlanInlineMarkdownView(content: content, fontSize: bodyFontSize),
    );
  }

  String _formatCompactCount(int count, String locale) {
    if (count >= 1000000) {
      final value = count / 1000000;
      return '${_trimTrailingZero(value.toStringAsFixed(1))}M';
    }
    if (count >= 1000) {
      final value = count / 1000;
      return '${_trimTrailingZero(value.toStringAsFixed(1))}k';
    }
    return NumberFormat.decimalPattern(locale).format(count);
  }

  String _trimTrailingZero(String value) {
    return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
  }

  void _navigateToSeriesDetail(
    GroupProfile profile,
    GroupProfileSeries series,
  ) {
    widget.onSeriesTap?.call();
    if (_seriesGroupEnrollmentStatus(series) == true) {
      context.push('/home/series/${series.id}');
      return;
    }

    context.push(
      '/home/series/${series.id}',
      extra: {
        'groupId': profile.id,
        'groupType': profile.groupType,
        'isGroupEnrolled': false,
      },
    );
  }

  Future<void> _onPracticeWithUsTap(
    GroupProfile profile,
    GroupProfileSeries series,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final enrollmentStatus = _seriesGroupEnrollmentStatus(series);
    final confirmed = await confirmGroupPracticeChangeIfNeeded(
      context,
      enrollmentStatus,
    );
    if (!confirmed || !mounted) return;

    setState(() => _enrollingSeriesId = series.id);

    final ok = await enrollSeriesThroughGroup(
      ref: ref,
      seriesId: series.id,
      groupId: profile.id,
      groupType: profile.groupType,
    );

    if (!mounted) return;
    setState(() {
      _enrollingSeriesId = null;
      if (ok) _localGroupEnrolledSeriesIds.add(series.id);
    });

    if (ok) {
      await ref.read(groupProfileProvider(profile.id).future);
      if (!mounted) return;
      await context.pushNamed(
        'edit-routine',
        extra: {'enrollSeriesId': series.id},
      );
      if (!mounted) return;
      await completeGroupPracticeEnrollmentFlow(
        ref: ref,
        groupId: profile.id,
        groupType: profile.groupType,
      );
      return;
    }

    final state = ref.read(seriesEnrollmentProvider(series.id));
    final message =
        state is SeriesEnrollmentFailure
            ? state.failure.message
            : context.l10n.series_enroll_error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _launchUrl(String url) => openUrl(url);
}

class _GroupFollowButton extends ConsumerWidget {
  final GroupProfile profile;
  final bool isDark;

  const _GroupFollowButton({required this.profile, required this.isDark});

  Future<void> _onInvitePressed(BuildContext context, WidgetRef ref) async {
    final shareMessage = context.l10n.share_group_invite_message;
    final longUrl =
        DeepLinkUrlBuilder.groupLink(groupId: profile.id).toString();
    final shareUrl = await resolveShareUrlRef(ref, longUrl);
    if (!context.mounted) return;

    final sharePositionOrigin = getSharePositionOrigin(context: context);
    await SharePlus.instance.share(
      ShareParams(
        text: '$shareMessage\n\n$shareUrl',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  Future<void> _onRequestToJoinPressed(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final sent = await GroupJoinRequestDrawer.show(context, profile);
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.group_join_request_sent_snackbar),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profile.isPrivateCommunity) {
      return _buildPrivateCommunityActions(context, ref);
    }

    return _buildPublicCommunityActions(context, ref);
  }

  Widget _buildPrivateCommunityActions(BuildContext context, WidgetRef ref) {
    final followKey = GroupFollowKey(
      groupId: profile.id,
      groupType: profile.groupType,
    );
    final followState = ref.watch(groupFollowProvider(followKey));
    final isFollowing = switch (followState) {
      GroupFollowSuccess(isFollowing: final f) => f,
      _ => false,
    };
    final isLoading = followState is GroupFollowLoading;
    final joinRequestStatus = profile.myJoinRequestStatus;

    if (isPrivateGroupMembershipLoading(followState)) {
      return _buildPrivateMembershipLoadingButton(context);
    }

    if (isPrivateGroupMember(followState: followState)) {
      final isAdmin =
          ref
              .watch(groupMyPermissionProvider(profile.id))
              .valueOrNull
              ?.isGroupAdmin ??
          false;
      return Column(
        children: [
          _buildJoinedActions(
            context,
            ref,
            followKey,
            isFollowing,
            isLoading,
          ),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            GroupJoinRequestsRow(groupId: profile.id, isDark: isDark),
          ],
        ],
      );
    }

    if (joinRequestStatus == GroupJoinRequestStatus.pending) {
      return _buildRequestSentButton(context);
    }

    return _buildRequestToJoinButton(context, ref, isLoading);
  }

  Widget _buildPublicCommunityActions(BuildContext context, WidgetRef ref) {
    final followKey = GroupFollowKey(
      groupId: profile.id,
      groupType: profile.groupType,
    );
    final followState = ref.watch(groupFollowProvider(followKey));
    final isFollowing = switch (followState) {
      GroupFollowSuccess(isFollowing: final f) => f,
      _ => false,
    };
    final isLoading = followState is GroupFollowLoading;
    final isPage = profile.groupType.isPage;

    if (isFollowing && !isPage) {
      return _buildJoinedActions(
        context,
        ref,
        followKey,
        isFollowing,
        isLoading,
      );
    }

    return _buildPrimaryFollowButton(
      context,
      ref,
      followKey,
      isFollowing,
      isLoading,
      isPage,
    );
  }

  Widget _buildJoinedActions(
    BuildContext context,
    WidgetRef ref,
    GroupFollowKey followKey,
    bool isFollowing,
    bool isLoading,
  ) {
    const fontSize = 16.0;
    final locale = Localizations.localeOf(context);
    final isTibetan = context.isTibetanLocale;
    final buttonHeight = isTibetan ? 52.0 : 48.0;
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: Size(0, buttonHeight),
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isTibetan ? 10 : 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    );

    final authState = ref.watch(authProvider);
    final showChat = isFollowing && authState.isLoggedIn && !authState.isGuest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          if (showChat) ...[
            IconButton(
              onPressed:
                  () => context.push(AppRoutes.groupChatPath(profile.id)),
              tooltip: context.l10n.group_chat_open,
              icon: const Icon(AppAssets.chatCircleDots),
              style: IconButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
                foregroundColor:
                    isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                shape: const CircleBorder(),
                fixedSize: Size.square(buttonHeight),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              // Opens the member menu (notification toggles + leave). Leaving
              // is confirmed inside the sheet, never on a bare tap here.
              onPressed:
                  isLoading
                      ? null
                      : () => _openMemberMenu(context, followKey),
              style: buttonStyle.copyWith(
                backgroundColor: WidgetStatePropertyAll(
                  isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
                ),
                foregroundColor: WidgetStatePropertyAll(
                  isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                ),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              context.l10n.joined,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              strutStyle: context.tibetanStrutStyle(fontSize),
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                                fontFamily: getSystemFontFamily(
                                  locale.languageCode,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(AppAssets.caretDown, size: 18),
                        ],
                      ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _onInvitePressed(context, ref),
              style: buttonStyle.copyWith(
                backgroundColor: WidgetStatePropertyAll(
                  isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                ),
                foregroundColor: WidgetStatePropertyAll(
                  isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                ),
              ),
              child: Text(
                context.l10n.group_invite,
                textAlign: TextAlign.center,
                strutStyle: context.tibetanStrutStyle(fontSize),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: getSystemFontFamily(locale.languageCode),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateMembershipLoadingButton(BuildContext context) {
    final isTibetan = context.isTibetanLocale;
    final buttonHeight = isTibetan ? 52.0 : 48.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor:
                isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestSentButton(BuildContext context) {
    const fontSize = 16.0;
    final locale = Localizations.localeOf(context);
    final isTibetan = context.isTibetanLocale;
    final buttonHeight = isTibetan ? 52.0 : 48.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, buttonHeight),
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isTibetan ? 10 : 12,
            ),
            disabledBackgroundColor:
                isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            disabledForegroundColor:
                isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          child: Text(
            context.l10n.group_request_sent,
            textAlign: TextAlign.center,
            strutStyle: context.tibetanStrutStyle(fontSize),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              fontFamily: getSystemFontFamily(locale.languageCode),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestToJoinButton(
    BuildContext context,
    WidgetRef ref,
    bool isLoading,
  ) {
    const fontSize = 16.0;
    final locale = Localizations.localeOf(context);
    final isTibetan = context.isTibetanLocale;
    final buttonHeight = isTibetan ? 52.0 : 48.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              isLoading ? null : () => _onRequestToJoinPressed(context, ref),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, buttonHeight),
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isTibetan ? 10 : 12,
            ),
            backgroundColor:
                isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
            foregroundColor:
                isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          child:
              isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(
                    context.l10n.group_request_to_join,
                    textAlign: TextAlign.center,
                    strutStyle: context.tibetanStrutStyle(fontSize),
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      fontFamily: getSystemFontFamily(locale.languageCode),
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildPrimaryFollowButton(
    BuildContext context,
    WidgetRef ref,
    GroupFollowKey followKey,
    bool isFollowing,
    bool isLoading,
    bool isPage,
  ) {
    const fontSize = 16.0;
    final locale = Localizations.localeOf(context);
    final isTibetan = context.isTibetanLocale;
    final buttonHeight = isTibetan ? 52.0 : 48.0;
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: Size(0, buttonHeight),
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isTibetan ? 10 : 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    );

    final authState = ref.watch(authProvider);
    final showChat = isFollowing && authState.isLoggedIn && !authState.isGuest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child:
          isFollowing
              ? Row(
                children: [
                  if (showChat) ...[
                    IconButton(
                      onPressed:
                          () =>
                              context.push(AppRoutes.groupChatPath(profile.id)),
                      tooltip: context.l10n.group_chat_open,
                      icon: const Icon(AppAssets.chatCircleDots),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.grey100,
                        foregroundColor:
                            isDark
                                ? AppColors.surfaceWhite
                                : AppColors.textPrimary,
                        shape: const CircleBorder(),
                        fixedSize: Size.square(buttonHeight),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () => _onFollowPressed(
                                context,
                                ref,
                                followKey,
                                isFollowing,
                              ),
                      style: buttonStyle.copyWith(
                        backgroundColor: WidgetStatePropertyAll(
                          isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.grey100,
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          isDark
                              ? AppColors.surfaceWhite
                              : AppColors.textPrimary,
                        ),
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                isPage
                                    ? context.l10n.following
                                    : context.l10n.joined,
                                textAlign: TextAlign.center,
                                strutStyle: context.tibetanStrutStyle(fontSize),
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: getSystemFontFamily(
                                    locale.languageCode,
                                  ),
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _onInvitePressed(context, ref),
                      style: buttonStyle.copyWith(
                        backgroundColor: WidgetStatePropertyAll(
                          isDark
                              ? AppColors.surfaceWhite
                              : AppColors.textPrimary,
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          isDark
                              ? AppColors.textPrimary
                              : AppColors.surfaceWhite,
                        ),
                      ),
                      child: Text(
                        context.l10n.group_invite,
                        textAlign: TextAlign.center,
                        strutStyle: context.tibetanStrutStyle(fontSize),
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          fontFamily: getSystemFontFamily(locale.languageCode),
                        ),
                      ),
                    ),
                  ),
                ],
              )
              : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () => _onFollowPressed(
                            context,
                            ref,
                            followKey,
                            isFollowing,
                          ),
                  style: buttonStyle.copyWith(
                    backgroundColor: WidgetStatePropertyAll(
                      isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                    ),
                    minimumSize: WidgetStatePropertyAll(
                      Size(double.infinity, buttonHeight),
                    ),
                  ),
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            isPage ? context.l10n.follow : context.l10n.join,
                            textAlign: TextAlign.center,
                            strutStyle: context.tibetanStrutStyle(fontSize),
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                              fontFamily: getSystemFontFamily(
                                locale.languageCode,
                              ),
                            ),
                          ),
                ),
              ),
    );
  }

  /// Shows the member sheet and acts on its result from this page's context,
  /// after the sheet has closed, so no route is pushed from inside a modal
  /// that is on its way out.
  Future<void> _openMemberMenu(
    BuildContext context,
    GroupFollowKey followKey,
  ) async {
    final result = await GroupNotificationSettingsDrawer.show(
      context,
      profile,
      followKey: followKey,
    );
    if (!context.mounted) return;
    if (result == GroupNotificationSheetResult.openNotificationSettings) {
      // This profile is a root-pushed route above the /home shell, and
      // AppRoutes.notifications lives inside that shell. Pushing it through
      // go_router from here makes the router insert a second /home shell page
      // and trip its duplicate page key assertion, so the screen goes on the
      // root navigator as a pageless route instead. Its own back button uses
      // context.pop(), which go_router resolves to this route.
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const NotificationSettingsScreen(),
        ),
      );
    }
  }

  Future<void> _onFollowPressed(
    BuildContext context,
    WidgetRef ref,
    GroupFollowKey followKey,
    bool isCurrentlyFollowing,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final notifier = ref.read(groupFollowProvider(followKey).notifier);
    isCurrentlyFollowing
        ? await notifier.unfollow(connectGroup: profile)
        : await notifier.follow(connectGroup: profile);
  }
}

class _GroupProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _GroupProfileTabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
  });

  final Widget tabBar;
  final Color backgroundColor;

  static const _extent = kTextTabBarHeight + 1;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _GroupProfileTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
