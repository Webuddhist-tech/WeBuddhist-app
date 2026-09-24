import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_explore_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/all_plans_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_plan_card.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_container.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PracticePlansSection extends ConsumerWidget {
  const PracticePlansSection({super.key});

  static const _previewCount = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final seriesAsync = ref.watch(practiceExploreSeriesProvider);

    return seriesAsync.when(
      data:
          (either) => either.fold((_) => const SizedBox.shrink(), (seriesList) {
            if (seriesList.isEmpty) return const SizedBox.shrink();
            final preview = seriesList.take(_previewCount).toList();
            return PracticeSectionContainer(
              title: l10n.home_shortcut_plans,
              seeAllLabel:
                  seriesList.length >= _previewCount ? l10n.see_all : null,
              onSeeAll:
                  seriesList.length >= _previewCount
                      ? () => _showAllPlans(context, seriesList)
                      : null,
              child: SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: preview.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final series = preview[index];
                    return PracticePlanCard(
                      series: series,
                      onTap: () => _navigateToSeries(context, series),
                    );
                  },
                ),
              ),
            );
          }),
      loading:
          () => const PracticeSectionSkeleton(
            height: 240,
            axis: Axis.horizontal,
            itemCount: 2,
            itemWidth: 300,
            cardBorderRadius: 12,
          ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _navigateToSeries(BuildContext context, Series series) {
    context.pushNamed(
      'home-series-detail',
      pathParameters: {'id': series.id},
    );
  }

  void _showAllPlans(BuildContext context, List<Series> seriesList) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'all-plans'),
        builder:
            (_) => AllPlansScreen(
              seriesList: seriesList,
              onTap: (series) => _navigateToSeries(context, series),
            ),
      ),
    );
  }
}
