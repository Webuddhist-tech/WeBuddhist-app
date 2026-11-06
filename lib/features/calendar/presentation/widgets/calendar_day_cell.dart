import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// A single day cell in the calendar grid: the Gregorian date on top and the
/// Tibetan lunar day beneath, with an optional event dot.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.gregorianDay,
    required this.lunarDay,
    this.isOutside = false,
    this.isSelected = false,
    this.isToday = false,
    this.hasEvent = false,
  });

  final int gregorianDay;
  final int? lunarDay;
  final bool isOutside;
  final bool isSelected;
  final bool isToday;
  final bool hasEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final Color fill;
    if (isOutside) {
      fill = Colors.transparent;
    } else {
      fill = dark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite;
    }

    final Color primaryText =
        isOutside
            ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
            : theme.colorScheme.onSurface;
    final Color lunarText = theme.colorScheme.onSurface.withValues(
      alpha: isOutside ? 0.3 : 0.55,
    );

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border:
            isSelected ? Border.all(color: theme.colorScheme.onSurface) : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$gregorianDay',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: primaryText,
                    fontWeight:
                        isSelected || isToday
                            ? FontWeight.w700
                            : FontWeight.w500,
                    decoration: isToday ? TextDecoration.underline : null,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  lunarDay != null ? '$lunarDay' : '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: lunarText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (hasEvent)
            Positioned(
              top: 5,
              right: 6,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: dark ? AppColors.blueDark : AppColors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
