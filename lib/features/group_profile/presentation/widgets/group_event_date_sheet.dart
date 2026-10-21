import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_schedule_utils.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';
import 'package:table_calendar/table_calendar.dart';

/// Month grid; past days are disabled for a new event.
class GroupEventDateSheet extends StatefulWidget {
  final String title;
  final DateTime? selected;
  final DateTime? minDate;

  const GroupEventDateSheet({
    super.key,
    required this.title,
    this.selected,
    this.minDate,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    required String title,
    DateTime? selected,
    DateTime? minDate,
  }) {
    return GroupEventSheet.show<DateTime>(
      context,
      builder:
          (_) => GroupEventDateSheet(
            title: title,
            selected: selected,
            minDate: minDate,
          ),
    );
  }

  @override
  State<GroupEventDateSheet> createState() => _GroupEventDateSheetState();
}

class _GroupEventDateSheetState extends State<GroupEventDateSheet> {
  late DateTime _focused = widget.selected ?? widget.minDate ?? DateTime.now();

  DateTime get _first =>
      GroupEventScheduleUtils.dateOnly(widget.minDate ?? DateTime.now());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final onPrimary = isDark ? AppColors.textPrimary : AppColors.surfaceWhite;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final selected = widget.selected;

    return GroupEventSheet(
      title: widget.title,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: TableCalendar<void>(
          firstDay: DateTime(_first.year - 1, 1, 1),
          lastDay: DateTime(_first.year + 10, 12, 31),
          focusedDay: _focused,
          currentDay: GroupEventScheduleUtils.dateOnly(DateTime.now()),
          locale: intlFormatLocaleOf(context),
          startingDayOfWeek: StartingDayOfWeek.sunday,
          availableGestures: AvailableGestures.horizontalSwipe,
          rowHeight: 44,
          enabledDayPredicate: (day) => !day.isBefore(_first),
          selectedDayPredicate:
              (day) => selected != null && isSameDay(day, selected),
          onDaySelected: (day, _) {
            Navigator.of(context).pop(GroupEventScheduleUtils.dateOnly(day));
          },
          onPageChanged: (focused) => setState(() => _focused = focused),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: false,
            titleTextStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            leftChevronIcon: Icon(
              AppAssets.caretLeft,
              size: 20,
              color: secondaryColor,
            ),
            rightChevronIcon: Icon(AppAssets.caretRight, size: 20),
            headerPadding: const EdgeInsets.fromLTRB(8, 4, 0, 8),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontSize: 12, color: secondaryColor),
            weekendStyle: TextStyle(fontSize: 12, color: secondaryColor),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: const TextStyle(fontSize: 15),
            weekendTextStyle: const TextStyle(fontSize: 15),
            disabledTextStyle: TextStyle(
              fontSize: 15,
              color: AppColors.grey400,
            ),
            todayTextStyle: TextStyle(fontSize: 15, color: primary),
            todayDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentGoldDarkest),
            ),
            selectedTextStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: onPrimary,
            ),
            selectedDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary,
            ),
          ),
        ),
      ),
    );
  }
}
