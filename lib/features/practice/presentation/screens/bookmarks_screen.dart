import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/bookmark_card.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<String> _tabLabels(BuildContext context) => [
    context.l10n.search_all,
    context.l10n.home_shortcut_plans,
    context.l10n.home_chants,
    context.l10n.bookmark_mala,
    context.l10n.bookmark_group_accumulation,
    context.l10n.bookmark_timers,
    context.l10n.bookmark_texts,
  ];
  static const _tabs = [
    BookmarkTab.all,
    BookmarkTab.plans,
    BookmarkTab.chants,
    BookmarkTab.mala,
    BookmarkTab.groupAccumulation,
    BookmarkTab.timers,
    BookmarkTab.texts,
  ];

  List<(String, String)> _emptyMessages(BuildContext context) => [
    (
      context.l10n.bookmarks_empty_all_title,
      context.l10n.bookmarks_empty_all_subtitle,
    ),
    (
      context.l10n.bookmarks_empty_plans_title,
      context.l10n.bookmarks_empty_plans_subtitle,
    ),
    (
      context.l10n.bookmarks_empty_chant_collections_title,
      context.l10n.bookmarks_empty_chant_collections_subtitle,
    ),
    (
      context.l10n.bookmarks_empty_malas_title,
      context.l10n.bookmarks_empty_malas_subtitle,
    ),
    (
      context.l10n.bookmarks_empty_group_accumulations_title,
      context.l10n.bookmarks_empty_group_accumulations_subtitle,
    ),
    (
      context.l10n.bookmarks_empty_timers_title,
      context.l10n.bookmarks_empty_timers_subtitle,
    ),
    (
      context.l10n.bookmarks_empty_texts_title,
      context.l10n.bookmarks_empty_texts_subtitle,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRemove(BookmarkDTO bookmark) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(bookmarksProvider.notifier).remove(bookmark);
    if (!mounted) return;
    if (ok) {
      final type = bookmarkTypeFromItem(bookmark.type);
      if (type != null) {
        ref.read(bookmarkExistsCacheProvider.notifier).set(
          BookmarkTarget(type: type, sourceId: bookmark.sourceId),
          const BookmarkExistsResult(exists: false),
        );
      }
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? context.l10n.bookmark_removed : context.l10n.bookmark_remove_failed,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onTap(BookmarkDTO bookmark) {
    switch (bookmark.type) {
      case BookmarkItemType.text:
      case BookmarkItemType.verse:
        final textId = bookmark.textId ?? bookmark.sourceId;
        context.push(
          '/reader/$textId',
          extra: NavigationContext(source: NavigationSource.normal),
        );
      case BookmarkItemType.series:
        context.pushNamed(
          'home-series-detail',
          pathParameters: {'id': bookmark.sourceId},
        );
      case BookmarkItemType.timer:
        // Open the active timer directly. This route is root-navigator-keyed,
        // so it won't duplicate the /home shell page (which crashes when a
        // shell route like the timers list is pushed from this root screen).
        final durationMs = bookmark.timerDurationMs;
        if (durationMs == null || durationMs <= 0) return;
        context.push(
          '/home/timers/active',
          extra: PresetTimer(
            id: bookmark.sourceId,
            name: bookmark.displayTitle,
            durationMs: durationMs,
          ),
        );
      case BookmarkItemType.accumulator:
        context.push('/mala', extra: {'presetId': bookmark.sourceId});
      case BookmarkItemType.groupRecitationCollection:
        final groupId = bookmark.groupId;
        if (groupId == null || groupId.isEmpty) return;
        context.push(
          '/home/group/$groupId/recitation-collections/${bookmark.sourceId}',
          extra: {'title': _collectionDisplayTitle(bookmark)},
        );
      case BookmarkItemType.recitationCollection:
        context.pushNamed(
          'my-recitation-collection',
          pathParameters: {'collectionId': bookmark.sourceId},
          extra: {'title': _collectionDisplayTitle(bookmark)},
        );
      case BookmarkItemType.groupAccumulator:
        if (bookmark.isOrphaned) return;
        context.pushNamed(
          'home-group-accumulator',
          pathParameters: {'accumulatorId': bookmark.sourceId},
        );
      case BookmarkItemType.plan:
        // No reliable id-based deep link for a plan from bookmark data alone.
        break;
    }
  }

  String _collectionDisplayTitle(BookmarkDTO bookmark) {
    final preferred = bookmark.nestedTitle ?? bookmark.name;
    if (preferred != null && preferred.trim().isNotEmpty) {
      return preferred.trim();
    }
    return context.l10n.my_recitation_collection_fallback_title;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(bookmarksProvider);
    final emptyMessages = _emptyMessages(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.l10n.bookmarks,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        scrolledUnderElevation: 0,
        centerTitle: true,
        bottom: _buildTabBar(context, isDark),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          _tabs.length,
          (i) => _BookmarkTabView(
            state: state,
            tab: _tabs[i],
            emptyMessage: emptyMessages[i],
            isDark: isDark,
            onRefresh: () => ref.read(bookmarksProvider.notifier).refresh(),
            onRetry: () => ref.read(bookmarksProvider.notifier).load(),
            onRemove: _onRemove,
            onTap: _onTap,
          ),
        ),
      ),
    );
  }

  /// Scrollable tabs that still fill the screen width evenly when labels are
  /// short; tabs grow past their share when a locale needs more room.
  PreferredSizeWidget _buildTabBar(BuildContext context, bool isDark) {
    final labels = _tabLabels(context);
    final minTabWidth = MediaQuery.sizeOf(context).width / labels.length;

    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelPadding: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      tabs:
          labels
              .map(
                (label) => Tab(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: minTabWidth),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ),
              )
              .toList(),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      labelColor:
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      unselectedLabelColor:
          isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
      indicatorColor: Colors.blue,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
    );
  }
}

/// Renders one tab: loading / error / empty / grouped list states.
class _BookmarkTabView extends StatelessWidget {
  const _BookmarkTabView({
    required this.state,
    required this.tab,
    required this.emptyMessage,
    required this.isDark,
    required this.onRefresh,
    required this.onRetry,
    required this.onRemove,
    required this.onTap,
  });

  final BookmarksState state;
  final BookmarkTab tab;
  final (String, String) emptyMessage;
  final bool isDark;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final void Function(BookmarkDTO) onRemove;
  final void Function(BookmarkDTO) onTap;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.bookmarks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.bookmarks.isEmpty) {
      return _BookmarkErrorState(onRetry: onRetry);
    }

    final items = state.forTab(tab);
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder:
              (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: _BookmarkEmptyState(
                    firstLine: emptyMessage.$1,
                    secondLine: emptyMessage.$2,
                  ),
                ),
              ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: _buildGroupedChildren(context, items),
      ),
    );
  }

  List<Widget> _buildGroupedChildren(
    BuildContext context,
    List<BookmarkDTO> items,
  ) {
    final children = <Widget>[];
    String? lastHeader;
    for (final bookmark in items) {
      final header = _sectionLabel(context, bookmark.createdAt);
      if (header != lastHeader) {
        children.add(
          _SectionHeader(label: header, isDark: isDark, isFirst: lastHeader == null),
        );
        lastHeader = header;
      }
      children.add(
        BookmarkCard(
          bookmark: bookmark,
          onRemove: () => onRemove(bookmark),
          onTap: bookmark.isOpenable ? () => onTap(bookmark) : null,
        ),
      );
    }
    return children;
  }

  static String _sectionLabel(BuildContext context, DateTime created) {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(created);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return context.l10n.home_today;
    if (diff == 1) return context.l10n.bookmarks_yesterday;
    if (today.year == created.year) return DateFormat('MMM d').format(created);
    return DateFormat('MMM d, y').format(created);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.isDark,
    required this.isFirst,
  });

  final String label;
  final bool isDark;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 12, bottom: 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Failure state for a tab.
///
/// Deliberately shows only the localized message, never [BookmarksState.error]:
/// that string carries backend detail like "Server error (500)", which belongs
/// in the logs ([BookmarksNotifier.load] records it) and not on screen.
class _BookmarkErrorState extends StatelessWidget {
  const _BookmarkErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textSubtleDark : AppColors.grey600;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.unableToLoad,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}

class _BookmarkEmptyState extends StatelessWidget {
  const _BookmarkEmptyState({
    required this.firstLine,
    required this.secondLine,
  });

  final String firstLine;
  final String secondLine;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textSubtleDark : AppColors.grey600;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              firstLine,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
            ),
            Text(
              secondLine,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
