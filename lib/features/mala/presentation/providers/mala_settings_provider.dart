import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';

class MalaSettingsState {
  const MalaSettingsState({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.leftHanded = false,
  });

  final bool soundEnabled;
  final bool vibrationEnabled;

  /// Counter sits on the right (thumb-side for a left hand) when true.
  final bool leftHanded;

  MalaSettingsState copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? leftHanded,
  }) =>
      MalaSettingsState(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        leftHanded: leftHanded ?? this.leftHanded,
      );
}

class MalaSettingsNotifier extends StateNotifier<MalaSettingsState> {
  MalaSettingsNotifier() : super(const MalaSettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = MalaSettingsState(
      soundEnabled:
          prefs.getBool(StorageKeys.malaSoundEnabled) ?? true,
      vibrationEnabled:
          prefs.getBool(StorageKeys.malaVibrationEnabled) ?? true,
      leftHanded: prefs.getBool(StorageKeys.malaLeftHanded) ?? false,
    );
  }

  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.malaSoundEnabled, enabled);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    state = state.copyWith(vibrationEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.malaVibrationEnabled, enabled);
  }

  Future<void> setLeftHanded(bool leftHanded) async {
    state = state.copyWith(leftHanded: leftHanded);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.malaLeftHanded, leftHanded);
  }
}

final malaSettingsProvider =
    StateNotifierProvider<MalaSettingsNotifier, MalaSettingsState>((ref) {
  return MalaSettingsNotifier();
});
