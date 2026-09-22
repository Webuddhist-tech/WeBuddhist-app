import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/timer_sheet_header.dart';

/// Minute-wheel picker for the "Duration" row on the New Timer screen.
///
/// Pops with the selected minute count, or `null` if dismissed without a
/// change (swipe-to-dismiss) — callers should keep their previous value in
/// that case.
class DurationPickerSheet extends StatefulWidget {
  const DurationPickerSheet({super.key, required this.initialMinutes});

  final int initialMinutes;

  static const minMinutes = 1;
  static const maxMinutes = 180;

  static Future<int?> show(
    BuildContext context, {
    required int initialMinutes,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DurationPickerSheet(initialMinutes: initialMinutes),
    );
  }

  @override
  State<DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<DurationPickerSheet> {
  static const _itemExtent = 48.0;

  late int _selected = widget.initialMinutes.clamp(
    DurationPickerSheet.minMinutes,
    DurationPickerSheet.maxMinutes,
  );
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(
        initialItem: _selected - DurationPickerSheet.minMinutes,
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final itemCount =
        DurationPickerSheet.maxMinutes - DurationPickerSheet.minMinutes + 1;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            TimerSheetHeader(
              title: 'Duration',
              onClose: () => Navigator.of(context).pop(_selected),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: _itemExtent,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: _controller,
                    itemExtent: _itemExtent,
                    diameterRatio: 4,
                    perspective: 0.003,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(
                        () =>
                            _selected = index + DurationPickerSheet.minMinutes,
                      );
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: itemCount,
                      builder: (context, index) {
                        final value = index + DurationPickerSheet.minMinutes;
                        final isSelected = value == _selected;
                        return Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$value',
                                style: TextStyle(
                                  fontSize: isSelected ? 24 : 18,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                  color:
                                      isSelected
                                          ? textColor
                                          : textColor.withValues(alpha: 0.35),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'min',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withValues(
                                    alpha: isSelected ? 0.6 : 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
