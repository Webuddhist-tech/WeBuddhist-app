import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/user_plans_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/my_plans_paginated_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _notAuthenticated = Left<Failure, Never>(
  AuthenticationFailure('Not authenticated'),
);

bool _signedOut(Ref ref) {
  final auth = ref.watch(authProvider);
  return auth.isLoading || !auth.isLoggedIn || auth.isGuest;
}

// Stored list is the first state for the signed-in user.
final userPlansFutureProvider = AsyncNotifierProvider<
  ScreenCacheNotifier<
    UserPlanListResponseModel,
    Either<Failure, UserPlanListResponseModel>
  >,
  Either<Failure, UserPlanListResponseModel>
>(() {
  return ScreenCacheNotifier((ref, bind) {
    if (_signedOut(ref)) return _notAuthenticated;

    final languageCode = ref.watch(contentLanguageProvider);
    final repository = ref.watch(userPlansDomainRepositoryProvider);
    final local = ref.watch(plansLocalDatasourceProvider);
    final userId = local.currentUserIdSync;
    final stored =
        userId == null
            ? null
            : local.readUserPlans(userId: userId, language: languageCode);
    return bind.stream(
      stored == null ? null : Right(stored),
      repository.watchUserPlans(language: languageCode),
    );
  });
});

final userPlanProgressDetailsFutureProvider = AsyncNotifierProvider.autoDispose
    .family<
      AutoDisposeScreenCacheFamilyNotifier<
        List<PlanProgressModel>,
        Either<Failure, List<PlanProgressModel>>,
        String
      >,
      Either<Failure, List<PlanProgressModel>>,
      String
    >(() {
      return AutoDisposeScreenCacheFamilyNotifier((ref, planId, bind) {
        if (_signedOut(ref)) return _notAuthenticated;

        final repository = ref.watch(userPlansDomainRepositoryProvider);
        final local = ref.watch(plansLocalDatasourceProvider);
        final userId = local.currentUserIdSync;
        final stored =
            userId == null ? null : local.readPlanProgress(userId, planId);
        return bind.stream(
          stored == null ? null : Right(stored),
          repository.watchUserPlanProgressDetails(planId),
        );
      });
    });

final userPlanSubscribeFutureProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, String>((ref, planId) {
      final useCase = ref.watch(subscribeToPlanUseCaseProvider);
      return useCase(SubscribeToPlanParams(planId: planId));
    });

final userPlanUnsubscribeFutureProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, String>((ref, planId) {
      final useCase = ref.watch(unsubscribeFromPlanUseCaseProvider);
      return useCase(UnsubscribeFromPlanParams(planId: planId));
    });

final completeTaskFutureProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, String>((ref, taskId) {
      final useCase = ref.watch(completeTaskUseCaseProvider);
      return useCase(CompleteTaskParams(taskId: taskId));
    });

final deleteTaskFutureProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, String>((ref, taskId) {
      final useCase = ref.watch(deleteTaskUseCaseProvider);
      return useCase(DeleteTaskParams(taskId: taskId));
    });

final completeSubTaskFutureProvider = FutureProvider.autoDispose
    .family<Either<Failure, bool>, String>((ref, subTaskId) {
      final useCase = ref.watch(completeSubTaskUseCaseProvider);
      return useCase(CompleteSubTaskParams(subTaskId: subTaskId));
    });

// My plans with pagination provider
final myPlansPaginatedProvider =
    StateNotifierProvider<MyPlansNotifier, MyPlansState>((ref) {
      final repository = ref.watch(userPlansDomainRepositoryProvider);
      final languageCode = ref.watch(contentLanguageProvider);
      return MyPlansNotifier(
        repository: repository,
        languageCode: languageCode,
        local: ref.watch(plansLocalDatasourceProvider),
      );
    });

// Stored day content is the first state for the signed-in user.
final userPlanDayContentFutureProvider = AsyncNotifierProvider.autoDispose
    .family<
      AutoDisposeScreenCacheFamilyNotifier<
        UserPlanDayDetailResponse,
        Either<Failure, UserPlanDayDetailResponse>,
        PlanDaysParams
      >,
      Either<Failure, UserPlanDayDetailResponse>,
      PlanDaysParams
    >(() {
      return AutoDisposeScreenCacheFamilyNotifier((ref, params, bind) {
        if (_signedOut(ref)) return _notAuthenticated;

        final repository = ref.watch(userPlansDomainRepositoryProvider);
        final local = ref.watch(plansLocalDatasourceProvider);
        final userId = local.currentUserIdSync;
        final stored =
            userId == null
                ? null
                : local.readUserPlanDay(userId, params.planId, params.dayNumber);
        return bind.stream(
          stored == null ? null : Right(stored),
          repository.watchUserPlanDayContent(params.planId, params.dayNumber),
        );
      });
    });

/// Completion status for all days in a plan, keyed by day number.
final userPlanDaysCompletionStatusProvider = AsyncNotifierProvider.autoDispose
    .family<
      AutoDisposeScreenCacheFamilyNotifier<
        Map<int, bool>,
        Either<Failure, Map<int, bool>>,
        String
      >,
      Either<Failure, Map<int, bool>>,
      String
    >(() {
      return AutoDisposeScreenCacheFamilyNotifier((ref, planId, bind) {
        if (_signedOut(ref)) return _notAuthenticated;

        final repository = ref.watch(userPlansDomainRepositoryProvider);
        final local = ref.watch(plansLocalDatasourceProvider);
        final userId = local.currentUserIdSync;
        final stored =
            userId == null ? null : local.readCompletionStatus(userId, planId);
        return bind.stream(
          stored == null ? null : Right(stored),
          repository.watchPlanDaysCompletionStatus(planId),
        );
      });
    });
