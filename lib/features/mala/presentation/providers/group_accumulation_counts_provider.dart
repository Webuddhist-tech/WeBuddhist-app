import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/domain/usecases/mala_usecases.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local group user session counts keyed by [AccumulatorGroup.groupAccumulatorId].
///
/// Persisted in Hive per `(userId, groupAccumulatorId)` with `total` /
/// `syncedTotal` dirty tracking. Seeded from group_profile's
/// `GET /group-accumulators/{id}` (`user.totalCount`). Background sync via
/// [MalaSyncManager] (`POST` with `current_count`).
class GroupAccumulationCountsNotifier extends StateNotifier<Map<String, int>> {
  GroupAccumulationCountsNotifier({
    required Ref ref,
    required String presetId,
    required MalaLocalDataSource local,
    required MalaSyncManager sync,
    required DeleteGroupAccumulatorUseCase deleteGroupAccumulator,
    required Future<String?> Function() currentUserId,
  })  : _ref = ref,
        _presetId = presetId,
        _local = local,
        _sync = sync,
        _deleteGroupAccumulator = deleteGroupAccumulator,
        _currentUserId = currentUserId,
        super(const {}) {
    _sync.onGroupCountSynced = handleGroupCountSynced;
    unawaited(_init());
  }

  final Ref _ref;
  final String _presetId;
  final MalaLocalDataSource _local;
  final MalaSyncManager _sync;
  final DeleteGroupAccumulatorUseCase _deleteGroupAccumulator;
  final Future<String?> Function() _currentUserId;

  String? _userId;
  bool _isResetting = false;
  /// Groups recently reset via [resetCount]; ignore stale server totals until
  /// GET confirms 0.
  final Set<String> _postResetGroupIds = {};

  bool get isResetting => _isResetting;

  Future<void> _init() async {
    _userId = await _currentUserId();
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;

    final ids = _local.groupAccumulatorIdsForUser(userId);
    if (ids.isEmpty) return;

    final next = Map<String, int>.from(state);
    for (final id in ids) {
      next[id] = _local.readGroup(userId, id).total;
    }
    state = next;
  }

  /// Reconcile group_profile detail user totals with local Hive state
  /// (`max()` on both sides).
  Future<void> mergeFromServerCounts(Map<String, int> serverCounts) async {
    if (serverCounts.isEmpty) return;

    var userId = _userId;
    userId ??= await _currentUserId();
    if (userId == null || userId.isEmpty) return;
    _userId = userId;

    final next = Map<String, int>.from(state);
    var changed = false;
    var hasDirtyTail = false;

    for (final entry in serverCounts.entries) {
      final id = entry.key;
      var serverTotal = entry.value;

      if (_postResetGroupIds.contains(id)) {
        if (serverTotal == 0) {
          _postResetGroupIds.remove(id);
        } else {
          // Stale detail response after DELETE — keep the local zero session.
          serverTotal = 0;
        }
      }

      final localState = _local.readGroup(userId, id);
      final LocalGroupMalaState reconciled;
      if (localState.isDirty) {
        final total = max(localState.total, serverTotal);
        reconciled = localState.copyWith(
          total: total,
          syncedTotal: max(localState.syncedTotal, serverTotal),
        );
      } else {
        // Clean local: mirror server exactly (seed, post-sync, post-reset).
        reconciled = LocalGroupMalaState(
          total: serverTotal,
          syncedTotal: serverTotal,
        );
      }

      if (reconciled.total != localState.total ||
          reconciled.syncedTotal != localState.syncedTotal) {
        await _local.writeGroup(userId, id, reconciled);
      }
      if (next[id] != reconciled.total) {
        next[id] = reconciled.total;
        changed = true;
      }
      if (reconciled.isDirty) hasDirtyTail = true;
    }

    if (changed) state = next;
    if (hasDirtyTail) unawaited(_sync.flush(SyncReason.launch));
  }

  int countFor(String groupAccumulatorId, [List<AccumulatorGroup>? groups]) {
    final fromState = state[groupAccumulatorId];
    if (fromState != null) return fromState;

    final userId = _userId;
    if (userId != null) {
      return _local.readGroup(userId, groupAccumulatorId).total;
    }
    return 0;
  }

  /// Lifetime total for [GroupAccumulationsSheet]: API baseline plus any taps
  /// not yet reflected in `user_total_count`.
  int displayLifetimeCount(String groupAccumulatorId, int lifetimeFromApi) {
    final userId = _userId;
    if (userId == null) return lifetimeFromApi;

    final local = _local.readGroup(userId, groupAccumulatorId);
    final dirty = local.total - local.syncedTotal;
    if (dirty <= 0) return lifetimeFromApi;
    return lifetimeFromApi + dirty;
  }

  void handleGroupCountSynced(String groupAccumulatorId) {
    _ref.invalidate(joinedAccumulatorGroupsProvider(_presetId));
  }

  /// Returns the new total, or null when the tap was ignored.
  int? increment({
    required String groupAccumulatorId,
    required List<AccumulatorGroup> groups,
    required bool soundEnabled,
    required bool vibrationEnabled,
    required int beadsPerRound,
  }) {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return null;

    _postResetGroupIds.remove(groupAccumulatorId);
    final current = countFor(groupAccumulatorId, groups);
    final newTotal = current + 1;
    state = {...state, groupAccumulatorId: newTotal};
    unawaited(_local.recordGroupTap(userId, groupAccumulatorId));

    final roundComplete = newTotal % beadsPerRound == 0;
    if (soundEnabled) {
      _ref.read(malaSoundPlayerProvider).play();
    }
    if (vibrationEnabled) {
      HapticFeedback.lightImpact();
      if (roundComplete) HapticFeedback.mediumImpact();
    }

    _sync.onTap(roundComplete: roundComplete);
    return newTotal;
  }

  /// Returns false when the add was ignored.
  bool addRounds({
    required String groupAccumulatorId,
    required List<AccumulatorGroup> groups,
    required int rounds,
    required int beadsPerRound,
  }) {
    if (rounds <= 0) return false;

    final userId = _userId;
    if (userId == null || userId.isEmpty) return false;

    _postResetGroupIds.remove(groupAccumulatorId);
    final current = countFor(groupAccumulatorId, groups);
    final delta = rounds * beadsPerRound;
    final newTotal = current + delta;
    state = {...state, groupAccumulatorId: newTotal};
    unawaited(_local.addGroupToTotal(userId, groupAccumulatorId, delta));
    _sync.onTap(roundComplete: true);
    return true;
  }

  /// Adds [count] offline recitations on top of the current session total.
  void addCount({
    required String groupAccumulatorId,
    required List<AccumulatorGroup> groups,
    required int count,
  }) {
    if (count <= 0) return;

    final userId = _userId;
    if (userId == null || userId.isEmpty) return;

    _postResetGroupIds.remove(groupAccumulatorId);
    final current = countFor(groupAccumulatorId, groups);
    final newTotal = current + count;
    state = {...state, groupAccumulatorId: newTotal};
    unawaited(_local.addGroupToTotal(userId, groupAccumulatorId, count));
    _sync.onTap(roundComplete: true);
  }

  /// Clears in-memory count after a successful reset DELETE. Hive is cleared
  /// separately by [MalaSyncManager.resetGroupAccumulator].
  void _markLocalCountResetAfterDelete(String groupAccumulatorId) {
    _postResetGroupIds.add(groupAccumulatorId);
    state = {...state, groupAccumulatorId: 0};
  }

  /// Resets the user's group count to zero by soft-deleting on the server
  /// (`DELETE /group-accumulators/{id}`). Unsynced taps are flushed first.
  /// Returns false on failure.
  Future<bool> resetCount({required String groupAccumulatorId}) async {
    if (_isResetting) return false;

    final userId = _userId ?? await _currentUserId();
    if (userId == null || userId.isEmpty) return false;
    _userId = userId;

    _isResetting = true;
    try {
      await _sync.resetGroupAccumulator(
        groupAccumulatorId,
        deleteGroupAccumulator: _deleteGroupAccumulator,
      );
      if (!mounted) return false;
      _markLocalCountResetAfterDelete(groupAccumulatorId);
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) _isResetting = false;
    }
  }
}

final groupAccumulationCountsProvider = StateNotifierProvider.autoDispose
    .family<GroupAccumulationCountsNotifier, Map<String, int>, String>(
  (ref, presetId) {
    final sync = ref.watch(malaSyncManagerProvider);
    final notifier = GroupAccumulationCountsNotifier(
      ref: ref,
      presetId: presetId,
      local: ref.watch(malaLocalDataSourceProvider),
      sync: sync,
      deleteGroupAccumulator: ref.watch(deleteGroupAccumulatorUseCaseProvider),
      currentUserId: () => resolveMalaUserId(ref),
    );
    ref.onDispose(() {
      if (sync.onGroupCountSynced == notifier.handleGroupCountSynced) {
        sync.onGroupCountSynced = null;
      }
    });
    return notifier;
  },
);
