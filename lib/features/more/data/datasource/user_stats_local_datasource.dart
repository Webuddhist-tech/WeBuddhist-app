import 'dart:async';
import 'dart:convert';

import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/more/data/models/user_stats_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _logger = AppLogger('UserStatsLocalDatasource');

/// Persistent local source of truth for the Me stats section.
///
/// This is last-known user state, not a TTL cache. The UI reads this first and
/// remote refreshes write back into this box.
class UserStatsLocalDatasource {
  static const String boxName = 'me_user_stats';

  Box<String> get _box => Hive.box<String>(boxName);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<String>(boxName);
      _logger.info('UserStatsLocalDatasource initialized');
    }
  }

  Future<String?> currentUserId() {
    return SharedPreferencesService.instance.get<String>(
      StorageKeys.currentUserId,
    );
  }

  /// Same id without an await, so a screen can seed its first frame.
  String? get currentUserIdSync {
    return SharedPreferencesService.instance.getSync<String>(
      StorageKeys.currentUserId,
    );
  }

  String userStatsKey(String userId) => 'user_stats:$userId';

  UserStatsModel? readUserStats(String userId) {
    final raw = _box.get(userStatsKey(userId));
    if (raw == null) return null;
    try {
      return UserStatsModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, st) {
      _logger.error('Failed to read local user stats', e, st);
      return null;
    }
  }

  Future<void> saveUserStats(String userId, UserStatsModel stats) {
    return _box.put(userStatsKey(userId), jsonEncode(stats.toJson()));
  }

  Stream<void> watchUserStats(String userId) async* {
    await for (final _ in _box.watch(key: userStatsKey(userId))) {
      yield null;
    }
  }
}
