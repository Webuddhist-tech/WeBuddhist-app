import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Confirms deleting [count] of the member's own messages.
///
/// Only deleting for everyone is offered. The API has no delete-for-me, so a
/// second option would have to be faked locally and would quietly disagree
/// with what everyone else sees.
///
/// Resolves true when the member confirms.
Future<bool> confirmChatMessageDelete(
  BuildContext context, {
  int count = 1,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _DeleteMessageDialog(count: count),
  );
  return confirmed ?? false;
}

/// Title, one line of body, then two stacked full-width outlined pills —
/// Delete in red above Cancel — per the mock.
class _DeleteMessageDialog extends StatelessWidget {
  const _DeleteMessageDialog({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Dialog(
      backgroundColor:
          isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              count > 1
                  ? l10n.group_chat_delete_title_many(count)
                  : l10n.group_chat_delete_title,
              strutStyle: context.tibetanStrutStyle(18, compact: true),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.group_chat_delete_confirm_body,
              strutStyle: context.tibetanStrutStyle(14),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.grey300 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _PillButton(
              label: l10n.group_chat_delete,
              color: AppColors.error,
              isDark: isDark,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            _PillButton(
              label: l10n.cancel,
              color: titleColor,
              isDark: isDark,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.color,
    required this.isDark,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: isDark ? AppColors.grey800 : AppColors.grey300),
        shape: const StadiumBorder(),
        foregroundColor: color,
      ),
      child: Text(
        label,
        strutStyle: context.tibetanStrutStyle(15, compact: true),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
