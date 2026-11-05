import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Shared plan progress bar. Fills the width it is given, so callers place
/// it on its own row to span the card.
class PlanProgressBar extends StatelessWidget {
  const PlanProgressBar({super.key, required this.value, this.height = 6});

  /// Completion ratio, 0..1.
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor =
        isDark ? AppColors.grey800.withValues(alpha: 0.6) : AppColors.grey300;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: trackColor,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.planProgress),
      ),
    );
  }
}
