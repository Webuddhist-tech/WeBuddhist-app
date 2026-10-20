import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/timer_sheet_header.dart';

/// Hours, minutes, and seconds wheels for the "Duration" row on the New Timer
/// screen, in the style of the iOS timer picker.
///
/// Closing the sheet any way — the X button, a tap outside, or a drag down —
/// keeps the time on the wheels. Returns `null` when that time is 0:00:00 so
/// callers keep their previous duration.
class DurationPickerSheet extends StatefulWidget {
  const DurationPickerSheet({
    super.key,
    required this.initialDuration,
    required this.selected,
  });

  final Duration initialDuration;

  /// Latest time on the wheels. [show] reads this after the sheet closes, so a
  /// barrier tap or drag-down commits the same value as the X button.
  final ValueNotifier<Duration> selected;

  static const maxHours = 23;

  static Future<Duration?> show(
    BuildContext context, {
    required Duration initialDuration,
  }) async {
    final selected = ValueNotifier<Duration>(_clampDuration(initialDuration));
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => DurationPickerSheet(
          initialDuration: initialDuration,
          selected: selected,
        ),
      );
      final value = selected.value;
      return value == Duration.zero ? null : value;
    } finally {
      selected.dispose();
    }
  }

  static Duration _clampDuration(Duration duration) {
    final positive = duration.isNegative ? Duration.zero : duration;
    const max = Duration(hours: maxHours, minutes: 59, seconds: 59);
    final limited = positive > max ? max : positive;
    return Duration(seconds: limited.inSeconds);
  }

  @override
  State<DurationPickerSheet> createState() => _DurationPickerSheetState();
}

const _itemExtent = 44.0;

class _DurationPickerSheetState extends State<DurationPickerSheet> {
  late int _hours;
  late int _minutes;
  late int _seconds;
  late final FixedExtentScrollController _hoursController;
  late final FixedExtentScrollController _minutesController;
  late final FixedExtentScrollController _secondsController;

  @override
  void initState() {
    super.initState();
    final initial = DurationPickerSheet._clampDuration(widget.initialDuration);
    _hours = initial.inHours;
    _minutes = initial.inMinutes.remainder(60);
    _seconds = initial.inSeconds.remainder(60);
    widget.selected.value = _selected;
    _hoursController = FixedExtentScrollController(initialItem: _hours);
    _minutesController = FixedExtentScrollController(initialItem: _minutes);
    _secondsController = FixedExtentScrollController(initialItem: _seconds);
  }

  Duration get _selected =>
      Duration(hours: _hours, minutes: _minutes, seconds: _seconds);

  void _setHours(int value) {
    setState(() => _hours = value);
    widget.selected.value = _selected;
  }

  void _setMinutes(int value) {
    setState(() => _minutes = value);
    widget.selected.value = _selected;
  }

  void _setSeconds(int value) {
    setState(() => _seconds = value);
    widget.selected.value = _selected;
  }

  void _close() => Navigator.of(context).pop();

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            TimerSheetHeader(title: l10n.timer_duration_title, onClose: _close),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: _itemExtent,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: _DurationWheel(
                            controller: _hoursController,
                            itemCount: DurationPickerSheet.maxHours + 1,
                            selected: _hours,
                            unitLabel: l10n.timer_duration_hours,
                            textColor: textColor,
                            onSelected: _setHours,
                          ),
                        ),
                        Expanded(
                          child: _DurationWheel(
                            controller: _minutesController,
                            itemCount: 60,
                            selected: _minutes,
                            unitLabel: l10n.timer_min,
                            textColor: textColor,
                            onSelected: _setMinutes,
                          ),
                        ),
                        Expanded(
                          child: _DurationWheel(
                            controller: _secondsController,
                            itemCount: 60,
                            selected: _seconds,
                            unitLabel: l10n.timer_duration_sec,
                            textColor: textColor,
                            onSelected: _setSeconds,
                          ),
                        ),
                      ],
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

class _DurationWheel extends StatelessWidget {
  const _DurationWheel({
    required this.controller,
    required this.itemCount,
    required this.selected,
    required this.unitLabel,
    required this.textColor,
    required this.onSelected,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final int selected;
  final String unitLabel;
  final Color textColor;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _itemExtent,
      diameterRatio: 3,
      perspective: 0.003,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isSelected = index == selected;
          final numberStyle = TextStyle(
            fontSize: isSelected ? 22 : 20,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? textColor : textColor.withValues(alpha: 0.35),
          );

          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$index', style: numberStyle),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  Text(
                    unitLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: textColor.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
