import 'package:flutter_pecha/core/utils/local_storage_service.dart';

/// In-memory [LocalStorageService] for provider tests.
class FakeLocalStorage implements LocalStorageService {
  final Map<String, Object> values = {};

  @override
  Future<T?> get<T>(String key) async => values[key] as T?;

  @override
  Future<bool> set<T>(String key, T value) async {
    values[key] = value as Object;
    return true;
  }

  @override
  Future<bool> remove(String key) async => values.remove(key) != null;

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<void> setUserData(Map<String, dynamic> userData) async {}

  @override
  Future<Map<String, dynamic>?> getUserData() async => null;

  @override
  Future<void> clearUserData() async {}
}
