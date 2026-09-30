import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Bordered single-select row used on the language and tradition steps.
class OnboardingRadioOption extends StatelessWidget {
  const OnboardingRadioOption({
    super.key,
    required this.id,
    required this.label,
    required this.selectedId,
    required this.onSelect,
    this.labelStyle,
    this.bordered = true,
  });

  final String id;
  final String label;
  final String? selectedId;
  final void Function(String id) onSelect;
  final TextStyle? labelStyle;

  /// Path choices use a bordered card. "Show me everything" is a plain row.
  final bool bordered;

  bool get isSelected => selectedId == id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
    final borderColor =
        isDark ? AppColors.cardBorderDark : const Color(0xFFE6E4DE);

    final row = Row(
      children: [
        _RadioMark(isSelected: isSelected),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
              height: 1.3,
            ).merge(labelStyle),
          ),
        ),
      ],
    );

    if (!bordered) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: InkWell(
          onTap: () => onSelect(id),
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
          onTap: () => onSelect(id),
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
