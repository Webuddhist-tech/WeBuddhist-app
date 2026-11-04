import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/series_plan_card_widgets.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_date_format.dart';

/// Horizontal list-row card for a practice plan: a small rounded thumbnail on
/// the left with the title and date range on the right.
class PracticePlanListTile extends StatelessWidget {
  const PracticePlanListTile({
    super.key,
    required this.series,
    required this.onTap,
  });

  final Series series;
  final VoidCallback onTap;

  static const _titleFontSize = 15.0;
  static const _metaFontSize = 13.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateRange = _formatSeriesDateRange(series);

    return Material(
      color: isDark ? AppColors.cardBackgroundDark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 56,
                  width: 56,
                  child: ResponsiveCoverImage(
                    image: series.coverImage,
                    fallbackAsset: 'assets/images/tag_cover/cover_image.jpg',
                    fit: BoxFit.cover,
                    width: 56,
                    height: 56,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      series.title,
                      style: const TextStyle(
                        fontSize: _titleFontSize,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (series.partner != null) ...[
                      if (series.progress != null &&
                          series.progress!.totalDayCount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: SeriesPlanProgressBar(
                                progress: series.progress!,
                              ),
                            ),
                            if (series.enrolledCount > 0) ...[
                              const SizedBox(width: 12),
                              SeriesPlanEnrolledCount(
                                count: series.enrolledCount,
                                fontSize: _metaFontSize,
                              ),
                            ],
                          ],
                        ),
                      ] else if (series.enrolledCount > 0) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SeriesPlanEnrolledCount(
                            count: series.enrolledCount,
                            fontSize: _metaFontSize,
                          ),
                        ),
                      ],
                    ] else ...[
                      if (dateRange != null || series.enrolledCount > 0) ...[
                        const SizedBox(height: 4),
                        SeriesPlanMetaRow(
                          series: series,
                          fontSize: _metaFontSize,
                        ),
                      ],
                      if (series.progress != null &&
                          series.progress!.totalDayCount > 0) ...[
                        const SizedBox(height: 8),
                        SeriesPlanProgressBar(progress: series.progress!),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _formatSeriesDateRange(Series series) {
    return PlanDateFormat.formatRangeOrNull(series.startDate, series.endDate);
  }
}
