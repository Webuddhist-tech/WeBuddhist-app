import 'dart:async';
import 'dart:convert';

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

  /// Entries kept per key group (one language/user of one screen).
  static const int defaultGroupLimit = 200;
  static const Map<String, int> groupLimits = {'text_details': 50};
  static const String _indexPrefix = '${versionPrefix}__index:';

  final Map<String, Future<String>> _inFlight = {};

  /// Keys per group, least recently used first.
  final Map<String, List<String>> _recent = {};

  Box<String>? get _box =>
      Hive.isBoxOpen(boxName) ? Hive.box<String>(boxName) : null;

  /// Opens the box, drops entries written under an older schema and loads
  /// preferences so [currentUserIdSync] answers before the first screen.
  static Future<void> init() async {
    try {
      await SharedPreferencesService.instance.get<String>(
        StorageKeys.currentUserId,
      );
    } catch (e) {
      _logger.warning('Preferences not loaded before the first screen', e);
    }
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

  /// Same id without an await, so a screen can seed its first frame.
  String? get currentUserIdSync {
    return SharedPreferencesService.instance.getSync<String>(
      StorageKeys.currentUserId,
    );
  }

  String? read(String key) {
    final value = _box?.get(key);
    if (value != null) _touch(key);
    return value;
  }

  /// Writes only when the payload differs so watchers fire on real change.
  Future<bool> save(String key, String json) async {
    final box = _box;
    if (box == null || box.get(key) == json) return false;
    await box.put(key, json);
    await _touch(key, persist: true);
    return true;
  }

  Future<void> remove(String key) async {
    await _box?.delete(key);
    final group = groupOf(key);
    if (group != null) _recent[group]?.remove(key);
  }

  /// `v1:p:<lang>:<screen>` or `v1:u:<user>:<lang>:<screen>`; null for others.
  static String? groupOf(String key) {
    final parts = key.split(':');
    if (parts.length < 4 || parts[1] == '__index') return null;
    final length = parts[1] == 'u' ? 5 : 4;
    if (parts.length < length) return null;
    return parts.take(length).join(':');
  }

  Future<void> _touch(String key, {bool persist = false}) async {
    final box = _box;
    final group = groupOf(key);
    if (box == null || group == null) return;
    final recent = _recent[group] ??= _loadRecent(box, group);
    recent
      ..remove(key)
      ..add(key);
    if (!persist) return;
    try {
      final limit = groupLimits[group.split(':').last] ?? defaultGroupLimit;
      if (recent.length > limit) {
        final evicted = recent.sublist(0, recent.length - limit);
        recent.removeRange(0, evicted.length);
        await box.deleteAll(evicted);
      }
      await box.put('$_indexPrefix$group', jsonEncode(recent));
    } catch (e, st) {
      _logger.warning('Could not update the index for $group', e, st);
    }
  }

  List<String> _loadRecent(Box<String> box, String group) {
    final order = <String>[];
    final stored = box.get('$_indexPrefix$group');
    if (stored != null) {
      try {
        order.addAll(
          (jsonDecode(stored) as List).cast<String>().where(box.containsKey),
        );
      } catch (_) {}
    }
    for (final key in box.keys) {
      if (key is String && groupOf(key) == group && !order.contains(key)) {
        order.add(key);
      }
    }
    return order;
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
          // A full disk must not turn a good response into a load error.
          try {
            await save(key, json);
          } catch (e, st) {
            _logger.warning('Could not store $key', e, st);
          }
          return json;
        })
        .whenComplete(() {
          _inFlight.remove(key);
        });
  }
}
