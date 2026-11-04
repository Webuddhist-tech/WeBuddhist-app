import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/screens/group_search_screen.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/group_search_result_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connect for someone with no spaces: a hero with the space search, then
/// the popular spaces to start from.
class ConnectLandingView extends ConsumerWidget {
  const ConnectLandingView({super.key});

  static const _paginationThreshold = 200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoverGroupsProvider);
    final notifier = ref.read(discoverGroupsProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ref.read(discoverGroupsProvider.notifier).ensureLoaded();
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status bar over the hero photo.
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: RefreshIndicator(
          onRefresh: notifier.refresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent -
                      _paginationThreshold) {
                notifier.loadMore();
              }
              return false;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _ConnectHero()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                    child: Text(
                      context.l10n.connect_popular_spaces,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                ..._buildSpaces(context, state, notifier),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSpaces(
    BuildContext context,
    DiscoverGroupsState state,
    DiscoverGroupsNotifier notifier,
  ) {
    final groups = state.groups;
    if (groups.isEmpty) {
      final Widget child;
      if (state.isLoading || !state.hasLoaded) {
        child = const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      } else if (state.error != null) {
        child = ErrorStateWidget(error: state.error!, onRetry: notifier.retry);
      } else {
        child = Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            context.l10n.no_groups_found,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
      }
      return [SliverToBoxAdapter(child: child)];
    }

    return [
      SliverList.builder(
        itemCount: groups.length,
        itemBuilder:
            (context, index) => GroupSearchResultCard(group: groups[index]),
      ),
      if (state.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ];
  }
}

class _ConnectHero extends StatelessWidget {
  const _ConnectHero();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: (width * 0.95).clamp(280.0, 420.0) + topInset,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Placeholder until the design's hero photo is added.
          Image.asset(AppAssets.connect, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.4, 1],
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.connect_landing_title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const ConnectSpaceSearchField(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Looks like a search box; tapping it opens the space search.
class ConnectSpaceSearchField extends StatelessWidget {
  const ConnectSpaceSearchField({super.key});

  static void openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'group-search'),
        builder: (_) => const GroupSearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Semantics(
      button: true,
      label: context.l10n.search_groups,
      child: Material(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => openSearch(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(AppAssets.exploreUnselected, size: 20, color: hintColor),
                const SizedBox(width: 10),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      context.l10n.search_groups,
                      style: TextStyle(fontSize: 15, color: hintColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
