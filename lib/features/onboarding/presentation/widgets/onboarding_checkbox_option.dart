import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_option_card.dart';

/// Multi-select row used on the tradition step.
class OnboardingCheckboxOption extends StatelessWidget {
  const OnboardingCheckboxOption({
    super.key,
    required this.label,
    required this.isChecked,
    required this.onTap,
    this.bordered = true,
  });

  final String label;
  final bool isChecked;

  /// Null disables the row.
  final VoidCallback? onTap;

  /// See [OnboardingOptionCard.bordered].
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isChecked,
      child: OnboardingOptionCard(
        mark: _CheckMark(isChecked: isChecked),
        label: label,
        onTap: onTap,
        bordered: bordered,
      ),
    );
  }
}

class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.isChecked});

  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idleBorder = isDark ? AppColors.grey500 : const Color(0xFFC8C8C8);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isChecked ? AppColors.brandblue : Colors.transparent,
        border: Border.all(
          color: isChecked ? AppColors.brandblue : idleBorder,
          width: 1.5,
        ),
      ),
      child:
          isChecked
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : null,
    );
  }
}
