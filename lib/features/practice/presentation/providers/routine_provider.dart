import 'dart:async';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_local_storage.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart'
    show routineLocalStorageProvider;
import 'package:flutter_pecha/features/practice/presentation/utils/practice_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('RoutineNotifier');

/// Provider for RoutineNotifier with persistent storage.
///
/// Uses RoutineLocalStorage (Hive) for persistence and
/// [NotificationSyncEngine] for notification scheduling.
final routineProvider = StateNotifierProvider<RoutineNotifier, RoutineData>((ref) {
  final localStorage = ref.watch(routineLocalStorageProvider);
  final analytics = ref.watch(practiceAnalyticsProvider);
  return RoutineNotifier(
    localStorage: localStorage,
    syncEngine: () => ref.read(notificationSyncEngineProvider),
    analytics: analytics,
  );
});

class RoutineNotifier extends StateNotifier<RoutineData> {
  final RoutineLocalStorage _localStorage;
  final NotificationSyncEngine Function() _syncEngine;
  final PracticeAnalytics _analytics;

  RoutineNotifier({
    required RoutineLocalStorage localStorage,
    required NotificationSyncEngine Function() syncEngine,
    required PracticeAnalytics analytics,
  })  : _localStorage = localStorage,
        _syncEngine = syncEngine,
        _analytics = analytics,
        super(const RoutineData()) {
    _loadRoutines();
  }

  final Completer<void> _loadCompleter = Completer<void>();

  /// Completes once `_loadRoutines` has finished (success or failure). Callers
  /// that need to read [state.blocks] meaningfully at startup — e.g. the
  /// notification bootstrap deciding whether to clear stale plan metadata —
  /// should `await` this first.
  Future<void> get whenLoaded => _loadCompleter.future;

  bool _loadFailed = false;

  /// True when the last Hive load threw — [state.blocks] is then an empty
  /// placeholder, NOT the user's real routine. The notification engine must
  /// treat this as "routine unknown" and skip reconciliation; otherwise an
  /// empty desired set would cancel every valid scheduled notification.
  bool get loadFailed => _loadFailed;

  /// Load routines from local storage (Hive) and re-sync notifications.
  /// Re-syncing on startup ensures alarms are registered even after app
  /// updates or edge cases where AlarmManager entries were cleared.
  Future<void> _loadRoutines() async {
    try {
      final data = await _localStorage.loadRoutine();
      _loadFailed = false;
      if (mounted) {
        state = data;
        _logger.info('[ROUTINE-LOAD] Loaded ${data.blocks.length} blocks from storage');
        if (data.blocks.isNotEmpty) {
          _logger.info('[ROUTINE-LOAD] Re-syncing ${data.blocks.length} notifications on startup...');
          final report =
              await _syncEngine().sync(trigger: SyncTrigger.coldStart);
          _logger.info('[ROUTINE-LOAD] Startup sync done: $report');
        }
      }
    } catch (e) {
      _logger.error('[ROUTINE-LOAD] Failed to load routines', e);
      _loadFailed = true;
      if (mounted) {
        state = const RoutineData();
      }
    } finally {
      if (!_loadCompleter.isCompleted) {
        _loadCompleter.complete();
      }
    }
  }

  /// Save routine blocks to persistent storage and sync notifications.
  ///
  /// Convenience for non-latency-sensitive callers (e.g. background enrolment,
  /// reorder ops). Latency-sensitive UI flows (e.g. Edit Routine → "Done")
  /// should call [saveRoutineLocalOnly] and run [syncNotifications]
  /// unawaited so the slow notification reschedule never blocks navigation.
  Future<void> saveRoutine(List<RoutineBlock> blocks) async {
    await saveRoutineLocalOnly(blocks);
    await syncNotifications(blocks);
  }

  /// Persists [blocks] to Hive and updates in-memory state. Fast (~ms).
  ///
  /// Does NOT touch OS notifications — see [syncNotifications]. Splitting
  /// these lets the UI navigate away the moment local state is durable,
  /// while the (slow) platform-channel notification work continues in the
  /// background.
  Future<void> saveRoutineLocalOnly(List<RoutineBlock> blocks) async {
    final data = RoutineData(blocks: blocks).sortedByTime;
    _logger.info('[ROUTINE-SAVE] persisting ${data.blocks.length} blocks (local only)');
    try {
      await _localStorage.saveRoutine(data);
      // A successful save makes in-memory state authoritative again even if
      // the initial load had failed.
      _loadFailed = false;
      if (mounted) {
        state = data;
      }
      _analytics.routineSaved(data);
    } catch (e) {
      _logger.error('[ROUTINE-SAVE] local persist failed', e);
      rethrow;
    }
  }

  /// Reschedules OS notifications to match the current routine.
  ///
  /// The `blocks` argument is accepted for backwards-compatibility with
  /// existing callers (e.g. [`EditRoutineScreen._saveAndPop`]); the engine
  /// reads routine state from [routineProvider] internally, so the argument
  /// is intentionally unused — the caller's earlier `saveRoutineLocalOnly`
  /// call has already written the new state.
  Future<void> syncNotifications(List<RoutineBlock> blocks) async {
    _logger.info('[ROUTINE-SAVE] delegating to NotificationSyncEngine');
    final report = await _syncEngine().sync(trigger: SyncTrigger.routineSaved);
    _logger.info('[ROUTINE-SAVE] sync done: $report');
  }

  /// Mirrors the server-truth routine into local storage and in-memory state.
  ///
  /// Called after login so a fresh install or a new device restores the
  /// user's notification schedule without requiring a visit to the Practice
  /// tab (the engine reads the LOCAL routine — before this hydration a fresh
  /// install had zero local blocks and silently scheduled nothing). Server
  /// truth wins: every routine edit is pushed to the API at save time, so
  /// overwriting local state here cannot lose edits.
  Future<void> hydrateFromServer(RoutineData data) async {
    final sorted = data.sortedByTime;
    _logger.info(
      '[ROUTINE-HYDRATE] mirroring server routine (${sorted.blocks.length} blocks) into local storage',
    );
    await _localStorage.saveRoutine(sorted);
    _loadFailed = false;
    if (mounted) {
      state = sorted;
    }
  }

  /// Clear all routine data from storage and cancel notifications.
  Future<void> clearRoutine() async {
    try {
      // 1. Clear from Hive storage so the engine sees empty routine.
      await _localStorage.clearRoutine();
      _logger.info('Cleared all routine data from storage');

      // 2. Update in-memory state.
      if (mounted) {
        state = const RoutineData();
      }

      // 3. Run reconciliation — pending IDs go away because the desired set
      //    is now empty.
      await _syncEngine().sync(trigger: SyncTrigger.routineSaved);
    } catch (e) {
      _logger.error('Failed to clear routine', e);
      rethrow;
    }
  }

  /// Reorder items within a specific block and persist.
  Future<void> reorderItemsInBlock(
    String blockId,
    int oldIndex,
    int newIndex,
  ) async {
    final blocks = state.blocks.map((block) {
      if (block.id != blockId) return block;
      final items = List<RoutineItem>.from(block.items);
      final item = items.removeAt(oldIndex);
      final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      items.insert(adjustedIndex, item);
      return block.copyWith(items: items);
    }).toList();
    await saveRoutine(blocks);
  }

  /// Refresh routine data from storage.
  Future<void> refresh() async {
    await _loadRoutines();
  }
}
