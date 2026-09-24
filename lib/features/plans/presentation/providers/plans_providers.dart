import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/plan.dart';
import 'use_case_providers.dart';
import 'plan_search_provider.dart';
import 'find_plans_paginated_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/utils/plan_analytics.dart';

final _logger = AppLogger('PlansProviders');

// Get all plans provider — local-first via repository cache + Hive watch.
final plansFutureProvider = StreamProvider<Either<Failure, List<Plan>>>((ref) async* {
  final languageCode = ref.watch(contentLanguageProvider);
  final repository = ref.watch(plansDomainRepositoryProvider);
  final local = ref.watch(plansLocalDatasourceProvider);
  final key = local.plansKey(language: languageCode);

  yield await repository.getPlans(language: languageCode);

  await for (final _ in local.watchKey(key)) {
    final cached = local.readPlans(language: languageCode);
    if (cached != null) {
      yield Right(cached.map((plan) => plan.toEntity()).toList());
    }
  }
});

final planByIdFutureProvider = StreamProvider.family<Either<Failure, Plan?>, String>((
  ref,
  id,
) {
  final repository = ref.watch(plansDomainRepositoryProvider);
  return repository.watchPlan(id);
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
