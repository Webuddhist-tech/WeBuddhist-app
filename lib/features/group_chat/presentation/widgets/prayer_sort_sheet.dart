import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_requests_filter.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_requests_filter_bar.dart';

/// Picks how the prayer requests are ordered, or the viewer's own. Pops
/// with the chosen filter, or null when dismissed.
class PrayerSortSheet extends StatelessWidget {
  const PrayerSortSheet({super.key, required this.current});

  final PrayerRequestsFilter current;

  static Future<PrayerRequestsFilter?> show(
    BuildContext context, {
    required PrayerRequestsFilter current,
  }) {
    return showModalBottomSheet<PrayerRequestsFilter>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => PrayerSortSheet(current: current),
    );
  }

  static const List<PrayerSort> _sorts = [
    PrayerSort.newest,
    PrayerSort.needsPrayers,
  ];

  static IconData _iconFor(PrayerSort sort) {
    return switch (sort) {
      PrayerSort.needsPrayers => AppAssets.handsPraying,
      PrayerSort.mostPrayed => AppAssets.trendUp,
      PrayerSort.newest => AppAssets.clock,
      PrayerSort.oldest => AppAssets.clockCounterClockwise,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final maxHeight = MediaQuery.sizeOf(context).height - topInset - 24;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, isDark),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final sort in _sorts)
                        _SortRow(
                          icon: _iconFor(sort),
                          label: prayerSortLabel(l10n, sort),
                          selected:
                              !current.byIntention &&
                              !current.mine &&
                              current.sort == sort,
                          isDark: isDark,
                          onTap:
                              () => Navigator.of(
                                context,
                              ).pop(current.withSort(sort)),
                        ),
                      _SortRow(
                        icon: AppAssets.profile,
                        label: l10n.event_prayer_sort_mine,
                        selected: current.mine,
                        isDark: isDark,
                        onTap:
                            () => Navigator.of(context).pop(current.withMine()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.event_prayer_sort_by,
                    strutStyle: context.tibetanStrutStyle(17, compact: true),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(AppAssets.x, color: titleColor),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final fill =
        selected
            ? (isDark ? AppColors.chipBackgroundDark : AppColors.grey100)
            : Colors.transparent;

    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 22, color: foreground),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    strutStyle: context.tibetanStrutStyle(15, compact: true),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: foreground,
                    ),
                  ),
                ),
                if (selected)
                  Icon(AppAssets.check, size: 18, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
