import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';

/// Asks how the user attends a hybrid event; null when dismissed.
class GroupEventParticipationDialog extends StatelessWidget {
  const GroupEventParticipationDialog({super.key});

  static Future<GroupEventParticipationType?> show(BuildContext context) {
    return showDialog<GroupEventParticipationType>(
      context: context,
      builder: (_) => const GroupEventParticipationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    const buttonFontSize = 15.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    );

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.connect_event_participation_prompt,
              strutStyle: context.tibetanStrutStyle(18),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  () => Navigator.of(
                    context,
                  ).pop(GroupEventParticipationType.offline),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                backgroundColor:
                    isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                foregroundColor:
                    isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                shape: shape,
              ),
              child: Text(
                l10n.connect_events_filter_in_person,
                strutStyle: context.tibetanStrutStyle(
                  buttonFontSize,
                  compact: true,
                ),
                style: const TextStyle(
                  fontSize: buttonFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  () => Navigator.of(
                    context,
                  ).pop(GroupEventParticipationType.online),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                backgroundColor:
                    isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
                foregroundColor:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                shape: shape,
              ),
              child: Text(
                l10n.connect_online,
                strutStyle: context.tibetanStrutStyle(
                  buttonFontSize,
                  compact: true,
                ),
                style: const TextStyle(
                  fontSize: buttonFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
