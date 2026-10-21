import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';

/// "Who adds the count?" for one accumulation.
class GroupEventCountModeSheet extends StatelessWidget {
  final GroupEventCountMode selected;

  /// True when another accumulation on the event already takes attendee
  /// counts. The event page only offers count entry for one, so the
  /// attendees option is disabled.
  final bool attendeesTaken;

  const GroupEventCountModeSheet({
    super.key,
    required this.selected,
    this.attendeesTaken = false,
  });

  static Future<GroupEventCountMode?> show(
    BuildContext context, {
    required GroupEventCountMode selected,
    bool attendeesTaken = false,
  }) {
    return GroupEventSheet.show<GroupEventCountMode>(
      context,
      builder:
          (_) => GroupEventCountModeSheet(
            selected: selected,
            attendeesTaken: attendeesTaken,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final activeColor = isDark ? AppColors.surfaceWhite : AppColors.textPrimary;

    Widget option(
      GroupEventCountMode mode,
      String title,
      String hint, {
      bool enabled = true,
    }) {
      final isSelected = mode == selected;
      final row = InkWell(
        onTap: enabled ? () => Navigator.of(context).pop(mode) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: TextStyle(fontSize: 13, color: secondaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? activeColor : AppColors.grey400,
                    width: isSelected ? 6 : 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return enabled ? row : Opacity(opacity: 0.5, child: row);
    }

    final attendeesDisabled =
        attendeesTaken && selected != GroupEventCountMode.attendees;

    return GroupEventSheet(
      title: l10n.group_event_count_mode_title,
      child: ListView(
        shrinkWrap: true,
        children: [
          option(
            GroupEventCountMode.attendees,
            l10n.group_event_count_mode_attendees,
            attendeesDisabled
                ? l10n.group_event_count_mode_attendees_taken
                : l10n.group_event_count_mode_attendees_hint,
            enabled: !attendeesDisabled,
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          option(
            GroupEventCountMode.admin,
            l10n.group_event_count_mode_admin,
            l10n.group_event_count_mode_admin_hint,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
