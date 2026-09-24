import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/user_plans_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/utils/plan_analytics.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/domain/usecases/routine_api_usecases.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coordinates event enrollment during onboarding:
///   1. Subscribe the user to the plan via `POST /users/me/plans`
///   2. Add the plan to the user's daily routine at 07:30 AM (server)
///   3. Persist the resulting routine to local Hive AND schedule device-local
///      notifications via [RoutineNotifier.saveRoutine] — exactly like
///      `edit_routine_screen` does on save. Without this step the server has
///      the time block but the device has no AlarmManager entry, so the
///      7:30 AM reminder never fires.
///   4. Return the enrolled [UserPlansModel] for post-onboarding navigation
///
/// Subscription and time-block creation are best-effort and idempotent: if
/// the user is already enrolled or a time-block conflict exists, we log and
/// continue rather than surfacing an error.
class EventEnrollmentService {
  final SubscribeToPlanUseCase _subscribeToPlanUseCase;
  final GetUserRoutineUseCase _getUserRoutineUseCase;
  final CreateRoutineWithTimeBlockUseCase _createRoutineWithTimeBlockUseCase;
  final CreateTimeBlockUseCase _createTimeBlockUseCase;
  final GetUserPlansUseCase _getUserPlansUseCase;
  final Ref _ref;

  final _logger = AppLogger('EventEnrollmentService');

  EventEnrollmentService({
    required SubscribeToPlanUseCase subscribeToPlanUseCase,
    required GetUserRoutineUseCase getUserRoutineUseCase,
    required CreateRoutineWithTimeBlockUseCase createRoutineWithTimeBlockUseCase,
    required CreateTimeBlockUseCase createTimeBlockUseCase,
    required GetUserPlansUseCase getUserPlansUseCase,
    required Ref ref,
  })  : _subscribeToPlanUseCase = subscribeToPlanUseCase,
        _getUserRoutineUseCase = getUserRoutineUseCase,
        _createRoutineWithTimeBlockUseCase = createRoutineWithTimeBlockUseCase,
        _createTimeBlockUseCase = createTimeBlockUseCase,
        _getUserPlansUseCase = getUserPlansUseCase,
        _ref = ref;

  /// Enrolls the user in all [planIds] and returns the resulting [UserPlansModel]
  /// list (those that were found in the user's plan list after enrollment).
  ///
  /// Throws a descriptive [Exception] if a critical step fails and the UI
  /// should surface an error to the user.
  Future<List<UserPlansModel>> enrollInEvents(
    List<String> planIds, {
    PlanSource source = PlanSource.onboarding,
  }) async {
    _logger.info('[SP-ENROLL] enrollInEvents START planIds=$planIds');
    for (final planId in planIds) {
      _logger.info('[SP-ENROLL] subscribing $planId');
      await _subscribeToPlan(planId, source);
      _logger.info('[SP-ENROLL] adding routine block for $planId');
      await _addToRoutine(planId);
    }

    // Fetch the user's enrolled plans to return to the caller. Plan/series
    // reminders are delivered via server push (FCM) now, so there is no local
    // plan-metadata cache to prime here.
    _logger.info('[SP-ENROLL] fetching enrolled plans');
    final enrolledPlans = await _fetchEnrolledPlans(planIds);
    _logger.info(
      '[SP-ENROLL] fetched ${enrolledPlans.length} enrolled plans: '
      '${enrolledPlans.map((p) => "${p.id}@${p.startedAt.toIso8601String()}").join(", ")}',
    );

    // Persist the final server routine to Hive, then reconcile local
    // recitation/mala/timer notifications for the newly-saved routine.
    _logger.info('[SP-ENROLL] persisting routine + scheduling notifications');
    await _persistRoutineLocallyAndScheduleNotifications();

    await _ref
        .read(notificationSyncEngineProvider)
        .sync(trigger: SyncTrigger.routineSaved);

    _logger.info('[SP-ENROLL] enrollInEvents DONE returning ${enrolledPlans.length} plans');
    return enrolledPlans;
  }

  // ─── Step 1: Subscribe ───

  Future<void> _subscribeToPlan(String planId, PlanSource source) async {
    final result = await _subscribeToPlanUseCase(
      SubscribeToPlanParams(planId: planId),
    );
    result.fold(
      (failure) {
        // Treat all subscription failures as warnings — the user may already
        // be enrolled from a previous onboarding attempt.
        _logger.warning('subscribe plan $planId: ${failure.message} (continuing)');
      },
      (success) {
        _logger.info('Subscribed to plan $planId');
        if (success) {
          _ref
              .read(planAnalyticsProvider)
              .planEnrolled(planId: planId, source: source);
        }
      },
    );
  }

  // ─── Step 2: Add to routine at 07:30 ───

  Future<void> _addToRoutine(String planId) async {
    final language = _ref.read(contentLanguageProvider);
    final routineResult = await _getUserRoutineUseCase(language: language);
    final routineData = routineResult.fold((_) => null, (data) => data);
    final routineId = routineData?.apiRoutineId;

    // Check if plan is already in routine to avoid duplicate time blocks
    if (routineData != null) {
      final alreadyInRoutine = routineData.blocks.any(
        (block) => block.items.any(
          (item) => item.representsStandalonePlan(planId),
        ),
      );
      if (alreadyInRoutine) {
        _logger.info('Plan $planId already in routine, skipping time block creation');
        return;
      }
    }

    final request = TimeBlockRequest(
      time: '07:30',
      timeInt: 730,
      notificationEnabled: true,
      sessions: [
        SessionRequest(
          sessionType: SessionType.plan,
          sourceId: planId,
          displayOrder: 0,
        ),
      ],
    );

    if (routineId != null) {
      final result = await _createTimeBlockUseCase(routineId, request);
      result.fold(
        (failure) => _logger.warning(
          'create time-block for $planId: ${failure.message} (continuing)',
        ),
        (_) => _logger.info('Time block created at 07:30 for plan $planId'),
      );
    } else {
      final result = await _createRoutineWithTimeBlockUseCase(request);
      result.fold(
        (failure) {
          // ValidationFailure here likely means routine already exists (race).
          // Not fatal — the subscription already succeeded.
          _logger.warning(
            'create routine+time-block for $planId: ${failure.message} (continuing)',
          );
        },
        (_) => _logger.info('Routine created with 07:30 block for plan $planId'),
      );
    }
  }

  // ─── Step 3: Persist routine to Hive + schedule local notifications ───

  /// Re-fetches the routine from the server (now includes the newly-added
  /// time blocks) and routes it through [RoutineNotifier.saveRoutine] which:
  ///   - persists blocks to Hive (so startup sync works on next app launch),
  ///   - delegates to `NotificationSyncEngine` which reconciles AlarmManager /
  ///     flutter_local_notifications entries against the routine.
  ///
  /// Also invalidates [userRoutineProvider] so any UI watching it refreshes.
  Future<void> _persistRoutineLocallyAndScheduleNotifications() async {
    final language = _ref.read(contentLanguageProvider);
    final routineResult = await _getUserRoutineUseCase(language: language);
    final routineData = routineResult.fold((_) => null, (data) => data);

    if (routineData == null || routineData.blocks.isEmpty) {
      _logger.warning(
        'No routine returned after enrollment — skipping local persist & notification scheduling',
      );
      return;
    }

    try {
      _logger.info(
        '[ONBOARD-SAVE] persisting ${routineData.blocks.length} blocks to Hive + scheduling notifications',
      );
      await _ref.read(routineProvider.notifier).saveRoutine(routineData.blocks);
      _ref.invalidate(userRoutineProvider);
      _logger.info('[ONBOARD-SAVE] done');
    } catch (e, st) {
      _logger.error(
        '[ONBOARD-SAVE] failed to persist routine / schedule notifications',
        e,
        st,
      );
    }
  }

  // ─── Step 4: Fetch enrolled plan models ───

  Future<List<UserPlansModel>> _fetchEnrolledPlans(List<String> planIds) async {
    final result = await _getUserPlansUseCase(
      const GetUserPlansParams(language: 'en', skip: 0, limit: 50),
    );

    return result.fold(
      (failure) {
        _logger.warning('fetch user plans after enrollment: ${failure.message}');
        // Return empty — enrollment succeeded, navigation will fall back gracefully.
        return [];
      },
      (response) => _filterEnrolledPlans(response, planIds),
    );
  }

  List<UserPlansModel> _filterEnrolledPlans(
    UserPlanListResponseModel response,
    List<String> planIds,
  ) {
    final planSet = planIds.toSet();
    return response.userPlans.where((p) => planSet.contains(p.id)).toList();
  }
}
