import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_accumulation_selection.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/group_accumulation_counts_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_accumulation_selection_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/utils/accumulation_sheet_display.dart';
import 'package:flutter_pecha/features/mala/presentation/utils/mala_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Bottom sheet for choosing where recitations are added: personal practice or
/// one of the joined accumulations. Opened from the mala screen and from the
/// reader's chant bar.
///
/// Every count is a lifetime total. Accumulation rows show
/// `user_total_count` and `group_total_count` from
/// `GET /accumulators/{presetId}/groups`, plus any unsynced local taps via
/// [GroupAccumulationCountsNotifier.displayLifetimeCount]. The personal row
/// shows `total_counted` from `GET /accumulators/{parent_id}` via
/// [MalaCounterNotifier.displayLifetimeCount]. The header adds them up. The
/// on-screen mala counter uses session counts instead; those reset to 0 on
/// DELETE while the totals here do not.
class GroupAccumulationsSheet extends ConsumerWidget {
  const GroupAccumulationsSheet({
    super.key,
    required this.mantra,
    required this.presetTitle,
    required this.groups,
  });

  /// Keys the personal counter. The reader passes a bare
  /// `Mantra(presetId: …)`: a recitation is not in the mala catalogue.
  final Mantra mantra;

  /// Mantra or chant name shown in the header.
  final String presetTitle;
  final List<AccumulatorGroup> groups;

  String get presetId => mantra.presetId;

  static Future<void> show(
    BuildContext context, {
    required Mantra mantra,
    required String presetTitle,
    required List<AccumulatorGroup> groups,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder:
          (_) => GroupAccumulationsSheet(
            mantra: mantra,
            presetTitle: presetTitle,
            groups: groups,
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final selection = ref.watch(malaAccumulationSelectionProvider(presetId));
    // Watching keeps the personal counter alive while the sheet is open and
    // repaints once its lifetime total has loaded.
    ref.watch(malaCounterProvider(mantra));
    final personalLifetimeCount =
        ref.read(malaCounterProvider(mantra).notifier).displayLifetimeCount;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    ref.watch(groupAccumulationCountsProvider(presetId));
    final groups =
        ref.watch(joinedAccumulatorGroupsProvider(presetId)).valueOrNull ??
        this.groups;
    final countsNotifier = ref.read(
      groupAccumulationCountsProvider(presetId).notifier,
    );
    final myTotals = {
      for (final group in groups)
        group.groupAccumulatorId: countsNotifier.displayLifetimeCount(
          group.groupAccumulatorId,
          group.userTotalCount,
        ),
    };
    final sections = splitAccumulationSections(groups);
    final allTime = allTimeAccumulation(
      personalLifetime: personalLifetimeCount,
      myGroupLifetimes: myTotals.values,
    );

    Widget accumulationRow(AccumulatorGroup group) {
      final myTotal = myTotals[group.groupAccumulatorId] ?? 0;
      final groupTotal = groupTotalWithUnsynced(
        apiGroupTotal: group.groupTotalCount,
        apiMyTotal: group.userTotalCount,
        displayMyTotal: myTotal,
      );
      return _AccumulationRow(
        isSelected: selection.groupAccumulatorId == group.groupAccumulatorId,
        onTap:
            () => _select(
              ref,
              MalaAccumulationSelection.group(group.groupAccumulatorId),
              groups,
            ),
        leading: _GroupAvatar(group: group),
        title: accumulationRowTitle(group) ?? l10n.mala_group_untitled,
        subtitle: accumulationRowSubtitle(group),
        totals:
            '${l10n.mala_my_total(_formatCount(context, myTotal))}'
            '  |  '
            '${l10n.mala_group_total(_formatCount(context, groupTotal))}',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.goldLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _SheetHeader(
                title: presetTitle,
                caption: l10n.mala_all_time_accumulation,
                formattedTotal: _formatCount(context, allTime),
                captionColor: secondaryColor,
              ),
              Divider(height: 1, thickness: 1, color: dividerColor),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        l10n.mala_group_accumulations,
                        strutStyle: context.tibetanStrutStyle(15),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _AccumulationRow(
                      isSelected: selection.isPersonal,
                      onTap:
                          () => _select(
                            ref,
                            const MalaAccumulationSelection.personal(),
                            groups,
                          ),
                      leading: const _PersonalAvatar(),
                      title: l10n.mala_personal_practice,
                      trailingCount: _formatCount(
                        context,
                        personalLifetimeCount,
                      ),
                    ),
                    if (groups.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 20,
                        endIndent: 20,
                        color: dividerColor,
                      ),
                    ],
                    if (sections.events.isNotEmpty) ...[
                      _SectionLabel(
                        label: l10n.mala_events_section,
                        color: secondaryColor,
                      ),
                      ...sections.events.map(accumulationRow),
                    ],
                    if (sections.groups.isNotEmpty) ...[
                      _SectionLabel(
                        label: l10n.mala_groups_section,
                        color: secondaryColor,
                      ),
                      ...sections.groups.map(accumulationRow),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Applies [next] and reports the change once it is the live selection.
  void _select(
    WidgetRef ref,
    MalaAccumulationSelection next,
    List<AccumulatorGroup> groups,
  ) {
    final provider = malaAccumulationSelectionProvider(presetId);
    final previous = ref.read(provider);
    final groupAccumulatorId = next.groupAccumulatorId;
    if (groupAccumulatorId == null) {
      ref.read(provider.notifier).selectPersonal();
    } else {
      ref.read(provider.notifier).selectGroup(groupAccumulatorId);
    }
    if (next == previous) return;
    ref
        .read(malaAnalyticsProvider)
        .modeChanged(
          from: previous.analyticsMode,
          to: next.analyticsMode,
          groupId: malaGroupIdFor(
            groups,
            groupAccumulatorId ?? previous.groupAccumulatorId,
          ),
        );
  }

  static String _formatCount(BuildContext context, int value) {
    final formatted = NumberFormat.decimalPattern(
      intlFormatLocaleOf(context),
    ).format(value);
    return context.isTibetanLocale ? toTibetanDigits(formatted) : formatted;
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.caption,
    required this.formattedTotal,
    required this.captionColor,
  });

  final String title;
  final String caption;
  final String formattedTotal;
  final Color captionColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  strutStyle: context.tibetanStrutStyle(18),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  strutStyle: context.tibetanStrutStyle(12),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: captionColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formattedTotal,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        label,
        strutStyle: context.tibetanStrutStyle(14),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

/// One selectable target. The selected row is drawn as a bordered card with a
/// check; the others sit flat on the sheet.
class _AccumulationRow extends StatelessWidget {
  const _AccumulationRow({
    required this.isSelected,
    required this.onTap,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailingCount,
    this.totals,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;

  /// Owning group's name, under the title.
  final String? subtitle;

  /// Count beside the title, for the personal row.
  final String? trailingCount;

  /// "My total | Group total" line, for accumulation rows.
  final String? totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark ? AppColors.chipBackgroundDark : AppColors.surfaceWhite;
    final borderColor = isDark ? AppColors.grey900 : AppColors.grey300;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final onSurface = theme.colorScheme.onSurface;
    final hasDetails = subtitle != null || totals != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Semantics(
        button: true,
        selected: isSelected,
        child: Material(
          color: isSelected ? cardColor : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? borderColor : Colors.transparent,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment:
                    hasDetails
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                strutStyle: context.tibetanStrutStyle(16),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                ),
                              ),
                            ),
                            if (trailingCount != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                trailingCount!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  color: onSurface,
                                ),
                              ),
                            ],
                            if (isSelected) ...[
                              const SizedBox(width: 10),
                              Icon(
                                AppAssets.check,
                                size: 20,
                                color:
                                    isDark
                                        ? AppColors.successDark
                                        : AppColors.success,
                              ),
                            ],
                          ],
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            strutStyle: context.tibetanStrutStyle(12),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: secondaryColor,
                            ),
                          ),
                        if (totals != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            totals!,
                            textAlign: TextAlign.end,
                            strutStyle: context.tibetanStrutStyle(13),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalAvatar extends StatelessWidget {
  const _PersonalAvatar();

  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey900 : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        AppAssets.profile,
        size: 24,
        color: isDark ? AppColors.textTertiaryDark : AppColors.grey800,
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.group});

  final AccumulatorGroup group;

  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor = isDark ? AppColors.grey900 : AppColors.grey100;

    return ClipOval(
      child: SizedBox(
        width: _size,
        height: _size,
        child:
            group.image != null && !group.image!.isEmpty
                ? ResponsiveCoverImage(
                  image: group.image,
                  width: _size,
                  height: _size,
                  fit: BoxFit.cover,
                )
                : ColoredBox(
                  color: placeholderColor,
                  child: Icon(
                    AppAssets.usersThree,
                    size: 24,
                    color: isDark ? AppColors.grey500 : AppColors.grey600,
                  ),
                ),
      ),
    );
  }
}
