import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

// Stored list is the first state; refetches when the app language changes.
final seriesListFutureProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<List<Series>, Either<Failure, List<Series>>>,
  Either<Failure, List<Series>>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final language = ref.watch(contentLanguageProvider);
    final repository = ref.watch(seriesDomainRepositoryProvider);
    final stored = ref
        .watch(homeLocalDatasourceProvider)
        .readSeriesList(language)
        ?.map((m) => m.toEntity(language: language))
        .toList();
    return bind.stream(
      stored == null ? null : Right(stored),
      repository.watchSeriesList(language: language),
    );
  });
});

final seriesByIdProvider = AsyncNotifierProvider.autoDispose.family<
  AutoDisposeScreenCacheFamilyNotifier<Series, Either<Failure, Series>, String>,
  Either<Failure, Series>,
  String
>(() {
  return AutoDisposeScreenCacheFamilyNotifier((ref, id, bind) {
    final language = ref.watch(contentLanguageProvider);
    final repository = ref.watch(seriesDomainRepositoryProvider);
    final stored = ref
        .watch(homeLocalDatasourceProvider)
        .readSeriesById(language, id)
        ?.toEntity(language: language);
    return bind.stream(
      stored == null ? null : Right(stored),
      repository.watchSeriesById(id, language: language),
    );
  });
});
