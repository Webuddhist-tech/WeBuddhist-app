import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stored plan days are the first state, then each refresh.
final planDaysByPlanIdFutureProvider = AsyncNotifierProvider.family<
  ScreenCacheFamilyNotifier<
    List<PlanDaysModel>,
    Either<Failure, List<PlanDaysModel>>,
    String
  >,
  Either<Failure, List<PlanDaysModel>>,
  String
>(() {
  return ScreenCacheFamilyNotifier((ref, planId, bind) {
    final repository = ref.watch(planDaysDomainRepositoryProvider);
    final stored = ref.watch(plansLocalDatasourceProvider).readPlanDays(planId);
    return bind.stream(
      stored == null ? null : Right(stored),
      repository.watchPlanDaysByPlanId(planId),
    );
  });
});

// Plan days params
class PlanDaysParams {
  final String planId;
  final int dayNumber;
  const PlanDaysParams({required this.planId, required this.dayNumber});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanDaysParams &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          dayNumber == other.dayNumber;

  @override
  int get hashCode => planId.hashCode ^ dayNumber.hashCode;
}

// Stored day content is the first state, then each refresh.
final planDayContentFutureProvider = AsyncNotifierProvider.family<
  ScreenCacheFamilyNotifier<
    PlanDaysModel,
    Either<Failure, PlanDaysModel>,
    PlanDaysParams
  >,
  Either<Failure, PlanDaysModel>,
  PlanDaysParams
>(() {
  return ScreenCacheFamilyNotifier((ref, params, bind) {
    final repository = ref.watch(planDaysDomainRepositoryProvider);
    final stored = ref
        .watch(plansLocalDatasourceProvider)
        .readPlanDayContent(params.planId, params.dayNumber);
    return bind.stream(
      stored == null ? null : Right(stored),
      repository.watchDayContent(params.planId, params.dayNumber),
    );
  });
});
