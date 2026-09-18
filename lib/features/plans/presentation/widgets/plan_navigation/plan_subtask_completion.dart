import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/user_plans_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('PlanSubtaskCompletion');

/// Container-scoped handler for plan subtask completion.
///
/// Plan task screens navigate via `pushReplacement`, which disposes the
/// current screen — and its `WidgetRef` — the instant the next task is
/// pushed. A completion POST fired from such a screen therefore outlives
/// the `ref` that started it, so the screen cannot reliably refresh the
/// plan-day providers once the API confirms.
///
/// This service holds the container's [Ref] (alive for the app's lifetime),
/// so the plan-day invalidation runs exactly when the POST completes —
/// regardless of which screen, if any, is still on the stack. No timers,
/// no racing the network.
class PlanSubtaskCompletionService {
  PlanSubtaskCompletionService(this._ref);

  final Ref _ref;

  /// Subtask IDs already completed (or in flight) this session.
  ///
  /// A [NavigationContext] snapshots each item's `isCompleted` flag once, on
  /// entry — it never reflects completions made while swiping. Without this
  /// set, swiping back over an already-finished subtask would re-fire the
  /// completion POST, which the backend rejects with 409.
  final Set<String> _completedSubtaskIds = {};

  /// Completes the current subtask in [navContext], then refreshes the
  /// plan-day providers once the API confirms success.
  ///
  /// Awaitable: finish actions await it so the refresh is in flight before
  /// they pop. Mid-sequence navigation calls it fire-and-forget — the
  /// refresh still lands, since this service's `ref` is container-scoped.
  ///
  /// No-ops when [navContext] is not a plan, the item has no `subtaskId`
  /// (preview mode), or the subtask is already completed.
  Future<void> completeCurrent(NavigationContext? navContext) async {
    if (navContext == null || navContext.source != NavigationSource.plan) {
      return;
    }

    final currentItem = navContext.currentItem;
    if (currentItem == null || currentItem.isCompleted) return;

    // A combined inline item completes every subtask it shows.
    final completedBlocks = {
      for (final b in currentItem.blocks)
        if (b.isCompleted && b.subtaskId != null) b.subtaskId!,
    };
    final pending =
        currentItem.subtaskIds
            .where((id) => !completedBlocks.contains(id))
            .where((id) => !_completedSubtaskIds.contains(id))
            .toList();
    if (pending.isEmpty) return;

    // Claim them up front so a concurrent or repeat swipe can't re-POST.
    _completedSubtaskIds.addAll(pending);

    final results = await Future.wait(pending.map(_complete));
    if (results.any((ok) => ok)) {
      _refreshPlanDay(navContext.planId, navContext.dayNumber);
    }
  }

  Future<bool> _complete(String subtaskId) async {
    try {
      final useCase = _ref.read(completeSubTaskUseCaseProvider);
      final result = await useCase(
        CompleteSubTaskParams(subTaskId: subtaskId),
      );
      return result.fold(
        (failure) {
          _logger.error('Failed to complete subtask: ${failure.message}');
          _completedSubtaskIds.remove(subtaskId); // allow a later retry
          return false;
        },
        (_) {
          _logger.info('Marked subtask $subtaskId as complete');
          return true;
        },
      );
    } catch (e) {
      _logger.error('Failed to complete subtask $subtaskId', e);
      _completedSubtaskIds.remove(subtaskId); // allow a later retry
      return false;
    }
  }

  /// Invalidates the plan-day providers so the plan detail UI re-fetches.
  /// Runs only after the completion POST has succeeded, so the re-fetch
  /// reads the updated backend state rather than racing it.
  void _refreshPlanDay(String? planId, int? dayNumber) {
    if (planId == null || dayNumber == null) return;
    _ref.invalidate(
      userPlanDayContentFutureProvider(
        PlanDaysParams(planId: planId, dayNumber: dayNumber),
      ),
    );
    _ref.invalidate(userPlanDaysCompletionStatusProvider(planId));
  }
}

final planSubtaskCompletionProvider = Provider<PlanSubtaskCompletionService>(
  (ref) => PlanSubtaskCompletionService(ref),
);
