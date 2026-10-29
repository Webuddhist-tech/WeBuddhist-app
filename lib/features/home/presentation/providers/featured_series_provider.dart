import 'dart:math';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class FeaturedSeriesLayout {
  const FeaturedSeriesLayout({required this.featured, required this.others});

  final Series featured;
  final List<Series> others;
}

const homeFeaturedSeriesLimit = 10;
const _featuredSeriesLimit = homeFeaturedSeriesLimit;

/// Picks one random series as the hero card so no single series is favored.
FeaturedSeriesLayout? _layout(List<Series> seriesList) {
  if (seriesList.isEmpty) return null;
  final featuredIndex = Random().nextInt(seriesList.length);
  final featured = seriesList[featuredIndex];
  final others = [
    for (var i = 0; i < seriesList.length; i++)
      if (i != featuredIndex) seriesList[i],
  ];
  return FeaturedSeriesLayout(featured: featured, others: others);
}

/// Stored series are the first state; re-fetches when the language changes.
final featuredSeriesFutureProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<List<Series>, Either<Failure, FeaturedSeriesLayout?>>,
  Either<Failure, FeaturedSeriesLayout?>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final language = ref.watch(contentLanguageProvider);
    final repository = ref.watch(seriesDomainRepositoryProvider);
    final stored = ref
        .watch(homeLocalDatasourceProvider)
        .readFeaturedSeries(language, _featuredSeriesLimit)
        ?.map((m) => m.toEntity(language: language))
        .toList();
    return bind.stream(
      stored == null ? null : Right(_layout(stored)),
      repository
          .watchFeaturedSeries(language: language, limit: _featuredSeriesLimit)
          .map((result) => result.map(_layout)),
    );
  });
});
