import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plans_local_datasource.dart';
import 'package:flutter_pecha/features/plans/domain/repositories/plans_repository.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/plan.dart';
import 'use_case_providers.dart';
import 'plan_search_provider.dart';
import 'find_plans_paginated_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/utils/plan_analytics.dart';

final _logger = AppLogger('PlansProviders');

// Each refresh written to Hive re-emits here.
Stream<Either<Failure, List<Plan>>> _plansUpdates(
  PlansRepository repository,
  PlansLocalDatasource local,
  String languageCode,
) async* {
  yield await repository.getPlans(language: languageCode);

  final key = local.plansKey(language: languageCode);
  await for (final _ in local.watchKey(key)) {
    final cached = local.readPlans(language: languageCode);
    if (cached != null) {
      yield Right(cached.map((plan) => plan.toEntity()).toList());
    }
  }
}

// Stored list (from Hive) is the first state, then each refresh.
final plansFutureProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<List<Plan>, Either<Failure, List<Plan>>>,
  Either<Failure, List<Plan>>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    final languageCode = ref.watch(contentLanguageProvider);
    final repository = ref.watch(plansDomainRepositoryProvider);
    final local = ref.watch(plansLocalDatasourceProvider);
    final stored = local
        .readPlans(language: languageCode)
        ?.map((plan) => plan.toEntity())
        .toList();
    return bind.stream(
      stored == null ? null : Right(stored),
      _plansUpdates(repository, local, languageCode),
    );
  });
});

// Stored plan is the first state, then each refresh.
final planByIdFutureProvider = AsyncNotifierProvider.family<
  ScreenCacheFamilyNotifier<Plan, Either<Failure, Plan?>, String>,
  Either<Failure, Plan?>,
  String
>(() {
  return ScreenCacheFamilyNotifier((ref, id, bind) {
    final repository = ref.watch(plansDomainRepositoryProvider);
    final stored =
        ref.watch(plansLocalDatasourceProvider).readPlanById(id)?.toEntity();
    return bind.stream(
      stored == null ? null : Right(stored),
      repository.watchPlan(id),
    );
  });
});

// Find plans with pagination provider
final findPlansPaginatedProvider =
    StateNotifierProvider<FindPlansNotifier, FindPlansState>((ref) {
      _logger.debug('🏗️ Creating FindPlansNotifier instance...');
      final getPlansUseCase = ref.watch(getPlansUseCaseProvider);
      final languageCode = ref.watch(contentLanguageProvider);
      _logger.debug('📝 Content language: $languageCode');
      final notifier = FindPlansNotifier(
        getPlansUseCase: getPlansUseCase,
        languageCode: languageCode,
        local: ref.watch(plansLocalDatasourceProvider),
      );
      _logger.debug('✅ FindPlansNotifier instance created');
      return notifier;
    });

// Plan search provider
final planSearchProvider =
    StateNotifierProvider<PlanSearchNotifier, PlanSearchState>((ref) {
      final getPlansUseCase = ref.watch(getPlansUseCaseProvider);
      final languageCode = ref.watch(contentLanguageProvider);
      return PlanSearchNotifier(
        getPlansUseCase: getPlansUseCase,
        languageCode: languageCode,
        analytics: ref.watch(planAnalyticsProvider),
      );
    });
