import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_accumulation_selection.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/group_accumulation_counts_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_accumulation_selection_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/utils/mala_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Bottom sheet for choosing personal vs group accumulation on the mala screen.
///
/// Group row counts show lifetime totals from
/// `GET /accumulators/{presetId}/groups` (`user_total_count`), plus any unsynced
/// local taps via [GroupAccumulationCountsNotifier.displayLifetimeCount]. The
/// personal row shows lifetime `total_counted` from
/// `GET /accumulators/{parent_id}` via [MalaCounterNotifier.displayLifetimeCount].
/// The on-screen mala counter uses session counts instead; those reset to 0 on
/// DELETE while lifetime totals here do not.
class GroupAccumulationsSheet extends ConsumerStatefulWidget {
  const GroupAccumulationsSheet({
    super.key,
    required this.presetId,
    required this.groups,
    required this.personalLifetimeCount,
    this.showPersonalRow = true,
  });

  final String presetId;
  final List<AccumulatorGroup> groups;
  final int personalLifetimeCount;

  /// When false (e.g. group chant reader), only group rows are shown.
  final bool showPersonalRow;

  static Future<void> show(
    BuildContext context, {
    required String presetId,
    required List<AccumulatorGroup> groups,
    required int personalLifetimeCount,
    bool showPersonalRow = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder:
          (_) => GroupAccumulationsSheet(
            presetId: presetId,
            groups: groups,
            personalLifetimeCount: personalLifetimeCount,
            showPersonalRow: showPersonalRow,
          ),
    );
  }

  @override
  ConsumerState<GroupAccumulationsSheet> createState() =>
      _GroupAccumulationsSheetState();
}

class _GroupAccumulationsSheetState
    extends ConsumerState<GroupAccumulationsSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureUserLoaded());
  }

  void _ensureUserLoaded() {
    final userState = ref.read(userProvider);
    if (userState.user == null && !userState.isLoading) {
      ref.read(userProvider.notifier).refreshUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider).user;
    final selection = ref.watch(
      malaAccumulationSelectionProvider(widget.presetId),
    );
    final accentColor = isDark ? AppColors.blueDark : AppColors.blue;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final locale = intlFormatLocaleOf(context);
    ref.watch(groupAccumulationCountsProvider(widget.presetId));
    final groups =
        ref
            .watch(joinedAccumulatorGroupsProvider(widget.presetId))
            .valueOrNull ??
        widget.groups;
    final countsNotifier = ref.read(
      groupAccumulationCountsProvider(widget.presetId).notifier,
    );

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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.showPersonalRow) ...[
                _SelectableAccumulationRow(
                  isSelected: selection.isPersonal,
                  accentColor: accentColor,
                  onTap:
                      () => _select(
                        const MalaAccumulationSelection.personal(),
                        groups,
                      ),
                  leading: _UserAvatar(avatarUrl: user?.avatarUrl),
                  title: user != null ? _userDisplayName(user) : '—',
                  formattedCount: NumberFormat.decimalPattern(
                    locale,
                  ).format(widget.personalLifetimeCount),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: dividerColor),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  context.l10n.mala_group_accumulations,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: groups.length,
                  separatorBuilder:
                      (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        indent: 20,
                        endIndent: 20,
                        color: dividerColor,
                      ),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final isSelected =
                        selection.groupAccumulatorId ==
                        group.groupAccumulatorId;

                    return _SelectableAccumulationRow(
                      isSelected: isSelected,
                      accentColor: accentColor,
                      onTap:
                          () => _select(
                            MalaAccumulationSelection.group(
                              group.groupAccumulatorId,
                            ),
                            groups,
                          ),
                      leading: _GroupAvatar(group: group),
                      title:
                          group.title?.trim().isNotEmpty == true
                              ? group.title!.trim()
                              : context.l10n.mala_group_untitled,
                      formattedCount: NumberFormat.decimalPattern(
                        locale,
                      ).format(
                        countsNotifier.displayLifetimeCount(
                          group.groupAccumulatorId,
                          group.userTotalCount,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Applies [next] and reports the change once it is the live selection.
  void _select(MalaAccumulationSelection next, List<AccumulatorGroup> groups) {
    final provider = malaAccumulationSelectionProvider(widget.presetId);
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

  String _userDisplayName(User user) {
    final parts =
        [
          user.firstName,
          user.lastName,
        ].whereType<String>().where((name) => name.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' ');
    return user.displayName;
  }
}

class _SelectableAccumulationRow extends StatelessWidget {
  const _SelectableAccumulationRow({
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.formattedCount,
  });

  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String formattedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameColor = isSelected ? accentColor : theme.colorScheme.onSurface;
    final countColor = isSelected ? accentColor : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: nameColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formattedCount,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: countColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.avatarUrl});

  final String? avatarUrl;

  static const _size = 40.0;

  @override
  Widget build(BuildContext context) {
    final fallbackColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return ClipOval(
      child: SizedBox(
        width: _size,
        height: _size,
        child:
            avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: avatarUrl,
                  width: _size,
                  height: _size,
                  fit: BoxFit.cover,
                )
                : ColoredBox(
                  color: fallbackColor,
                  child: Icon(
                    AppAssets.profile,
                    size: 22,
                    color: AppColors.grey600,
                  ),
                ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.group});

  final AccumulatorGroup group;

  static const _size = 40.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;

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
                    size: 22,
                    color: isDark ? AppColors.grey500 : AppColors.grey600,
                  ),
                ),
      ),
    );
  }
}
