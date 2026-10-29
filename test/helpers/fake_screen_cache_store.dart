import 'dart:async';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';

/// In-memory stand-in for the Hive-backed screen cache.
class FakeScreenCacheStore extends ScreenCacheStore {
  FakeScreenCacheStore({this.userId = 'user-1'});

  final Map<String, String> entries = {};
  final _changes = StreamController<String>.broadcast();
  String? userId;

  @override
  Future<String?> currentUserId() async => userId;

  @override
  String? get currentUserIdSync => userId;

  @override
  String? read(String key) => entries[key];

  @override
  Future<bool> save(String key, String json) async {
    if (entries[key] == json) return false;
    entries[key] = json;
    _changes.add(key);
    return true;
  }

  @override
  Future<void> remove(String key) async {
    if (entries.remove(key) != null) _changes.add(key);
  }

  @override
  Stream<void> watch(String key) {
    return _changes.stream.where((k) => k == key).map((_) => null);
  }
}
