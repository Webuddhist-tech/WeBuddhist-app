import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Card under the stats that opens the viewer's prayer requests.
class MePrayerRequestsRow extends StatelessWidget {
  const MePrayerRequestsRow({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.surfaceWhite;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Material(
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Icon(
                  AppAssets.handsPraying,
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.me_prayer_requests,
                    strutStyle: context.tibetanStrutStyle(16, compact: true),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  AppAssets.caretRight,
                  size: 20,
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
