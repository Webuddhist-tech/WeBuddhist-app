import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/featured_series_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/routine_info_provider.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/featured_plan_section_skeleton.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/series_plan_card_widgets.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeaturedPlanSection extends ConsumerWidget {
  const FeaturedPlanSection({super.key, required this.onSeriesTap});

  final ValueChanged<Series> onSeriesTap;

  static const _horizontalPadding = 16.0;
  static const _imageBorderRadius = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(featuredSeriesFutureProvider);

    return featuredAsync.when(
      data: (layoutEither) {
        return layoutEither.fold((_) => const SizedBox.shrink(), (layout) {
          if (layout == null) return const SizedBox.shrink();
          return _FeaturedPlanContent(layout: layout, onSeriesTap: onSeriesTap);
        });
      },
      loading: () => const FeaturedPlanSectionSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _FeaturedPlanContent extends ConsumerWidget {
  const _FeaturedPlanContent({required this.layout, required this.onSeriesTap});

  final FeaturedSeriesLayout layout;
  final ValueChanged<Series> onSeriesTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isTibetan = context.isTibetanLocale;
    final sectionTitleSize = getLocalizedFontSize(AppTextSize.bodyLarge);
    final titleFontSize = getLocalizedFontSize(AppTextSize.body);
    final dateFontSize = getLocalizedFontSize(AppTextSize.caption);
    final sectionContentGap = isTibetan ? 16.0 : 12.0;
    final itemBottomGap = isTibetan ? 16.0 : 12.0;
    final heroOthersGap = isTibetan ? 20.0 : 16.0;
    final contentPadding = isTibetan ? 16.0 : 12.0;
    final titleDateGap = isTibetan ? 8.0 : 4.0;
    final imageTextGap = isTibetan ? 16.0 : 12.0;
    final colorScheme = Theme.of(context).colorScheme;
    final hasStatsCard = ref
        .watch(routineInfoFutureProvider)
        .maybeWhen(
          data:
              (infoEither) => infoEither.fold(
                (_) => false,
                (info) => info.seriesCount > 0 || info.recitationCount > 0,
              ),
          orElse: () => false,
        );
    final allSeries = [layout.featured, ...layout.others];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FeaturedPlanSection._horizontalPadding,
        0,
        FeaturedPlanSection._horizontalPadding,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.creator_featured_plan,
            strutStyle: context.tibetanStrutStyle(
              sectionTitleSize,
              compact: true,
            ),
            style: TextStyle(
              fontSize: sectionTitleSize,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: isTibetan ? AppFontConfig.tibetanCompactLineHeight : 1.2,
              leadingDistribution:
                  isTibetan ? AppFontConfig.tibetanLeadingDistribution : null,
            ),
          ),
          SizedBox(height: sectionContentGap),
          if (hasStatsCard)
            ...allSeries.map(
              (series) => Padding(
                padding: EdgeInsets.only(bottom: itemBottomGap),
                child: _FeaturedPlanListItem(
                  series: series,
                  titleFontSize: titleFontSize,
                  dateFontSize: dateFontSize,
                  contentPadding: contentPadding,
                  titleDateGap: titleDateGap,
                  imageTextGap: imageTextGap,
                  onTap: () => onSeriesTap(series),
                ),
              ),
            )
          else ...[
            _FeaturedPlanListItem(
              series: layout.featured,
              titleFontSize: titleFontSize,
              dateFontSize: dateFontSize,
              contentPadding: contentPadding,
              titleDateGap: titleDateGap,
              imageTextGap: imageTextGap,
              onTap: () => onSeriesTap(layout.featured),
            ),
            if (layout.others.isNotEmpty) ...[
              SizedBox(height: heroOthersGap),
              ...layout.others.map(
                (series) => Padding(
                  padding: EdgeInsets.only(bottom: itemBottomGap),
                  child: _FeaturedPlanListItem(
                    series: series,
                    titleFontSize: titleFontSize,
                    dateFontSize: dateFontSize,
                    contentPadding: contentPadding,
                    titleDateGap: titleDateGap,
                    imageTextGap: imageTextGap,
                    onTap: () => onSeriesTap(series),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

Color _featuredPlanBackgroundColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
}

class _FeaturedPlanListItem extends StatelessWidget {
  const _FeaturedPlanListItem({
    required this.series,
    required this.titleFontSize,
    required this.dateFontSize,
    required this.contentPadding,
    required this.titleDateGap,
    required this.imageTextGap,
    required this.onTap,
  });

  final Series series;
  final double titleFontSize;
  final double dateFontSize;
  final double contentPadding;
  final double titleDateGap;
  final double imageTextGap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: _featuredPlanBackgroundColor(context),
      borderRadius: BorderRadius.circular(
        FeaturedPlanSection._imageBorderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(contentPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: ResponsiveCoverImage(
                    image: series.coverImage,
                    fallbackAsset: 'assets/images/tag_cover/cover_image.jpg',
                    fit: BoxFit.cover,
                    width: 72,
                    height: 72,
                  ),
                ),
              ),
              SizedBox(width: imageTextGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      strutStyle: context.tibetanStrutStyle(
                        titleFontSize,
                        compact: true,
                      ),
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height:
                            context.isTibetanLocale
                                ? AppFontConfig.tibetanCompactLineHeight
                                : 1.3,
                        leadingDistribution:
                            context.isTibetanLocale
                                ? AppFontConfig.tibetanLeadingDistribution
                                : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (series.partner != null) ...[
                      SizedBox(height: titleDateGap),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SeriesPlanPartnerRow(
                              partner: series.partner!,
                              fontSize: dateFontSize,
                            ),
                          ),
                          if (series.enrolledCount > 0) ...[
                            const SizedBox(width: 12),
                            SeriesPlanEnrolledCount(
                              count: series.enrolledCount,
                              fontSize: dateFontSize,
                            ),
                          ],
                        ],
                      ),
                    ] else if (series.enrolledCount > 0) ...[
                      SizedBox(height: titleDateGap),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SeriesPlanEnrolledCount(
                          count: series.enrolledCount,
                          fontSize: dateFontSize,
                        ),
                      ),
                    ],
                    if (SeriesPlanProgressBar.hasProgress(series)) ...[
                      SizedBox(height: titleDateGap + 4),
                      SeriesPlanProgressBar(progress: series.progress!),
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
}
