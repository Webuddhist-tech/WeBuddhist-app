import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';

enum GroupEventDraftAction { continueEditing, delete }

/// The "…" menu on a draft card.
class GroupEventDraftMenuSheet extends StatelessWidget {
  final String title;

  const GroupEventDraftMenuSheet({super.key, required this.title});

  static Future<GroupEventDraftAction?> show(
    BuildContext context, {
    required String title,
  }) {
    return GroupEventSheet.show<GroupEventDraftAction>(
      context,
      builder: (_) => GroupEventDraftMenuSheet(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return GroupEventSheet(
      title: title,
      child: ListView(
        shrinkWrap: true,
        children: [
          InkWell(
            onTap:
                () => Navigator.of(
                  context,
                ).pop(GroupEventDraftAction.continueEditing),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Text(
                l10n.group_event_draft_menu_continue,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          InkWell(
            onTap:
                () => Navigator.of(context).pop(GroupEventDraftAction.delete),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.group_event_draft_menu_delete,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.group_event_draft_menu_delete_hint,
                    style: TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
