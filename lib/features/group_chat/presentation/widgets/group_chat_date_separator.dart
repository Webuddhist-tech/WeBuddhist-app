import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_thread_rows.dart';
import 'package:intl/intl.dart';

/// Centered day pill between message runs.
class GroupChatDateSeparator extends StatelessWidget {
  const GroupChatDateSeparator({super.key, required this.day, this.now});

  final DateTime day;

  /// Injectable for tests; defaults to the wall clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            // White on the cream page, with a soft shadow, per the mocks.
            color:
                isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            _label(context),
            strutStyle: context.tibetanStrutStyle(13, compact: true),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  String _label(BuildContext context) {
    final kind = chatDateLabelKind(day, now ?? DateTime.now());
    switch (kind) {
      case ChatDateLabelKind.today:
        return context.l10n.group_chat_today;
      case ChatDateLabelKind.yesterday:
        return context.l10n.group_chat_yesterday;
      case ChatDateLabelKind.thisYear:
      case ChatDateLabelKind.older:
        final locale = intlFormatLocaleOf(context);
        final pattern =
            kind == ChatDateLabelKind.thisYear
                ? DateFormat.MMMd(locale)
                : DateFormat.yMMMd(locale);
        final formatted = pattern.format(day);
        return context.isTibetanLocale ? toTibetanDigits(formatted) : formatted;
    }
  }
}
