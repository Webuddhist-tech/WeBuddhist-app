import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_option_card.dart';

/// Bordered single-select row used on the language step.
class OnboardingRadioOption extends StatelessWidget {
  const OnboardingRadioOption({
    super.key,
    required this.id,
    required this.label,
    required this.selectedId,
    required this.onSelect,
  });

  final String id;
  final String label;
  final String? selectedId;
  final void Function(String id) onSelect;

  bool get isSelected => selectedId == id;

  @override
  Widget build(BuildContext context) {
    return OnboardingOptionCard(
      mark: _RadioMark(isSelected: isSelected),
      label: label,
      onTap: () => onSelect(id),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idleBorder = isDark ? AppColors.grey500 : const Color(0xFFC8C8C8);

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.brandblue : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.brandblue : idleBorder,
          width: 1.5,
        ),
      ),
      child:
          isSelected
              ? const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: SizedBox(width: 8, height: 8),
                ),
              )
              : null,
    );
  }
}
