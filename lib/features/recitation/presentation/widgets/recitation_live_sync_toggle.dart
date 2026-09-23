import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_live_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Live" pill for the reader's app bar: red while the reader follows the
/// operator's position, grey once the user scrolls away or opts out.
/// Shown only while the room has a position to follow.
class RecitationLiveSyncToggle extends ConsumerWidget {
  final String eventId;

  const RecitationLiveSyncToggle({super.key, required this.eventId});

  static const _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (hasPosition, isFollowing) = ref.watch(
      recitationLiveProvider(
        eventId,
      ).select((s) => (s.hasPosition, s.isFollowing)),
    );
    if (!hasPosition) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final offColor = isDark ? AppColors.grey600 : AppColors.grey500;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Tooltip(
          message: context.l10n.recitation_live_sync,
          child: Material(
            color: isFollowing ? AppColors.primary : offColor,
            borderRadius: _radius,
            child: InkWell(
              borderRadius: _radius,
              onTap: () {
                final notifier = ref.read(
                  recitationLiveProvider(eventId).notifier,
                );
                if (isFollowing) {
                  notifier.stopFollowing();
                } else {
                  notifier.resumeFollowing();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFollowing)
                      const Icon(
                        AppAssets.broadcast,
                        size: 16,
                        color: AppColors.surfaceWhite,
                      )
                    else
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceWhite,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.recitation_live_label,
                      style: const TextStyle(
                        color: AppColors.surfaceWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
