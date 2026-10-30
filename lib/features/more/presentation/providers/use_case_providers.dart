import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/more/data/datasource/user_stats_local_datasource.dart';
import 'package:flutter_pecha/features/more/data/datasource/user_stats_remote_datasource.dart';
import 'package:flutter_pecha/features/more/data/repositories/user_stats_repository_impl.dart';
import 'package:flutter_pecha/features/more/domain/repositories/user_stats_repository.dart';
import 'package:flutter_pecha/features/more/domain/usecases/get_mantra_counts_usecase.dart';
import 'package:flutter_pecha/features/more/domain/usecases/get_series_day_completed_usecase.dart';
import 'package:flutter_pecha/features/more/domain/usecases/get_user_stats_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userStatsRemoteDatasourceProvider = Provider<UserStatsRemoteDatasource>((
  ref,
) {
  return UserStatsRemoteDatasource(dio: ref.watch(dioProvider));
});

final userStatsLocalDatasourceProvider = Provider<UserStatsLocalDatasource>((
  ref,
) {
  return UserStatsLocalDatasource();
});

final userStatsRepositoryProvider = Provider<UserStatsRepositoryInterface>((
  ref,
) {
  return UserStatsRepositoryImpl(
    remote: ref.watch(userStatsRemoteDatasourceProvider),
    local: ref.watch(userStatsLocalDatasourceProvider),
    store: ref.watch(screenCacheStoreProvider),
  );
});

final getUserStatsUseCaseProvider = Provider<GetUserStatsUseCase>((ref) {
  final repository = ref.watch(userStatsRepositoryProvider);
  return GetUserStatsUseCase(repository.getUserStats);
});

final getSeriesDayCompletedUseCaseProvider =
    Provider<GetSeriesDayCompletedUseCase>((ref) {
      final repository = ref.watch(userStatsRepositoryProvider);
      return GetSeriesDayCompletedUseCase(repository.getSeriesDayCompleted);
    });

final getMantraCountsUseCaseProvider = Provider<GetMantraCountsUseCase>((ref) {
  final repository = ref.watch(userStatsRepositoryProvider);
  return GetMantraCountsUseCase(repository.getMantraCounts);
});
