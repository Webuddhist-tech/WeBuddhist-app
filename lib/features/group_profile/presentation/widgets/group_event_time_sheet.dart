import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';

/// Wheel picker for a start or end time.
class GroupEventTimeSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final GroupEventTime initial;

  const GroupEventTimeSheet({
    super.key,
    required this.title,
    required this.initial,
    this.subtitle,
  });

  static Future<GroupEventTime?> show(
    BuildContext context, {
    required String title,
    required GroupEventTime initial,
    String? subtitle,
  }) {
    return GroupEventSheet.show<GroupEventTime>(
      context,
      builder:
          (_) => GroupEventTimeSheet(
            title: title,
            initial: initial,
            subtitle: subtitle,
          ),
    );
  }

  @override
  State<GroupEventTimeSheet> createState() => _GroupEventTimeSheetState();
}

class _GroupEventTimeSheetState extends State<GroupEventTimeSheet> {
  late GroupEventTime _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final now = DateTime.now();

    return GroupEventSheet(
      title: widget.title,
      footer: GroupEventSheet.primaryButton(
        context,
        label: l10n.done,
        onPressed: () => Navigator.of(context).pop(_value),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Text(
                widget.subtitle!,
                style: TextStyle(fontSize: 13, color: secondaryColor),
              ),
            ),
          SizedBox(
            height: 216,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: isDark ? Brightness.dark : Brightness.light,
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                minuteInterval: 5,
                use24hFormat: MediaQuery.of(context).alwaysUse24HourFormat,
                initialDateTime: DateTime(
                  now.year,
                  now.month,
                  now.day,
                  widget.initial.hour,
                  widget.initial.minute - widget.initial.minute % 5,
                ),
                onDateTimeChanged:
                    (dt) => _value = GroupEventTime(dt.hour, dt.minute),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
