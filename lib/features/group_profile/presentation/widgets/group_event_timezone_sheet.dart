import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_schedule_utils.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';

class GroupEventTimezoneSheet extends StatelessWidget {
  final String selected;

  const GroupEventTimezoneSheet({super.key, required this.selected});

  static Future<String?> show(
    BuildContext context, {
    required String selected,
  }) {
    return GroupEventSheet.show<String>(
      context,
      builder: (_) => GroupEventTimezoneSheet(selected: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final activeColor = isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    const options = GroupEventTimezoneOption.all;

    return GroupEventSheet(
      title: context.l10n.group_event_timezone,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: options.length,
        separatorBuilder:
            (_, _) => Divider(height: 1, thickness: 1, color: dividerColor),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.value == selected;
          return InkWell(
            onTap: () => Navigator.of(context).pop(option.value),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.label,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  _Radio(selected: isSelected, color: activeColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? color : AppColors.grey400,
          width: selected ? 6 : 1.5,
        ),
      ),
    );
  }
}
