import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_requests_filter.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/prayer_requests_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/prayer_intention_l10n.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/prayer_intention_tint.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_requests_filter_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Picks how the prayer requests are ordered, or one intention to show.
/// Pops with the chosen filter, or null when dismissed.
class PrayerSortSheet extends ConsumerWidget {
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
    PrayerSort.needsPrayers,
    PrayerSort.mostPrayed,
    PrayerSort.newest,
    PrayerSort.oldest,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final intentions = ref.watch(prayerIntentionsProvider);
    final catalog = intentions.valueOrNull ?? const <ChatPrayerIntentionDTO>[];
    // A filter carried over from a request keeps its intention without the
    // catalog's copy, so match by slug.
    final selectedSlug = current.intention?.slug;
    final selected =
        catalog.where((item) => item.slug == selectedSlug).firstOrNull ??
        current.intention;
    final failed = intentions.hasError && catalog.isEmpty;
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
                              !current.byIntention && current.sort == sort,
                          isDark: isDark,
                          onTap:
                              () => Navigator.of(
                                context,
                              ).pop(current.withSort(sort)),
                        ),
                      _SortRow(
                        icon: AppAssets.smiley,
                        label: l10n.event_prayer_sort_by_intention,
                        subtitle:
                            failed
                                ? l10n.event_prayer_intentions_failed
                                : selected?.localizedLabel(context),
                        selected: current.byIntention,
                        isDark: isDark,
                        onTap:
                            selected == null
                                ? null
                                : () => Navigator.of(
                                  context,
                                ).pop(current.withIntention(selected)),
                        trailing:
                            failed
                                ? TextButton(
                                  onPressed:
                                      () => ref.invalidate(
                                        prayerIntentionsProvider,
                                      ),
                                  child: Text(l10n.group_chat_retry),
                                )
                                : _IntentionDots(
                                  intentions: catalog,
                                  selectedSlug: selected?.slug,
                                  loading: intentions.isLoading,
                                  isDark: isDark,
                                  onPick:
                                      (intention) => Navigator.of(
                                        context,
                                      ).pop(current.withIntention(intention)),
                                ),
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
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailing;

  static const double _padding = 14;
  static const double _iconSize = 22;
  static const double _iconGap = 14;
  static const double _trailingGap = 8;

  /// What the label keeps when the trailing dots want the rest.
  static const double _minLabelWidth = 96;

  @override
  Widget build(BuildContext context) {
    final foreground =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final muted = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
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
            padding: const EdgeInsets.symmetric(
              horizontal: _padding,
              vertical: 12,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trailingMax = math.max(
                  0.0,
                  constraints.maxWidth -
                      _iconSize -
                      _iconGap -
                      _trailingGap -
                      _minLabelWidth,
                );
                return Row(
                  children: [
                    Icon(icon, size: _iconSize, color: foreground),
                    const SizedBox(width: _iconGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            strutStyle: context.tibetanStrutStyle(
                              15,
                              compact: true,
                            ),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                              color: foreground,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              strutStyle: context.tibetanStrutStyle(
                                12,
                                compact: true,
                              ),
                              style: TextStyle(fontSize: 12, color: muted),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: _trailingGap),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: trailingMax),
                        child: trailing,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// One circle per intention; the chosen one wears a ring.
class _IntentionDots extends StatelessWidget {
  const _IntentionDots({
    required this.intentions,
    required this.selectedSlug,
    required this.loading,
    required this.isDark,
    required this.onPick,
  });

  final List<ChatPrayerIntentionDTO> intentions;
  final String? selectedSlug;
  final bool loading;
  final bool isDark;
  final ValueChanged<ChatPrayerIntentionDTO> onPick;

  static const double _size = 28;
  static const double _ringSize = 36;

  @override
  Widget build(BuildContext context) {
    if (loading && intentions.isEmpty) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final ring = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    // Wraps when the catalog outgrows one row on a narrow screen.
    return Wrap(
      alignment: WrapAlignment.end,
      children: [
        for (final intention in intentions)
          Semantics(
            button: true,
            selected: intention.slug == selectedSlug,
            label: intention.localizedLabel(context),
            child: InkWell(
              onTap: () => onPick(intention),
              customBorder: const CircleBorder(),
              child: Container(
                width: _ringSize,
                height: _ringSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        intention.slug == selectedSlug
                            ? ring
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    color: prayerIntentionColor(intention, isDark),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
