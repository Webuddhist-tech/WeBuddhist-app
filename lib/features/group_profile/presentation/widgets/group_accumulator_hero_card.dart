import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_ended_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:intl/intl.dart';

class GroupAccumulatorHeroCard extends StatelessWidget {
  final GroupAccumulatorDetail detail;
  final bool hasJoined;
  final bool isDark;
  final bool isJoining;
  final VoidCallback? onJoinTap;
  final VoidCallback? onActionTap;

  const GroupAccumulatorHeroCard({
    super.key,
    required this.detail,
    required this.hasJoined,
    required this.isDark,
    this.isJoining = false,
    this.onJoinTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern(
      intlFormatLocaleOf(context),
    );
    final progressText =
        '${numberFormat.format(detail.totalCount)} / ${numberFormat.format(detail.targetCount)}';
    final showJoinButton = !hasJoined;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final primaryTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final progressTrackColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey50;

    return Material(
      color: cardColor,
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child:
                detail.image != null && !detail.image!.isEmpty
                    ? ResponsiveCoverImage(
                      image: detail.image,
                      fit: BoxFit.cover,
                    )
                    : ColoredBox(
                      color:
                          isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.grey100,
                      child: Icon(
                        AppAssets.bookOpenText,
                        size: 40,
                        color: isDark ? AppColors.grey500 : AppColors.grey600,
                      ),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.group_accumulator_participants(
                    detail.memberCount,
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  detail.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        progressText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                    Text(
                      '${detail.progressPercent}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: detail.progressFraction,
                    minHeight: 8,
                    backgroundColor:
                        isDark ? AppColors.cardBorderDark : progressTrackColor,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                if (showJoinButton)
                  _JoinButton(
                    isDark: isDark,
                    isJoining: isJoining,
                    onTap: onJoinTap,
                  )
                else
                  _ActionButton(
                    isDark: isDark,
                    ended: isPastEndDate(detail.endDate, DateTime.now()),
                    onTap: onActionTap,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isDark;
  final bool ended;
  final VoidCallback? onTap;

  const _ActionButton({required this.isDark, required this.ended, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBorderDark : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          ended
              ? context.l10n.group_accumulator_view_practice
              : context.l10n.group_accumulator_recite_now,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final bool isDark;
  final bool isJoining;
  final VoidCallback? onTap;

  const _JoinButton({
    required this.isDark,
    required this.isJoining,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isJoining ? null : onTap,
      child: Container(
        height: 44,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBorderDark : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            isJoining
                ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                )
                : Text(
                  context.l10n.group_join_to_contribute,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
      ),
    );
  }
}
