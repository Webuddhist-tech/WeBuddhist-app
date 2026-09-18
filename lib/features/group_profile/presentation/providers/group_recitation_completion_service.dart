import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('GroupRecitationCompletion');

/// Service for handling group recitation chant completion.
///
/// Similar to [PlanSubtaskCompletionService], this service holds the
/// container's [Ref] (alive for the app's lifetime), so the completion
/// call runs exactly when the user swipes — regardless of which screen,
/// if any, is still on the stack.
class GroupRecitationCompletionService {
  GroupRecitationCompletionService(this._ref);

  final Ref _ref;

  /// Chant IDs already completed (or in flight) *today*.
  ///
  /// A [NavigationContext] snapshots each item's `isCompleted` flag once, on
  /// entry — it never reflects completions made while swiping. Without this
  /// set, swiping back over an already-finished chant would re-fire the
  /// completion POST, which the backend rejects. Completion is a daily fact,
  /// so the set is scoped to [_completedOn] and cleared when the local date
  /// rolls over — otherwise an app left resident past midnight would skip the
  /// next day's completions.
  final Set<String> _completedChantIds = {};
  DateTime? _completedOn;

  /// Completes the current chant in [navContext], then refreshes the
  /// completion state once the API confirms success.
  ///
  /// Awaitable: finish actions await it so the refresh is in flight before
  /// they pop. Mid-sequence navigation calls it fire-and-forget — the
  /// refresh still lands, since this service's `ref` is container-scoped.
  ///
  /// No-ops when [navContext] is not a group recitation collection, the item
  /// has no `subtaskId` (chant ID), or the chant is already completed.
  Future<void> completeCurrent(NavigationContext? navContext) async {
    if (navContext == null ||
        navContext.source != NavigationSource.groupRecitationCollection) {
      return;
    }

    final currentItem = navContext.currentItem;
    if (currentItem == null) return;

    final chantId = currentItem.subtaskId;
    if (chantId == null || chantId.isEmpty) return;
    if (currentItem.isCompleted) return;

    _resetIfDayChanged();
    if (_completedChantIds.contains(chantId)) return;

    final groupId = navContext.groupId;
    final collectionId = navContext.collectionId;
    if (groupId == null || collectionId == null) return;

    // Claim it up front so a concurrent or repeat swipe can't re-POST.
    _completedChantIds.add(chantId);

    try {
      final key = GroupRecitationCollectionKey(
        groupId: groupId,
        collectionId: collectionId,
      );
      final result = await _ref
          .read(groupRecitationCollectionCompletionProvider(key).notifier)
          .completeChant(chantId);

      switch (result) {
        case GroupChantCompletionResult.completed:
          _logger.info('Marked chant $chantId as complete');
          break;
        case GroupChantCompletionResult.membershipRequired:
          _logger.warning('Chant completion requires group membership');
          _completedChantIds.remove(chantId);
          break;
        case GroupChantCompletionResult.failed:
          _logger.error('Failed to complete chant $chantId');
          _completedChantIds.remove(chantId);
          break;
      }
    } catch (e) {
      _logger.error('Failed to complete chant $chantId', e);
      _completedChantIds.remove(chantId);
    }
  }

  /// Drops yesterday's claims so the same chant can be completed again today.
  void _resetIfDayChanged() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_completedOn != today) {
      _completedChantIds.clear();
      _completedOn = today;
    }
  }
}

final groupRecitationCompletionProvider =
    Provider<GroupRecitationCompletionService>(
  (ref) => GroupRecitationCompletionService(ref),
);
