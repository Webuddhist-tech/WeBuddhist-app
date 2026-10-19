import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/mala/data/models/accumulator_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _logger = AppLogger('MalaLocalDataSource');

/// Per-`(userId, presetId)` local counting state.
///
/// Numbers: the monotonic local [total] and the server-confirmed
/// [syncedTotal]. [accumulatorId] is the user-owned accumulator id (null until
/// it has been created on the backend). A background flush only needs the
/// preset id (the Hive key) to create, so nothing else is cached here.
class LocalMalaState {
  const LocalMalaState({
    this.total = 0,
    this.syncedTotal = 0,
    this.totalCounted = 0,
    this.accumulatorId,
    this.beadImageUrl,
    this.beadImageBase64,
  });

  final int total;
  final int syncedTotal;

  /// Lifetime `total_counted` baseline from the server, updated on sync.
  final int totalCounted;
  final String? accumulatorId;

  /// Cached bead-image URL so the strand can render offline on a cold start,
  /// before the seed network call returns.
  final String? beadImageUrl;

  /// Actual bead artwork bytes, base64-encoded for Hive string storage.
  /// The UI prefers this over the URL so the bead renders instantly offline.
  final String? beadImageBase64;

  Uint8List? get beadImageBytes {
    final raw = beadImageBase64;
    if (raw == null || raw.isEmpty) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  bool get isDirty => total > syncedTotal;

  LocalMalaState copyWith({
    int? total,
    int? syncedTotal,
    int? totalCounted,
    String? accumulatorId,
    String? beadImageUrl,
    String? beadImageBase64,
  }) => LocalMalaState(
    total: total ?? this.total,
    syncedTotal: syncedTotal ?? this.syncedTotal,
    totalCounted: totalCounted ?? this.totalCounted,
    accumulatorId: accumulatorId ?? this.accumulatorId,
    beadImageUrl: beadImageUrl ?? this.beadImageUrl,
    beadImageBase64: beadImageBase64 ?? this.beadImageBase64,
  );

  Map<String, dynamic> toJson() => {
    'total': total,
    'syncedTotal': syncedTotal,
    'totalCounted': totalCounted,
    if (accumulatorId != null) 'accumulatorId': accumulatorId,
    if (beadImageUrl != null) 'beadImageUrl': beadImageUrl,
    if (beadImageBase64 != null) 'beadImageBase64': beadImageBase64,
  };

  factory LocalMalaState.fromJson(Map<String, dynamic> j) => LocalMalaState(
    total: (j['total'] as num?)?.toInt() ?? 0,
    syncedTotal: (j['syncedTotal'] as num?)?.toInt() ?? 0,
    totalCounted: (j['totalCounted'] as num?)?.toInt() ?? 0,
    accumulatorId: j['accumulatorId'] as String?,
    beadImageUrl: j['beadImageUrl'] as String?,
    beadImageBase64: j['beadImageBase64'] as String?,
  );
}

/// Per-`(userId, groupAccumulatorId)` local group counting state.
class LocalGroupMalaState {
  const LocalGroupMalaState({
    this.total = 0,
    this.syncedTotal = 0,
  });

  final int total;
  final int syncedTotal;

  bool get isDirty => total > syncedTotal;

  LocalGroupMalaState copyWith({int? total, int? syncedTotal}) =>
      LocalGroupMalaState(
        total: total ?? this.total,
        syncedTotal: syncedTotal ?? this.syncedTotal,
      );

  Map<String, dynamic> toJson() => {
    'total': total,
    'syncedTotal': syncedTotal,
  };

  factory LocalGroupMalaState.fromJson(Map<String, dynamic> j) =>
      LocalGroupMalaState(
        total: (j['total'] as num?)?.toInt() ?? 0,
        syncedTotal: (j['syncedTotal'] as num?)?.toInt() ?? 0,
      );
}

/// Hive-backed local store for mala counts, namespaced by user id so one
/// account never reads or sends another's counts. Keys are `userId:presetId`.
class MalaLocalDataSource {
  static const String boxName = 'mala_counts';
  static const String groupBoxName = 'mala_group_counts';

  Box<String> get _box => Hive.box<String>(boxName);
  Box<String> get _groupBox => Hive.box<String>(groupBoxName);

  /// Open the box. Call once during app bootstrap (after `Hive.initFlutter()`).
  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<String>(boxName);
    }
    if (!Hive.isBoxOpen(groupBoxName)) {
      await Hive.openBox<String>(groupBoxName);
    }
    _logger.info('MalaLocalDataSource initialized');
  }

  String _key(String userId, String presetId) => '$userId:$presetId';
  // Bumped when the cached preset shape gains fields (v2: deity_image), so a
  // cache written by an older build is skipped instead of served stale.
  String _catalogueKey(String language) => 'catalogue:v2:$language';

  /// Key used before v2. Only read as an offline fallback, and deleted once a
  /// v2 catalogue is written.
  String _legacyCatalogueKey(String language) => 'catalogue:$language';

  /// The cached catalogue for [language]. With [allowLegacy], falls back to a
  /// pre-v2 cache (no deity images) when there is no v2 one — for when the
  /// network is down and an older cache beats an empty screen.
  List<PresetAccumulatorModel>? readCatalogue(
    String language, {
    bool allowLegacy = false,
  }) {
    final raw =
        _box.get(_catalogueKey(language)) ??
        (allowLegacy ? _box.get(_legacyCatalogueKey(language)) : null);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map(
            (item) =>
                PresetAccumulatorModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      _logger.error('Failed to parse local mala catalogue', e);
      return null;
    }
  }

  Future<void> writeCatalogue(
    String language,
    List<PresetAccumulatorModel> presets,
  ) async {
    await _box.put(
      _catalogueKey(language),
      jsonEncode(presets.map((preset) => preset.toJson()).toList()),
    );
    await _box.delete(_legacyCatalogueKey(language));
  }

  LocalMalaState read(String userId, String presetId) {
    final raw = _box.get(_key(userId, presetId));
    if (raw == null) return const LocalMalaState();
    try {
      return LocalMalaState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      _logger.error('Failed to parse local mala state', e);
      return const LocalMalaState();
    }
  }

  Future<void> write(String userId, String presetId, LocalMalaState s) =>
      _box.put(_key(userId, presetId), jsonEncode(s.toJson()));

  /// Append one recitation to the monotonic local total.
  Future<LocalMalaState> recordTap(String userId, String presetId) async {
    final s = read(userId, presetId);
    final next = s.copyWith(total: s.total + 1);
    await write(userId, presetId, next);
    return next;
  }

  /// Adds [delta] beads to the monotonic local total (e.g. offline mala rounds).
  Future<LocalMalaState> addToTotal(
    String userId,
    String presetId,
    int delta,
  ) async {
    if (delta <= 0) return read(userId, presetId);
    final s = read(userId, presetId);
    final next = s.copyWith(total: s.total + delta);
    await write(userId, presetId, next);
    return next;
  }

  /// Clears the on-screen session after a reset: count back to zero and no
  /// active accumulator id. Preserves [beadImageUrl] for offline rendering.
  Future<void> clearSession(String userId, String presetId) async {
    final s = read(userId, presetId);
    await write(
      userId,
      presetId,
      LocalMalaState(
        totalCounted: s.totalCounted,
        beadImageUrl: s.beadImageUrl,
        beadImageBase64: s.beadImageBase64,
      ),
    );
  }

  /// Preset ids for [userId] whose local total is ahead of the server.
  List<String> dirtyPresetIds(String userId) {
    final prefix = '$userId:';
    return _box.keys
        .cast<String>()
        .where((k) => k.startsWith(prefix))
        .where((k) {
          final raw = _box.get(k);
          if (raw == null) return false;
          try {
            return LocalMalaState.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            ).isDirty;
          } catch (_) {
            return false;
          }
        })
        .map((k) => k.substring(prefix.length))
        .toList();
  }

  /// Remove fully-synced entries for [userId] (storage hygiene on shared
  /// devices). Dirty entries are retained so no unsynced tail is lost.
  Future<void> pruneSynced(String userId) async {
    final prefix = '$userId:';
    final toDelete =
        _box.keys.cast<String>().where((k) {
          if (!k.startsWith(prefix)) return false;
          final raw = _box.get(k);
          if (raw == null) return true;
          try {
            return !LocalMalaState.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            ).isDirty;
          } catch (_) {
            return true;
          }
        }).toList();
    await _box.deleteAll(toDelete);
  }

  // ========== Group accumulations (separate box) ==========

  String _groupKey(String userId, String groupAccumulatorId) =>
      '$userId:$groupAccumulatorId';

  LocalGroupMalaState readGroup(String userId, String groupAccumulatorId) {
    final raw = _groupBox.get(_groupKey(userId, groupAccumulatorId));
    if (raw == null) return const LocalGroupMalaState();
    try {
      return LocalGroupMalaState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      _logger.error('Failed to parse local group mala state', e);
      return const LocalGroupMalaState();
    }
  }

  Future<void> writeGroup(
    String userId,
    String groupAccumulatorId,
    LocalGroupMalaState s,
  ) =>
      _groupBox.put(
        _groupKey(userId, groupAccumulatorId),
        jsonEncode(s.toJson()),
      );

  Future<LocalGroupMalaState> recordGroupTap(
    String userId,
    String groupAccumulatorId,
  ) async {
    final s = readGroup(userId, groupAccumulatorId);
    final next = s.copyWith(total: s.total + 1);
    await writeGroup(userId, groupAccumulatorId, next);
    return next;
  }

  Future<LocalGroupMalaState> addGroupToTotal(
    String userId,
    String groupAccumulatorId,
    int delta,
  ) async {
    if (delta <= 0) return readGroup(userId, groupAccumulatorId);
    final s = readGroup(userId, groupAccumulatorId);
    final next = s.copyWith(total: s.total + delta);
    await writeGroup(userId, groupAccumulatorId, next);
    return next;
  }

  /// Clears the local group count after a reset (`total` and `syncedTotal` back
  /// to zero). The user remains joined; counting resumes via POST on next tap.
  Future<void> clearGroupSession(
    String userId,
    String groupAccumulatorId,
  ) async {
    await writeGroup(
      userId,
      groupAccumulatorId,
      const LocalGroupMalaState(),
    );
  }

  List<String> groupAccumulatorIdsForUser(String userId) {
    final prefix = '$userId:';
    return _groupBox.keys
        .cast<String>()
        .where((k) => k.startsWith(prefix))
        .map((k) => k.substring(prefix.length))
        .toList();
  }

  List<String> dirtyGroupAccumulatorIds(String userId) {
    final prefix = '$userId:';
    return _groupBox.keys
        .cast<String>()
        .where((k) => k.startsWith(prefix))
        .where((k) {
          final raw = _groupBox.get(k);
          if (raw == null) return false;
          try {
            return LocalGroupMalaState.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            ).isDirty;
          } catch (_) {
            return false;
          }
        })
        .map((k) => k.substring(prefix.length))
        .toList();
  }
}
