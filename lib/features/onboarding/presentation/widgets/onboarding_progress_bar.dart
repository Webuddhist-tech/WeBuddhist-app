import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Segmented progress for the onboarding steps.
///
/// As in the Figma onboarding frames, only the step on screen is filled;
/// every other step stays on the track color.
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
    final inactive = isDark ? AppColors.grey800 : const Color(0xFFE5E7EB);

    return Row(
      children: [
        for (var index = 0; index < totalSteps; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: index == currentStep ? AppColors.brandblue : inactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
