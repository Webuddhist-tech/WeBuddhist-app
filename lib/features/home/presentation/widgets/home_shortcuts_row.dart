import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_explore_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/all_plans_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/all_recitations_screen.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeShortcutsRow extends ConsumerWidget {
  const HomeShortcutsRow({super.key, this.onMalaTap, this.onTimerTap});

  final VoidCallback? onMalaTap;
  final VoidCallback? onTimerTap;

  static const _horizontalPadding = 12.0;
  static const _itemSpacing = 16.0;
  static const _borderRadius = 16.0;
  static const _iconSize = 26.0;
  static const _contentHorizontalPadding = 6.0;
  static const _contentVerticalPadding = 10.0;
  static const _iconLabelSpacing = 6.0;
  static const _labelFontSize = 14.0;
  static const _labelLineHeight = 1.2;

  void _navigateToSeries(BuildContext context, Series series) {
    context.pushNamed(
      'home-series-detail',
      pathParameters: {'id': series.id},
    );
  }

  void _onPlansTap(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.read(practiceExploreSeriesProvider);
    seriesAsync.whenData((either) {
      either.fold((_) {}, (seriesList) {
        if (seriesList.isEmpty) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'all-plans'),
            builder:
                (_) => AllPlansScreen(
                  seriesList: seriesList,
                  onTap: (series) => _navigateToSeries(context, series),
                ),
          ),
        );
      });
    });
  }

  void _onChantsTap(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'all-recitations'),
        builder: (_) => const AllRecitationsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? colorScheme.surfaceContainerHigh : AppColors.grey100;

    final shortcuts = [
      _HomeShortcutItem(
        icon: AppAssets.homeList,
        label: l10n.home_shortcut_plans,
        onTap: () => _onPlansTap(context, ref),
      ),
      _HomeShortcutItem(
        icon: AppAssets.homeChants,
        label: l10n.home_chants,
        onTap: () => _onChantsTap(context, ref),
      ),
      _HomeShortcutItem(
        imageAsset: AppAssets.homeMalaIcon,
        label: l10n.home_mala,
        onTap: onMalaTap,
      ),
      _HomeShortcutItem(
        icon: AppAssets.homeTimer,
        label: l10n.home_timer,
        onTap: onTimerTap,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Row(
        children: [
          for (var index = 0; index < shortcuts.length; index++) ...[
            if (index > 0) const SizedBox(width: _itemSpacing),
            Expanded(child: shortcuts[index].build(context, cardColor)),
          ],
        ],
      ),
    );
  }
}

class _HomeShortcutItem {
  const _HomeShortcutItem({
    this.icon,
    this.imageAsset,
    required this.label,
    this.onTap,
  }) : assert(
         icon != null || imageAsset != null,
         'Either icon or imageAsset must be provided',
       );

  final IconData? icon;
  final String? imageAsset;
  final String label;
  final VoidCallback? onTap;

  Widget build(BuildContext context, Color cardColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurface;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(HomeShortcutsRow._borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth =
                  constraints.maxWidth -
                  (HomeShortcutsRow._contentHorizontalPadding * 2);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeShortcutsRow._contentHorizontalPadding,
                  vertical: HomeShortcutsRow._contentVerticalPadding,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIcon(iconColor),
                        const SizedBox(
                          height: HomeShortcutsRow._iconLabelSpacing,
                        ),
                        Text(
                          withTibetanLineBreakOpportunities(label),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          strutStyle: context.tibetanStrutStyle(
                            HomeShortcutsRow._labelFontSize,
                            compact: true,
                          ),
                          style: TextStyle(
                            fontSize: HomeShortcutsRow._labelFontSize,
                            fontWeight: FontWeight.bold,
                            height: HomeShortcutsRow._labelLineHeight,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color iconColor) {
    if (imageAsset != null) {
      return Image.asset(
        imageAsset!,
        width: HomeShortcutsRow._iconSize,
        height: HomeShortcutsRow._iconSize,
        color: iconColor,
        colorBlendMode: BlendMode.srcIn,
      );
    }

    return Icon(icon, size: HomeShortcutsRow._iconSize, color: iconColor);
  }
}
