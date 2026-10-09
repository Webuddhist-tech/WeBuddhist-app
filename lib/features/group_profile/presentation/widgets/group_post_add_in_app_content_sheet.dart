import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_events_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_practices_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_post_link_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_post_in_app_content.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_list_tile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_post_add_link_sheet.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_date_format.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_recitations_paginated_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_chant_list_tile.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_search_provider.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Picks an event, practice or chant the user follows and hands the composer
/// the same short link the item's share button produces.
class GroupPostAddInAppContentSheet extends ConsumerStatefulWidget {
  const GroupPostAddInAppContentSheet({super.key});

  static Future<GroupPostLinkDraft?> show(BuildContext context) {
    return showModalBottomSheet<GroupPostLinkDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const GroupPostAddInAppContentSheet(),
    );
  }

  @override
  ConsumerState<GroupPostAddInAppContentSheet> createState() =>
      _GroupPostAddInAppContentSheetState();
}

enum _Tab { events, practices, chants }

class _GroupPostAddInAppContentSheetState
    extends ConsumerState<GroupPostAddInAppContentSheet>
    with SingleTickerProviderStateMixin {
  static const _eventsFilter = ConnectEventFormatFilter.all;

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  GroupPostInAppContent? _selected;
  bool _isAttaching = false;

  _Tab get _tab => _Tab.values[_tabController.index];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _Tab.values.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    // After the first build, so the watch in build() already holds the
    // provider; same as the Connect events tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadTab(_Tab.events);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Each list loads when its tab is first shown; an untouched tab costs no
  // request.
  void _loadTab(_Tab tab) {
    switch (tab) {
      case _Tab.events:
        ref
            .read(myConnectEventsProvider(_eventsFilter).notifier)
            .ensureLoaded();
      case _Tab.practices:
        ref.read(myConnectPracticesProvider.notifier).ensureLoaded();
      case _Tab.chants:
        _searchChants();
    }
  }

  void _onTabChanged() {
    // The search field exists only on the chants tab.
    setState(() {});
    if (_tabController.indexIsChanging) return;
    _loadTab(_tab);
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value.trim());
    _searchChants();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  // Server-side title search; below the notifier's minimum length the tab
  // shows the plain catalogue.
  void _searchChants() {
    final language = ref.read(practiceRecitationsLanguageProvider);
    ref
        .read(practiceRecitationSearchProvider(language).notifier)
        .search(_query);
  }

  void _select(GroupPostInAppContent content) {
    setState(() => _selected = _selected?.id == content.id ? null : content);
  }

  Future<void> _attach() async {
    final selected = _selected;
    if (selected == null || _isAttaching) return;
    setState(() => _isAttaching = true);

    final url = await resolveShareUrlRef(ref, selected.link.toString());
    if (!mounted) return;
    Navigator.of(context).pop(
      GroupPostLinkDraft(
        url: url,
        type: ConnectPostLinkUtils.typeFor(url),
        title: selected.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watched here rather than in the tab pages so the lists survive tab
    // switches; neither notifier fetches until ensureLoaded().
    final eventsState = ref.watch(myConnectEventsProvider(_eventsFilter));
    final practicesState = ref.watch(myConnectPracticesProvider);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final sheetHeight =
        (screenHeight * 0.85 - bottomInset)
            .clamp(screenHeight * 0.45, screenHeight * 0.85)
            .toDouble();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildHeader(l10n),
              _buildTabBar(l10n, isDark),
              // Only chants have a search endpoint; /events and
              // /author/groups/practices take no search param.
              if (_tab == _Tab.chants) _buildSearchField(l10n, isDark),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventsTab(l10n, eventsState),
                    _buildPracticesTab(l10n, practicesState),
                    _ChantsTab(
                      query: _query,
                      selectedId: _selected?.id,
                      onSelect: _select,
                    ),
                  ],
                ),
              ),
              _buildAttachButton(l10n, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.group_post_add_in_app_content_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    _isAttaching ? null : () => Navigator.of(context).pop(),
                icon: const Icon(AppAssets.x),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n, bool isDark) {
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
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelColor: labelColor,
        unselectedLabelColor: unselectedColor,
        indicatorColor: labelColor,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        labelStyle: context.tabLabelStyle(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        unselectedLabelStyle: context.tabLabelStyle(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        tabs: [
          Tab(text: l10n.connect_tab_events),
          Tab(text: l10n.connect_tab_practices),
          Tab(text: l10n.home_chants),
        ],
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations l10n, bool isDark) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: color),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: l10n.my_recitation_collection_search_chants,
          hintStyle: TextStyle(fontSize: 14, color: secondaryColor),
          isDense: true,
          filled: true,
          fillColor:
              isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
          enabledBorder: border(borderColor),
          focusedBorder: border(
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon:
              _query.isEmpty
                  ? null
                  : IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(AppAssets.x, size: 18),
                  ),
        ),
      ),
    );
  }

  Widget _buildEventsTab(AppLocalizations l10n, ConnectEventsState state) {
    final notifier = ref.read(myConnectEventsProvider(_eventsFilter).notifier);

    return _ContentList<GroupEvent>(
      items: state.events,
      isLoading: !state.hasLoaded || state.isLoading,
      error: state.error,
      hasMore: state.hasMore,
      isLoadingMore: state.isLoadingMore,
      onLoadMore: notifier.loadMore,
      onRetry: notifier.retry,
      itemBuilder: (context, event) {
        final content = GroupPostInAppContent.event(event);
        return _ContentTile(
          title:
              content.title.trim().isNotEmpty
                  ? content.title
                  : l10n.connect_event_fallback_title,
          thumbnail: _responsiveThumbnail(event.image),
          fallbackIcon: AppAssets.calendarDots,
          subtitle: GroupEventListTile.formatDateLabel(context, event),
          count: event.participantCount,
          isSelected: _selected?.id == content.id,
          onTap: () => _select(content),
        );
      },
    );
  }

  Widget _buildPracticesTab(
    AppLocalizations l10n,
    ConnectPracticesState state,
  ) {
    final notifier = ref.read(myConnectPracticesProvider.notifier);
    final items = <(GroupPractice, GroupPostInAppContent)>[
      for (final practice in state.practices)
        if (GroupPostInAppContent.practice(practice) case final content?)
          (practice, content),
    ];

    return _ContentList<(GroupPractice, GroupPostInAppContent)>(
      items: items,
      isLoading: !state.hasLoaded || state.isLoading,
      error: state.error,
      hasMore: state.hasMore,
      isLoadingMore: state.isLoadingMore,
      onLoadMore: notifier.loadMore,
      onRetry: notifier.retry,
      itemBuilder:
          (context, item) => _buildPracticeTile(l10n, item.$1, item.$2),
    );
  }

  Widget _buildPracticeTile(
    AppLocalizations l10n,
    GroupPractice practice,
    GroupPostInAppContent content,
  ) {
    Widget? thumbnail;
    String? subtitle;
    double? progress;
    int? count;
    switch (practice.type) {
      case GroupPracticeType.series:
        final series = practice.series!;
        thumbnail = _responsiveThumbnail(series.image);
        subtitle = PlanDateFormat.formatRangeOrNull(
          series.startDate,
          series.endDate,
        );
        count = series.enrolledCount;
      case GroupPracticeType.accumulator:
        final accumulator = practice.accumulator!;
        thumbnail = _responsiveThumbnail(accumulator.image);
        subtitle = PlanDateFormat.formatRangeOrNull(
          accumulator.startDate,
          accumulator.endDate,
        );
        progress =
            accumulator.targetCount > 0 ? accumulator.progressFraction : null;
        count = accumulator.memberCount;
      case GroupPracticeType.plan:
        final plan = practice.plan!;
        thumbnail = _urlThumbnail(plan.imageUrl);
        final start = plan.startDate;
        subtitle = start == null ? null : PlanDateFormat.formatDate(start);
      case GroupPracticeType.collection:
        final collection = practice.collection!;
        thumbnail = _urlThumbnail(collection.imageUrl);
        subtitle =
            collection.itemCount > 0
                ? l10n.my_recitation_collection_chant_count(
                  collection.itemCount,
                )
                : null;
    }

    return _ContentTile(
      title: content.title,
      thumbnail: thumbnail,
      fallbackIcon: AppAssets.handsPraying,
      subtitle: subtitle,
      progress: progress,
      count: count,
      isSelected: _selected?.id == content.id,
      onTap: () => _select(content),
    );
  }

  Widget _buildAttachButton(AppLocalizations l10n, bool isDark) {
    final foreground = isDark ? AppColors.textPrimary : AppColors.surfaceWhite;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          // Stays in the enabled style while the link is being shortened.
          onPressed:
              _isAttaching ? () {} : (_selected == null ? null : _attach),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
            foregroundColor: foreground,
            disabledBackgroundColor:
                isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            disabledForegroundColor:
                isDark ? AppColors.grey500 : AppColors.grey600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          child:
              _isAttaching
                  ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                  : Text(
                    l10n.group_post_attach,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
    );
  }
}

Widget? _responsiveThumbnail(ResponsiveImage? image) {
  if (image == null || image.isEmpty) return null;
  return ResponsiveCoverImage(image: image, fit: BoxFit.cover);
}

Widget? _urlThumbnail(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  return CachedNetworkImageWidget(imageUrl: url, fit: BoxFit.cover);
}

/// Its own widget so the catalogue (and the user's collections) is fetched
/// only once this tab is actually on screen.
class _ChantsTab extends ConsumerWidget {
  const _ChantsTab({
    required this.query,
    required this.selectedId,
    required this.onSelect,
  });

  final String query;
  final String? selectedId;
  final ValueChanged<GroupPostInAppContent> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(practiceRecitationsLanguageProvider);
    final listProvider = practiceRecitationsPaginatedProvider(language);
    final searchProvider = practiceRecitationSearchProvider(language);
    final listState = ref.watch(listProvider);
    final searchState = ref.watch(searchProvider);
    final isServerSearch =
        query.length >= RecitationSearchNotifier.minQueryLength;
    final chants = isServerSearch ? searchState.results : listState.recitations;

    return _ContentList<RecitationModel>(
      items: chants,
      isLoading: isServerSearch ? searchState.isLoading : listState.isLoading,
      error: isServerSearch ? searchState.error : listState.error,
      hasMore: !isServerSearch && listState.hasMore,
      isLoadingMore: listState.isLoadingMore,
      query: isServerSearch ? query : '',
      onLoadMore: ref.read(listProvider.notifier).loadMore,
      onRetry:
          isServerSearch
              ? ref.read(searchProvider.notifier).retry
              : ref.read(listProvider.notifier).retry,
      itemBuilder: (context, chant) {
        final content = GroupPostInAppContent.chant(chant);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final tile = PracticeChantListTile(
          recitation: chant,
          includeOuterPadding: false,
          showTrailingCaret: false,
          onTap: () => onSelect(content),
        );
        if (selectedId != content.id) return tile;
        // Drawn over the tile; behind it the tile's own fill would hide it.
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              width: 2,
            ),
          ),
          child: tile,
        );
      },
    );
  }
}

class _ContentList<T> extends StatelessWidget {
  const _ContentList({
    required this.items,
    required this.isLoading,
    required this.error,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onRetry,
    required this.itemBuilder,
    this.query = '',
  });

  final List<T> items;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final bool isLoadingMore;

  /// The active search, used only to word the empty state.
  final String query;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      if (error != null) {
        return Center(child: ErrorStateWidget(error: error!, onRetry: onRetry));
      }
      if (isLoading) return const Center(child: CircularProgressIndicator());
      return _EmptyMessage(query: query);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (hasMore &&
            !isLoadingMore &&
            metrics.pixels >= metrics.maxScrollExtent - 200) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: items.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return itemBuilder(context, items[index]);
        },
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          query.isEmpty
              ? l10n.group_post_in_app_content_empty
              : l10n.search_no_results(query),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ContentTile extends StatelessWidget {
  const _ContentTile({
    required this.title,
    required this.fallbackIcon,
    required this.isSelected,
    required this.onTap,
    this.thumbnail,
    this.subtitle,
    this.progress,
    this.count,
  });

  final String title;
  final Widget? thumbnail;
  final IconData fallbackIcon;
  final String? subtitle;

  /// Shown as a bar in place of [subtitle] when set.
  final double? progress;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _thumbnailSize = 72;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final titleStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: primaryColor,
    );

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? primaryColor : borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: _thumbnailSize,
                  height: _thumbnailSize,
                  child:
                      thumbnail ??
                      ColoredBox(
                        color:
                            isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.grey100,
                        child: Icon(
                          fallbackIcon,
                          size: 28,
                          color: isDark ? AppColors.grey500 : AppColors.grey600,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor:
                              isDark
                                  ? AppColors.cardBorderDark
                                  : AppColors.grey100,
                          color: AppColors.primary,
                        ),
                      ),
                    ] else if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: secondaryColor),
                      ),
                    ],
                  ],
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 10),
                Icon(AppAssets.usercard, size: 16, color: secondaryColor),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(fontSize: 13, color: secondaryColor),
                ),
              ],
              if (isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                  ),
                  child: Icon(
                    AppAssets.check,
                    size: 12,
                    color: isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
