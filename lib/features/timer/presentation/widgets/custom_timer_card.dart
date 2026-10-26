import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// The "Create a custom timer" row at the top of "Your timers".
/// Timers the user has already created are listed under it.
class CustomTimerCard extends StatelessWidget {
  const CustomTimerCard({super.key, required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  static const _borderRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Theme.of(context).colorScheme.onSurface;
    final mutedColor = color.withValues(alpha: 0.45);

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(_borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: mutedColor),
                ),
                child: Icon(AppAssets.plus, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(AppAssets.caretRight, size: 18, color: mutedColor),
            ],
          ),
        ),
      ),
    );
  }
}
