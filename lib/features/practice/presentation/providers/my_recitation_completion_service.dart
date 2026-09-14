import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/my_recitation_collections_providers.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('MyRecitationCompletion');

/// Service for handling user-created recitation collection chant completion.
/// When you open a text from “My Recitation Collection” and swipe through items,
/// it marks each chant as completed on the backend.
/// It is container-scoped so completion requests kicked off during reader
/// swipes can finish even as route replacement disposes the current screen.
class MyRecitationCompletionService {
  MyRecitationCompletionService(this._ref);

  final Ref _ref;

  /// Chant IDs already completed (or in flight) *today*.
  ///
  /// A [NavigationContext] snapshots each item's `isCompleted` flag once, on
  /// entry, so without this set a swipe back over a finished chant would
  /// re-fire the POST. Completion is a daily fact, so the set is scoped to
  /// [_completedOn] and cleared when the local date rolls over — otherwise an
  /// app left resident past midnight would skip the next day's completions.
  final Set<String> _completedChantIds = {};
  DateTime? _completedOn;

  Future<void> completeCurrent(NavigationContext? navContext) async {
    if (navContext == null ||
        navContext.source != NavigationSource.myRecitationCollection) {
      return;
    }

    final currentItem = navContext.currentItem;
    if (currentItem == null) return;

    final chantId = currentItem.subtaskId;
    if (chantId == null || chantId.isEmpty) return;
    if (currentItem.isCompleted) return;

    _resetIfDayChanged();
    if (_completedChantIds.contains(chantId)) return;

    final collectionId = navContext.collectionId;
    if (collectionId == null || collectionId.isEmpty) return;

    _completedChantIds.add(chantId);

    try {
      final result = await _ref
          .read(myRecitationCollectionCompletionProvider(collectionId).notifier)
          .completeChant(chantId);

      switch (result) {
        case MyChantCompletionResult.completed:
          _logger.info('Marked chant $chantId as complete');
          break;
        case MyChantCompletionResult.failed:
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

final myRecitationCompletionProvider = Provider<MyRecitationCompletionService>(
  (ref) => MyRecitationCompletionService(ref),
);
