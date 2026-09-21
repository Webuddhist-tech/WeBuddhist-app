import 'dart:convert';

import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/timer/data/models/preset_timer_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

final _logger = AppLogger('TimersLocalDatasource');

class PendingTimerStop {
  const PendingTimerStop({
    required this.id,
    required this.timerId,
    required this.durationMs,
    required this.createdAtMs,
  });

  final String id;
  final String timerId;
  final int durationMs;
  final int createdAtMs;

  Map<String, dynamic> toJson() => {
    'id': id,
    'timerId': timerId,
    'durationMs': durationMs,
    'createdAtMs': createdAtMs,
  };

  factory PendingTimerStop.fromJson(Map<String, dynamic> json) {
    return PendingTimerStop(
      id: (json['id'] as String?) ?? '',
      timerId: (json['timerId'] as String?) ?? '',
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Persistent local source of truth for timer catalogue and pending writes.
///
/// Preset timers are namespaced by user id because the screen is currently
/// authenticated. Timer stop reports are queued per user so offline sessions
/// can be flushed later without leaking between accounts.
class TimersLocalDatasource {
  static const String boxName = 'timers_local_data';

  Box<String> get _box => Hive.box<String>(boxName);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<String>(boxName);
      _logger.info('TimersLocalDatasource initialized');
    }
  }

  Future<String?> currentUserId() {
    return SharedPreferencesService.instance.get<String>(
      StorageKeys.currentUserId,
    );
  }

  Stream<void> watchKey(String key) async* {
    await for (final _ in _box.watch(key: key)) {
      yield null;
    }
  }

  String presetTimersKey(String userId, int skip, int limit) =>
      'preset_timers:$userId:$skip:$limit';

  String pendingStopsKey(String userId) => 'pending_timer_stops:$userId';

  List<PresetTimerModel>? readPresetTimers(
    String userId, {
    required int skip,
    required int limit,
  }) {
    return _readModelList(
      presetTimersKey(userId, skip, limit),
      PresetTimerModel.fromJson,
    );
  }

  Future<void> savePresetTimers(
    String userId, {
    required int skip,
    required int limit,
    required List<PresetTimerModel> timers,
  }) {
    return _writeModelList(
      presetTimersKey(userId, skip, limit),
      timers.map((timer) => timer.toJson()).toList(),
    );
  }

  /// Adds (or replaces) [timer] in the cached first page of preset timers, so
  /// the list watcher shows a freshly created timer without depending on a
  /// successful remote refresh. No-op when nothing is cached yet — the stream
  /// fetches from the network in that case anyway.
  Future<void> upsertPresetTimer(
    String userId, {
    required PresetTimerModel timer,
    int skip = 0,
    int limit = 20,
  }) async {
    final key = presetTimersKey(userId, skip, limit);
    final cached = _readModelList(key, PresetTimerModel.fromJson);
    if (cached == null) return;

    final existingIndex = cached.indexWhere((item) => item.id == timer.id);
    final updated = [...cached];
    if (existingIndex == -1) {
      updated.add(timer);
    } else {
      // Replace in place so editing a timer doesn't move its card in the grid.
      updated[existingIndex] = timer;
    }
    await _writeModelList(key, updated.map((item) => item.toJson()).toList());
  }

  /// Drops [timerId] from every cached page of preset timers, so a deleted
  /// timer disappears from the list even if the remote refresh fails.
  Future<void> removePresetTimer(String userId, String timerId) async {
    final prefix = 'preset_timers:$userId:';
    final keys =
        _box.keys
            .whereType<String>()
            .where((key) => key.startsWith(prefix))
            .toList();

    for (final key in keys) {
      final cached = _readModelList(key, PresetTimerModel.fromJson);
      if (cached == null) continue;
      if (!cached.any((item) => item.id == timerId)) continue;
      await _writeModelList(
        key,
        cached
            .where((item) => item.id != timerId)
            .map((item) => item.toJson())
            .toList(),
      );
    }
  }

  List<PendingTimerStop> readPendingStops(String userId) {
    return _readModelList(pendingStopsKey(userId), PendingTimerStop.fromJson) ??
        const <PendingTimerStop>[];
  }

  Future<PendingTimerStop> enqueueTimerStop(
    String userId, {
    required String timerId,
    required int durationMs,
  }) async {
    final createdAtMs = DateTime.now().millisecondsSinceEpoch;
    final pending = PendingTimerStop(
      id: '$createdAtMs:$timerId:$durationMs:${const Uuid().v4()}',
      timerId: timerId,
      durationMs: durationMs,
      createdAtMs: createdAtMs,
    );
    await _writeModelList(
      pendingStopsKey(userId),
      [
        ...readPendingStops(userId),
        pending,
      ].map((item) => item.toJson()).toList(),
    );
    return pending;
  }

  Future<void> removePendingStop(String userId, String pendingId) {
    final remaining =
        readPendingStops(userId)
            .where((item) => item.id != pendingId)
            .map((item) => item.toJson())
            .toList();
    return _writeModelList(pendingStopsKey(userId), remaining);
  }

  List<T>? _readModelList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logger.error('Failed to read timer list for $key', e, st);
      return null;
    }
  }

  Future<void> _writeModelList(String key, List<Map<String, dynamic>> data) {
    return _box.put(key, jsonEncode(data));
  }
}
