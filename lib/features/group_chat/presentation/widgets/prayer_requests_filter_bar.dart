import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_requests_filter.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/prayer_intention_l10n.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/prayer_intention_tint.dart';

/// The sort option's name as shown in the chip and the sort sheet.
String prayerSortLabel(AppLocalizations l10n, PrayerSort sort) {
  return switch (sort) {
    PrayerSort.needsPrayers => l10n.event_prayer_sort_needs_prayers,
    PrayerSort.mostPrayed => l10n.event_prayer_sort_most_prayed,
    PrayerSort.newest => l10n.event_prayer_sort_newest,
    PrayerSort.oldest => l10n.event_prayer_sort_oldest,
  };
}

/// Sort chip, the intention chip when one is in view, and the match count.
class PrayerRequestsFilterBar extends StatelessWidget {
  const PrayerRequestsFilterBar({
    super.key,
    required this.filter,
    required this.total,
    required this.onOpenSort,
    required this.onClearIntention,
  });

  final PrayerRequestsFilter filter;
  final int total;
  final VoidCallback onOpenSort;
  final VoidCallback onClearIntention;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final intention = filter.intention;
    final muted = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final sortLabel =
        intention == null
            ? prayerSortLabel(l10n, filter.sort)
            : l10n.event_prayer_sort_by_intention;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SortChip(label: sortLabel, isDark: isDark, onTap: onOpenSort),
                if (intention != null) ...[
                  const SizedBox(width: 8),
                  _IntentionChip(
                    intention: intention,
                    isDark: isDark,
                    onClear: onClearIntention,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.event_prayer_request_count(total),
          strutStyle: context.tibetanStrutStyle(13, compact: true),
          style: TextStyle(fontSize: 13, color: muted),
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final border = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final fill = isDark ? AppColors.chipBackgroundDark : AppColors.surfaceWhite;

    return Semantics(
      button: true,
      label: context.l10n.event_prayer_sort_by,
      value: label,
      child: Material(
        color: fill,
        shape: StadiumBorder(side: BorderSide(color: border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppAssets.sliders, size: 16, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  strutStyle: context.tibetanStrutStyle(13, compact: true),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(AppAssets.caretDown, size: 14, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntentionChip extends StatelessWidget {
  const _IntentionChip({
    required this.intention,
    required this.isDark,
    required this.onClear,
  });

  final ChatPrayerIntentionDTO intention;
  final bool isDark;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final accent = prayerIntentionColor(intention, isDark);
    final foreground = prayerAccentTextColor(accent, isDark);
    final label = intention.localizedLabel(context);
    final dotBorder =
        prayerAccentNeedsBorder(accent, isDark)
            ? Border.all(color: foreground.withValues(alpha: 0.4))
            : null;

    return Material(
      color: prayerIntentionCardColor(intention, isDark),
      shape: StadiumBorder(
        side: BorderSide(color: prayerIntentionBorderColor(intention, isDark)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onClear,
        child: Semantics(
          button: true,
          label: context.l10n.event_prayer_clear_intention,
          value: label,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: dotBorder,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  strutStyle: context.tibetanStrutStyle(13, compact: true),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(AppAssets.x, size: 14, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
