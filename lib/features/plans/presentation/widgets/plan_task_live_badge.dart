import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Small Live chip beside a plan task title.
class PlanTaskLiveBadge extends StatelessWidget {
  const PlanTaskLiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Text(
        context.l10n.recitation_live_label,
        style: const TextStyle(
          color: AppColors.surfaceWhite,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Red Live label for the top of a task that is live when the reader is not
/// following a recitation. The follow control is [RecitationLiveSyncToggle].
class PlanTaskLiveLabel extends StatelessWidget {
  const PlanTaskLiveLabel({super.key});

  static const _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: AppColors.primary,
          borderRadius: _radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  AppAssets.broadcast,
                  size: 16,
                  color: AppColors.surfaceWhite,
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
    );
  }
}
