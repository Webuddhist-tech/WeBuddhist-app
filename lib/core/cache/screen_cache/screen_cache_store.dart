import 'dart:async';

import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _logger = AppLogger('ScreenCacheStore');

/// Last-known-good JSON per screen key; no TTL, a missing box means network-only.
class ScreenCacheStore {
  static const String boxName = 'screen_cache';
  static const int schemaVersion = 1;
  static const String versionPrefix = 'v$schemaVersion:';

  final Map<String, Future<String>> _inFlight = {};

  Box<String>? get _box =>
      Hive.isBoxOpen(boxName) ? Hive.box<String>(boxName) : null;

  /// Opens the box and drops entries written under an older schema.
  static Future<void> init() async {
    if (Hive.isBoxOpen(boxName)) return;
    final box = await Hive.openBox<String>(boxName);
    final stale =
        box.keys
            .where((k) => k is! String || !k.startsWith(versionPrefix))
            .toList();
    if (stale.isNotEmpty) await box.deleteAll(stale);
    _logger.info('ScreenCacheStore initialized');
  }

  Future<String?> currentUserId() {
    return SharedPreferencesService.instance.get<String>(
      StorageKeys.currentUserId,
    );
  }

  String? read(String key) => _box?.get(key);

  /// Writes only when the payload differs so watchers fire on real change.
  Future<bool> save(String key, String json) async {
    final box = _box;
    if (box == null || box.get(key) == json) return false;
    await box.put(key, json);
    return true;
  }

  Future<void> remove(String key) async {
    await _box?.delete(key);
  }

  Stream<void> watch(String key) {
    final box = _box;
    if (box == null) return const Stream.empty();
    return box.watch(key: key).map((_) => null);
  }

  /// Fetches, saves and returns the JSON; concurrent callers share one fetch.
  Future<String> revalidate(String key, Future<String> Function() fetchJson) {
    return _inFlight[key] ??= fetchJson()
        .then((json) async {
          await save(key, json);
          return json;
        })
        .whenComplete(() {
          _inFlight.remove(key);
        });
  }
}
