import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_unified_feed_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_analytics.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_feed_item_view.dart';
import 'package:flutter_pecha/features/home/presentation/providers/home_community_feed_provider.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/group_events_section_skeleton.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Home's "From the community": the first few Connect feed cards, with
/// "See more" opening the whole feed.
class CommunityFeedSection extends ConsumerWidget {
  const CommunityFeedSection({super.key});

  static const previewCount = 5;
  static const _horizontalPadding = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMember = ref.watch(
      authProvider.select((auth) => auth.isLoggedIn && !auth.isGuest),
    );
    final feed = ref.watch(homeCommunityFeedProvider);
    ref.watch(
      connectPostViewTrackerProvider((
        surface: ConnectPostSurface.homePreview,
        visitId: null,
      )),
    );

    // Both loads are idempotent; the member's own feed decides whether
    // Discover is needed at all.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (isMember) {
        ref.read(myUnifiedConnectFeedProvider.notifier).ensureLoaded();
      }
      if (feed == HomeCommunityFeed.discover) {
        ref.read(discoverUnifiedConnectFeedProvider.notifier).ensureLoaded();
      }
    });

    if (feed == null) {
      final myFailed = ref.watch(
        myUnifiedConnectFeedProvider.select((state) => state.error != null),
      );
      return myFailed
          ? const SizedBox.shrink()
          : const GroupEventsSectionSkeleton();
    }

    final state = ref.watch(feed.provider);
    final items = state.mergedItems;
    if (items.isEmpty) {
      return state.hasLoaded && !state.isLoading
          ? const SizedBox.shrink()
          : const GroupEventsSectionSkeleton();
    }

    return _CommunityFeedContent(
      items: items.take(previewCount).toList(),
      includeUnfollowed: feed.includeUnfollowed,
      showSeeMore: items.length > previewCount || state.hasMore,
    );
  }
}

class _CommunityFeedContent extends StatelessWidget {
  const _CommunityFeedContent({
    required this.items,
    required this.includeUnfollowed,
    required this.showSeeMore,
  });

  final List<ConnectFeedItem> items;
  final bool includeUnfollowed;
  final bool showSeeMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTibetan = context.isTibetanLocale;
    final sectionTitleSize = getLocalizedFontSize(AppTextSize.bodyLarge);
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CommunityFeedSection._horizontalPadding,
          ),
          child: Text(
            l10n.home_community_feed,
            strutStyle: context.tibetanStrutStyle(
              sectionTitleSize,
              compact: true,
            ),
            style: TextStyle(
              fontSize: sectionTitleSize,
              fontWeight: FontWeight.w700,
              height: isTibetan ? AppFontConfig.tibetanCompactLineHeight : 1.2,
              leadingDistribution:
                  isTibetan ? AppFontConfig.tibetanLeadingDistribution : null,
            ),
          ),
        ),
        SizedBox(height: isTibetan ? 16.0 : 12.0),
        for (var i = 0; i < items.length; i++) ...[
          ConnectFeedItemView(
            item: items[i],
            includeUnfollowed: includeUnfollowed,
            placement: ConnectPostPlacement(
              surface: ConnectPostSurface.homePreview,
              position: i,
            ),
          ),
          if (i < items.length - 1)
            Divider(height: 1, thickness: 1, color: dividerColor),
        ],
        if (showSeeMore) ...[
          const SizedBox(height: 12),
          Center(child: _SeeMoreButton(isDark: isDark)),
        ],
      ],
    );
  }
}

class _SeeMoreButton extends StatelessWidget {
  const _SeeMoreButton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.pushNamed('home-community-feed'),
      style: TextButton.styleFrom(
        backgroundColor:
            isDark ? AppColors.surfaceVariantDark : AppColors.greyLight,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: const StadiumBorder(),
      ),
      child: Text(
        context.l10n.see_more,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
