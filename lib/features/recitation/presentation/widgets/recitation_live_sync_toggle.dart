import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_live_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sync button for the reader's app bar: lit green while the reader follows
/// the operator's position, greyed once the user scrolls away or opts out.
/// Shown only while the room has a position to follow.
class RecitationLiveSyncToggle extends ConsumerWidget {
  final String eventId;

  const RecitationLiveSyncToggle({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (hasPosition, isFollowing) = ref.watch(
      recitationLiveProvider(
        eventId,
      ).select((s) => (s.hasPosition, s.isFollowing)),
    );
    if (!hasPosition) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final liveColor =
        isDark ? AppColors.eventOnlineChipDark : AppColors.eventOnlineChip;
    final offColor = isDark ? AppColors.grey600 : AppColors.grey500;

    return IconButton(
      isSelected: isFollowing,
      tooltip: context.l10n.recitation_live_sync,
      icon: Icon(
        AppAssets.arrowsClockwise,
        color: isFollowing ? liveColor : offColor,
      ),
      onPressed: () {
        final notifier = ref.read(recitationLiveProvider(eventId).notifier);
        if (isFollowing) {
          notifier.stopFollowing();
        } else {
          notifier.resumeFollowing();
        }
      },
    );
  }
}
