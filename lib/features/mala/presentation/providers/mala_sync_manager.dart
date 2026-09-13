import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/usecases/mala_usecases.dart';

enum SyncReason {
  launch,
  tap,
  roundComplete,
  debounce,
  background,
  reconnect,
  screenLeave,
  logout,
}

/// App-scoped background sync for mala counts.
///
/// Sends the **absolute lifetime total** per accumulator (defensive
/// absolute-total model): seed-before-send guarantees a stale low value is
/// never sent, and `max()` on both sides keeps the count monotonic and
/// reconciles across devices. Reads dirty entries straight from Hive, so it
/// flushes even after the user has left the mala screen.
class MalaSyncManager with WidgetsBindingObserver {
  MalaSyncManager({
    required MalaLocalDataSource local,
    required CreateUserAccumulatorUseCase createAccumulator,
    required UpdateUserAccumulatorUseCase updateAccumulator,
    required SubmitGroupAccumulatorCountUseCase submitGroupCount,
    required bool Function() isLoggedIn,
    required Future<String?> Function() currentUserId,
    Stream<bool>? connectivityStream,
    AnalyticsService? analytics,
  })  : _local = local,
        _createAccumulator = createAccumulator,
        _updateAccumulator = updateAccumulator,
        _submitGroupCount = submitGroupCount,
        _isLoggedIn = isLoggedIn,
        _currentUserId = currentUserId,
        _connectivityStream = connectivityStream,
        _analytics = analytics;

  final MalaLocalDataSource _local;
  final CreateUserAccumulatorUseCase _createAccumulator;
  final UpdateUserAccumulatorUseCase _updateAccumulator;
  final SubmitGroupAccumulatorCountUseCase _submitGroupCount;
  final bool Function() _isLoggedIn;
  final Future<String?> Function() _currentUserId;
  final Stream<bool>? _connectivityStream;
  final AnalyticsService? _analytics;

  final _logger = AppLogger('MalaSyncManager');

  static const Duration _debounceDelay = Duration(seconds: 5);
  static const Duration _maxBackoff = Duration(seconds: 60);
  static const Duration _syncIdleTimeout = Duration(seconds: 30);

  bool _started = false;
  bool _isSyncing = false;
  bool _dirty = false; // a trigger fired mid-flush; sweep again afterwards
  Timer? _debounce;
  Timer? _retry;
  int _retryAttempt = 0;
  StreamSubscription<bool>? _connectivitySub;

  /// Called after a group session count POST succeeds. Used to refresh lifetime
  /// totals from `GET /accumulators/{id}/groups`.
  void Function(String groupAccumulatorId)? onGroupCountSynced;

  /// Called after a personal session PUT succeeds so UI can refresh lifetime
  /// `total_counted` for [GroupAccumulationsSheet].
  void Function(String presetId)? onPersonalCountSynced;

  /// Attach lifecycle + connectivity observers and flush any offline tail.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _connectivitySub = _connectivityStream?.listen((online) {
      if (online) unawaited(flush(SyncReason.reconnect));
    });
    unawaited(flush(SyncReason.launch));
  }

  void dispose() {
    _debounce?.cancel();
    _retry?.cancel();
    _connectivitySub?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  /// Called by the counter notifier on each tap.
  void onTap({required bool roundComplete}) {
    if (roundComplete) {
      _debounce?.cancel();
      unawaited(flush(SyncReason.roundComplete));
    } else {
      _debounce?.cancel();
      _debounce = Timer(_debounceDelay, () => flush(SyncReason.debounce));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(flush(SyncReason.background));
    }
  }

  /// One guarded flush for all triggers. Idempotent: re-sending the same
  /// absolute total is a no-op on the server, so retries are always safe.
  Future<void> flush(SyncReason reason) async {
    if (!_isLoggedIn()) return;
    final userId = await _currentUserId();
    if (userId == null || userId.isEmpty) return;

    if (_isSyncing) {
      _dirty = true; // collapse concurrent triggers
      return;
    }
    _isSyncing = true;
    _debounce?.cancel();

    try {
      for (final presetId in _local.dirtyPresetIds(userId)) {
        final s = _local.read(userId, presetId);
        if (!s.isDirty) continue;
        await _pushTotal(userId, presetId, s.total);
      }
      for (final groupAccumulatorId in _local.dirtyGroupAccumulatorIds(userId)) {
        final s = _local.readGroup(userId, groupAccumulatorId);
        if (!s.isDirty) continue;
        await _pushGroupTotal(userId, groupAccumulatorId, s.total);
      }
      _retryAttempt = 0;
      _retry?.cancel();
    } catch (e) {
      _logger.warning('Mala flush failed ($reason): $e');
      _scheduleRetry();
    } finally {
      _isSyncing = false;
      if (_dirty) {
        _dirty = false;
        unawaited(flush(reason)); // sweep taps that landed mid-flush
      }
    }
  }

  /// Resets the on-screen session by soft-deleting the active user accumulator
  /// for [presetId]. Unsynced taps are flushed to the existing accumulator
  /// first so lifetime totals on that record are preserved server-side. A new
  /// accumulator is lazily created on the next sync after counting resumes.
  ///
  /// [deleteAccumulator] is passed per call (not stored on the manager) so
  /// reset stays correct after hot reload of the app-scoped sync manager.
  Future<void> resetAccumulator(
    String presetId, {
    required DeleteUserAccumulatorUseCase deleteAccumulator,
  }) async {
    if (!_isLoggedIn()) {
      throw StateError('Cannot reset mala while logged out');
    }
    final userId = await _currentUserId();
    if (userId == null || userId.isEmpty) {
      throw StateError('Cannot reset mala without a user id');
    }

    await _awaitSyncIdle();
    _isSyncing = true;
    _debounce?.cancel();

    try {
      final before = _local.read(userId, presetId);
      _logger.info(
        'Reset start presetId=$presetId total=${before.total} '
        'synced=${before.syncedTotal} accId=${before.accumulatorId}',
      );

      if (before.isDirty) {
        _logger.info('Reset flushing dirty tail before DELETE');
        await _pushTotal(userId, presetId, before.total);
      }

      final accumulatorId = _local.read(userId, presetId).accumulatorId;
      if (accumulatorId != null && accumulatorId.isNotEmpty) {
        _logger.info('Reset DELETE /accumulators/user/$accumulatorId');
        final deleted = await deleteAccumulator(accumulatorId);
        deleted.fold(
          (failure) => throw Exception(failure.message),
          (_) {},
        );
      } else {
        _logger.info('Reset no active accumulator to delete presetId=$presetId');
      }

      await _local.clearSession(userId, presetId);

      _logger.info('Reset complete presetId=$presetId');

      _analytics?.track(
        AnalyticsEvents.malaSynced,
        properties: {
          if (accumulatorId != null) 'accumulatorId': accumulatorId,
          'total': 0,
          'reset': true,
        },
      );
    } catch (e, st) {
      _logger.warning('Reset failed presetId=$presetId: $e', e, st);
      rethrow;
    } finally {
      _isSyncing = false;
      // Unlike [flush], we do not re-sweep when [_dirty] is set: the session
      // was cleared and any tap that landed mid-reset will create a fresh
      // accumulator on the next normal flush.
      if (_dirty) _dirty = false;
    }
  }

  /// Resets the user's group count by soft-deleting via
  /// `DELETE /group-accumulators/{id}`. Unsynced taps are flushed first so
  /// lifetime totals on the deleted record are preserved server-side.
  ///
  /// [deleteGroupAccumulator] is passed per call (not stored on the manager) so
  /// reset stays correct after hot reload of the app-scoped sync manager.
  Future<void> resetGroupAccumulator(
    String groupAccumulatorId, {
    required DeleteGroupAccumulatorUseCase deleteGroupAccumulator,
  }) async {
    if (!_isLoggedIn()) {
      throw StateError('Cannot reset group mala while logged out');
    }
    final userId = await _currentUserId();
    if (userId == null || userId.isEmpty) {
      throw StateError('Cannot reset group mala without a user id');
    }

    await _awaitSyncIdle();
    _isSyncing = true;
    _debounce?.cancel();

    try {
      final before = _local.readGroup(userId, groupAccumulatorId);
      _logger.info(
        'Group reset start groupAccumulatorId=$groupAccumulatorId '
        'total=${before.total} synced=${before.syncedTotal}',
      );

      if (before.isDirty) {
        _logger.info('Group reset flushing dirty tail before DELETE');
        await _pushGroupTotal(userId, groupAccumulatorId, before.total);
      }

      _logger.info(
        'Group reset DELETE /group-accumulators/$groupAccumulatorId',
      );
      final deleted = await deleteGroupAccumulator(groupAccumulatorId);
      deleted.fold(
        (failure) => throw Exception(failure.message),
        (_) {},
      );

      await _local.clearGroupSession(userId, groupAccumulatorId);

      _logger.info(
        'Group reset complete groupAccumulatorId=$groupAccumulatorId',
      );

      _analytics?.track(
        AnalyticsEvents.malaSynced,
        properties: {
          'groupAccumulatorId': groupAccumulatorId,
          'total': 0,
          'reset': true,
          'group': true,
        },
      );
    } catch (e, st) {
      _logger.warning(
        'Group reset failed groupAccumulatorId=$groupAccumulatorId: $e',
        e,
        st,
      );
      rethrow;
    } finally {
      _isSyncing = false;
      if (_dirty) _dirty = false;
    }
  }

  /// Flushes and waits for the in-flight sweep so callers can refetch
  /// server-backed counts right after.
  Future<void> flushAndSettle(SyncReason reason) async {
    await flush(reason);
    try {
      await _awaitSyncIdle();
    } on TimeoutException {
      // Best effort; the caller refreshes with whatever has landed.
    }
  }

  Future<void> _awaitSyncIdle() async {
    final deadline = DateTime.now().add(_syncIdleTimeout);
    while (_isSyncing) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException(
          'Timed out waiting for in-flight sync before reset',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _pushTotal(String userId, String presetId, int sending) async {
    final beforePush = _local.read(userId, presetId);
    final s = beforePush;

    // First time only: mint the accumulator once via POST {parent_id}.
    // The new accumulator starts at 0; the absolute total is pushed by the
    // PUT below. Thereafter accumulatorId is non-null and we PUT only.
    var accumulatorId = s.accumulatorId;
    if (accumulatorId == null) {
      final created = await _createAccumulator(presetId);
      final newId = created.fold(
        (failure) => throw Exception(failure.message),
        (count) => count.accumulatorId,
      );
      if (newId == null || newId.isEmpty) {
        throw Exception('Create returned no accumulator id');
      }
      await _local.write(
        userId,
        presetId,
        _local.read(userId, presetId).copyWith(accumulatorId: newId),
      );
      accumulatorId = newId;
    }

    final result = await _updateAccumulator(
      UpdateUserAccumulatorParams(
        accumulatorId: accumulatorId,
        currentCount: sending,
      ),
    );

    await result.fold(
      (failure) async => throw Exception(failure.message),
      (count) async {
        // Re-read: taps may have landed during the round-trip.
        final after = _local.read(userId, presetId);
        final confirmedTotal = max(count.total, sending);
        final syncedDelta = confirmedTotal - beforePush.syncedTotal;
        final nextTotalCounted =
            syncedDelta > 0
                ? beforePush.totalCounted + syncedDelta
                : beforePush.totalCounted;
        await _local.write(
          userId,
          presetId,
          after.copyWith(
            total: max(after.total, count.total),
            syncedTotal: confirmedTotal,
            totalCounted: nextTotalCounted,
            accumulatorId: count.accumulatorId ?? accumulatorId,
          ),
        );
        _analytics?.track(
          AnalyticsEvents.malaSynced,
          properties: {
            'accumulatorId': count.accumulatorId ?? accumulatorId,
            'total': max(after.total, count.total),
          },
        );
        onPersonalCountSynced?.call(presetId);
      },
    );
  }

  Future<void> _pushGroupTotal(
    String userId,
    String groupAccumulatorId,
    int sending,
  ) async {
    final result = await _submitGroupCount(
      SubmitGroupAccumulatorCountParams(
        groupAccumulatorId: groupAccumulatorId,
        currentCount: sending,
      ),
    );

    await result.fold(
      (failure) async => throw Exception(failure.message),
      (_) async {
        // Re-read: taps may have landed during the round-trip.
        final after = _local.readGroup(userId, groupAccumulatorId);
        final confirmedTotal = max(after.syncedTotal, sending);
        await _local.writeGroup(
          userId,
          groupAccumulatorId,
          after.copyWith(
            total: max(after.total, sending),
            syncedTotal: confirmedTotal,
          ),
        );
        _analytics?.track(
          AnalyticsEvents.malaSynced,
          properties: {
            'groupAccumulatorId': groupAccumulatorId,
            'total': max(after.total, sending),
            'group': true,
          },
        );
        onGroupCountSynced?.call(groupAccumulatorId);
      },
    );
  }

  void _scheduleRetry() {
    _retry?.cancel();
    final seconds = min(_maxBackoff.inSeconds, pow(2, _retryAttempt + 1).toInt());
    _retryAttempt++;
    _retry = Timer(Duration(seconds: seconds), () => flush(SyncReason.launch));
  }
}
