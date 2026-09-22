import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Chip that opens the event's prayer requests, under the live stream or in
/// the app bar.
class PrayerRequestsButton extends StatelessWidget {
  const PrayerRequestsButton({
    super.key,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppAssets.handsPraying, size: 18, color: foreground),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.event_prayer_requests,
                    strutStyle: context.tibetanStrutStyle(13, compact: true),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: foreground,
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
