import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';

/// SharedPreferences implementation of StorageService.
///
/// Provides persistent key-value storage using SharedPreferences.
class SharedPreferencesService implements StorageService {
  SharedPreferencesService._();
  static SharedPreferencesService? _serviceInstance;
  static SharedPreferencesService get instance =>
      _serviceInstance ??= SharedPreferencesService._();

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<T?> get<T>(String key) async {
    final prefs = await _prefsInstance;
    return prefs.get(key) as T?;
  }

  /// Null until the first async read has loaded the preferences.
  T? getSync<T>(String key) => _prefs?.get(key) as T?;

  @override
  Future<bool> set<T>(String key, T value) async {
    final prefs = await _prefsInstance;
    if (value is String) return prefs.setString(key, value);
    if (value is int) return prefs.setInt(key, value);
    if (value is double) return prefs.setDouble(key, value);
    if (value is bool) return prefs.setBool(key, value);
    if (value is List<String>) return prefs.setStringList(key, value);
    throw UnsupportedError('Type ${T.toString()} not supported');
  }

  @override
  Future<bool> delete(String key) async {
    final prefs = await _prefsInstance;
    return prefs.remove(key);
  }

  @override
  Future<bool> clear() async {
    final prefs = await _prefsInstance;
    return prefs.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    final prefs = await _prefsInstance;
    return prefs.containsKey(key);
  }
}

/// Riverpod provider for SharedPreferencesService
final storageServiceProvider = Provider<StorageService>((ref) {
  return SharedPreferencesService.instance;
});

/// @deprecated Use storageServiceProvider instead
final preferencesServiceProvider = Provider<StorageService>((ref) {
  return SharedPreferencesService.instance;
});
