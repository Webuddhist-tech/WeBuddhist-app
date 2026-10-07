import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/group_accumulations_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pill entry point for group accumulations on the mala screen.
///
/// Always reserves [barHeight] so bead layout does not shift when the groups
/// request resolves. The pill is shown only when
/// `GET /accumulators/{presetId}/groups?joined_only=true` returns groups.
///
/// Tapping opens [GroupAccumulationsSheet], which shows lifetime totals per
/// accumulation and personal `total_counted`.
/// The mala counter above uses session counts when a group is selected.
class GroupAccumulationsBar extends ConsumerWidget {
  const GroupAccumulationsBar({
    super.key,
    required this.mantra,
    required this.presetTitle,
  });

  final Mantra mantra;

  /// Mantra name shown in the sheet's header.
  final String presetTitle;

  static const barHeight = 40.0;
  static const _avatarSize = 28.0;
  static const _avatarOverlap = 10.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(
      joinedAccumulatorGroupsProvider(mantra.presetId),
    );

    return SizedBox(
      height: barHeight,
      child: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) return const SizedBox.shrink();
          return _GroupAccumulationsBarContent(
            mantra: mantra,
            presetTitle: presetTitle,
            groups: groups,
            avatarSize: _avatarSize,
            avatarOverlap: _avatarOverlap,
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _GroupAccumulationsBarContent extends ConsumerWidget {
  const _GroupAccumulationsBarContent({
    required this.mantra,
    required this.presetTitle,
    required this.groups,
    required this.avatarSize,
    required this.avatarOverlap,
  });

  final Mantra mantra;
  final String presetTitle;
  final List<AccumulatorGroup> groups;
  final double avatarSize;
  final double avatarOverlap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor =
        isDark ? const Color(0xCC454545) : AppColors.grey100;
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final userAvatarUrl = ref.watch(userProvider).user?.avatarUrl;
    final groupPreview = groups.take(2).toList();
    final avatarCount = 1 + groupPreview.length;
    final stackWidth = avatarSize + (avatarCount - 1) * avatarOverlap;

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: pillColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap:
              () => GroupAccumulationsSheet.show(
                context,
                mantra: mantra,
                presetTitle: presetTitle,
                groups: groups,
              ),
          child: Container(
            height: GroupAccumulationsBar.barHeight,
            padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: stackWidth,
                  height: avatarSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        child: _BarUserAvatar(
                          avatarUrl: userAvatarUrl,
                          size: avatarSize,
                        ),
                      ),
                      for (var i = 0; i < groupPreview.length; i++)
                        Positioned(
                          left: (i + 1) * avatarOverlap,
                          child: _GroupAvatar(
                            group: groupPreview[i],
                            size: avatarSize,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  AppAssets.caretRight2,
                  size: 24,
                  color: iconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarUserAvatar extends StatelessWidget {
  const _BarUserAvatar({required this.size, this.avatarUrl});

  final double size;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final fallbackColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fallbackColor,
        border: Border.all(color: AppColors.surfaceWhite, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          avatarUrl != null && avatarUrl!.isNotEmpty
              ? CachedNetworkImageWidget(
                imageUrl: avatarUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
              : Icon(
                AppAssets.profile,
                size: size * 0.55,
                color: AppColors.grey600,
              ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.group, required this.size});

  final AccumulatorGroup group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallbackColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fallbackColor,
        border: Border.all(color: AppColors.surfaceWhite, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: ResponsiveCoverImage(
        image: group.image,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
