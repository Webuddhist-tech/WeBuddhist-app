import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_date_format.dart';

class SeriesPlanProgressBar extends StatelessWidget {
  const SeriesPlanProgressBar({super.key, required this.progress});

  final SeriesProgress progress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor =
        isDark ? AppColors.grey800.withValues(alpha: 0.6) : AppColors.grey300;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress.fraction,
        minHeight: 4,
        backgroundColor: trackColor,
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF2B24F)),
      ),
    );
  }
}

class SeriesPlanPartnerRow extends StatelessWidget {
  const SeriesPlanPartnerRow({
    super.key,
    required this.partner,
    required this.fontSize,
    this.avatarSize,
  });

  final SeriesPartner partner;
  final double fontSize;
  final double? avatarSize;

  @override
  Widget build(BuildContext context) {
    final isTibetan = context.isTibetanLocale;
    final secondaryColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final resolvedAvatarSize = avatarSize ?? fontSize + 8;

    return Row(
      children: [
        ClipOval(
          child: CachedNetworkImageWidget(
            imageUrl: partner.groupImage,
            width: resolvedAvatarSize,
            height: resolvedAvatarSize,
            fit: BoxFit.cover,
            placeholder: SizedBox(
              width: resolvedAvatarSize,
              height: resolvedAvatarSize,
            ),
            errorWidget: SizedBox(
              width: resolvedAvatarSize,
              height: resolvedAvatarSize,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.series_practicing_with_group(partner.groupName),
            strutStyle: context.tibetanStrutStyle(fontSize, compact: true),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: secondaryColor,
              height: isTibetan ? AppFontConfig.tibetanCompactLineHeight : 1.2,
              leadingDistribution:
                  isTibetan ? AppFontConfig.tibetanLeadingDistribution : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class SeriesPlanEnrolledCount extends StatelessWidget {
  const SeriesPlanEnrolledCount({
    super.key,
    required this.count,
    required this.fontSize,
  });

  final int count;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isTibetan = context.isTibetanLocale;
    final secondaryColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: secondaryColor,
      height: isTibetan ? AppFontConfig.tibetanCompactLineHeight : 1.2,
      leadingDistribution:
          isTibetan ? AppFontConfig.tibetanLeadingDistribution : null,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppAssets.usercard, size: fontSize + 2, color: secondaryColor),
        const SizedBox(width: 4),
        Text('$count', style: textStyle),
      ],
    );
  }
}

class SeriesPlanMetaRow extends StatelessWidget {
  const SeriesPlanMetaRow({
    super.key,
    required this.series,
    required this.fontSize,
  });

  final Series series;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final dateRange = PlanDateFormat.formatRangeOrNull(
      series.startDate,
      series.endDate,
    );
    if (dateRange == null && series.enrolledCount <= 0) {
      return const SizedBox.shrink();
    }

    final isTibetan = context.isTibetanLocale;
    final secondaryColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: secondaryColor,
      height: isTibetan ? AppFontConfig.tibetanCompactLineHeight : 1.2,
      leadingDistribution:
          isTibetan ? AppFontConfig.tibetanLeadingDistribution : null,
    );

    return Row(
      children: [
        if (dateRange != null)
          Expanded(
            child: Text(
              dateRange,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (series.enrolledCount > 0)
          SeriesPlanEnrolledCount(
            count: series.enrolledCount,
            fontSize: fontSize,
          ),
      ],
    );
  }
}
