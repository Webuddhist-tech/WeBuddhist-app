import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

/// Notice shown on a private group profile once the join endpoint reports the
/// signed-in user was removed by an admin. [expiresAt] is the server ban
/// expiry; the rejoin block is dropped when the server sent no end date.
class GroupRemovedNoticeCard extends StatelessWidget {
  final String groupTitle;
  final DateTime? expiresAt;
  final bool isDark;
  final double? lineHeight;

  const GroupRemovedNoticeCard({
    super.key,
    required this.groupTitle,
    required this.expiresAt,
    required this.isDark,
    this.lineHeight,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final bodyColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final expiry = expiresAt?.toLocal();
    final daysLeft = expiry == null ? null : _daysLeft(expiry);

    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? Color.lerp(AppColors.cardDark, AppColors.error, 0.12)
                : Color.lerp(AppColors.surfaceWhite, AppColors.error, 0.06),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWhite,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppAssets.warningCircleFill,
                  size: 22,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.group_removed_title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    height: lineHeight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            daysLeft == null
                ? l10n.group_removed_message_no_date(groupTitle)
                : l10n.group_removed_message(
                  groupTitle,
                  _durationLabel(context, daysLeft),
                ),
            style: TextStyle(
              fontSize: 14,
              color: bodyColor,
              height: lineHeight ?? 1.4,
            ),
          ),
          if (expiry != null && daysLeft != null) ...[
            const SizedBox(height: 16),
            _buildRejoinBlock(context, expiry, daysLeft, titleColor, bodyColor),
          ],
        ],
      ),
    );
  }

  Widget _buildRejoinBlock(
    BuildContext context,
    DateTime expiry,
    int daysLeft,
    Color titleColor,
    Color bodyColor,
  ) {
    final date = DateFormat.MMMEd(intlFormatLocaleOf(context)).format(expiry);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.group_removed_rejoin_label,
            style: TextStyle(
              fontSize: 13,
              color: bodyColor,
              height: lineHeight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.group_removed_rejoin_value(
              date,
              _daysLeftLabel(context, daysLeft),
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: titleColor,
              height: lineHeight,
            ),
          ),
        ],
      ),
    );
  }

  /// Whole days until the ban lifts, rounded up so a part-day still reads as a
  /// day. Returns 0 once the expiry has passed.
  int _daysLeft(DateTime expiry) {
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) return 0;
    return (remaining.inMinutes / Duration.minutesPerDay).ceil();
  }

  String _durationLabel(BuildContext context, int days) {
    return days == 1
        ? context.l10n.group_remove_member_duration_day
        : context.l10n.group_remove_member_duration_days(days);
  }

  String _daysLeftLabel(BuildContext context, int days) {
    return switch (days) {
      0 => context.l10n.group_removed_last_day,
      1 => context.l10n.group_removed_day_left,
      _ => context.l10n.group_removed_days_left(days),
    };
  }
}
