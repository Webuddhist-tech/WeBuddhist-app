import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Tappable row shared by the onboarding radio and checkbox options: a
/// selection [mark] followed by [label].
class OnboardingOptionCard extends StatelessWidget {
  const OnboardingOptionCard({
    super.key,
    required this.mark,
    required this.label,
    required this.onTap,
    this.bordered = true,
  });

  final Widget mark;
  final String label;
  final VoidCallback onTap;

  /// Choices use a bordered card. A trailing "select all" row is plain.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
    final borderColor =
        isDark ? AppColors.cardBorderDark : const Color(0xFFE6E4DE);

    final row = Row(
      children: [
        mark,
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
              height: 1.3,
            ),
          ),
        ),
      ],
    );

    if (!bordered) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: row,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: row,
          ),
        ),
      ),
    );
  }
}
