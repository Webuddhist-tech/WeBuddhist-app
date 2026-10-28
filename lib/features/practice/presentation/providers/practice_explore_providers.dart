import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/series_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_remote_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/practice/data/repositories/practice_explore_repository.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitations_page_response.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_datasource_provider.dart';
import 'package:flutter_pecha/features/timer/data/datasource/timers_remote_datasource.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

export 'package:flutter_pecha/features/practice/data/repositories/practice_explore_repository.dart'
    show practiceExploreRecitationsPreviewLimit;

final practiceExploreRepositoryProvider = Provider<PracticeExploreRepository>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return PracticeExploreRepository(
    store: ref.watch(screenCacheStoreProvider),
    seriesRemote: SeriesRemoteDatasource(dio: dio),
    recitationsRemote: ref.watch(recitationsRemoteDatasourceProvider),
    malaRemote: MalaRemoteDataSource(dio: dio),
    timersRemote: TimersRemoteDatasource(dio: dio),
  );
});

// Stored sections are the first state; pull-to-refresh goes through the
// repository.
final practiceExploreSeriesProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<List<Series>, Either<Failure, List<Series>>>,
  Either<Failure, List<Series>>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final language = ref.watch(contentLanguageProvider);
    return bind.source(
      ref.watch(practiceExploreRepositoryProvider).seriesSource(language),
    );
  });
});

final practiceExploreRecitationsProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<
    RecitationsPageResponse,
    Either<Failure, RecitationsPageResponse>
  >,
  Either<Failure, RecitationsPageResponse>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final language = ref.watch(contentLanguageProvider);
    return bind.source(
      ref.watch(practiceExploreRepositoryProvider).recitationsSource(language),
    );
  });
});

final practiceExploreAccumulatorsProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<List<Mantra>, Either<Failure, List<Mantra>>>,
  Either<Failure, List<Mantra>>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final language = ref.watch(contentLanguageProvider);
    return bind.source(
      ref.watch(practiceExploreRepositoryProvider).accumulatorsSource(language),
    );
  });
});

final practiceExploreTimersProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<List<PresetTimer>, Either<Failure, List<PresetTimer>>>,
  Either<Failure, List<PresetTimer>>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    return bind.source(
      ref.watch(practiceExploreRepositoryProvider).timersSource(),
    );
  });
});
