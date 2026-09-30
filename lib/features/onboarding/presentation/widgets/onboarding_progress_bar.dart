import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Segmented progress for the language and tradition onboarding steps.
///
/// The active step and every step before it are filled. Later steps stay
/// on the track color.
class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  /// Zero-based index of the step on screen.
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive = isDark ? AppColors.grey800 : const Color(0xFFE6E3DB);

    return Row(
      children: [
        for (var index = 0; index < totalSteps; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              decoration: BoxDecoration(
                color: index <= currentStep ? AppColors.brandblue : inactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
