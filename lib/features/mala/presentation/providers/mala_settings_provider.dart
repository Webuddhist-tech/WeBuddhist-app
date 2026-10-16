import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';

/// Bounds for the mantra marquee speed multiplier.
const double kMalaMantraSpeedMin = 0.5;
const double kMalaMantraSpeedMax = 2.0;
const double kMalaMantraSpeedDefault = 1.0;

class MalaSettingsState {
  const MalaSettingsState({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.leftHanded = false,
    this.mantraSpeed = kMalaMantraSpeedDefault,
  });

  final bool soundEnabled;
  final bool vibrationEnabled;

  /// Counter sits on the right (thumb-side for a left hand) when true.
  final bool leftHanded;

  /// Marquee speed multiplier, clamped to the min/max bounds.
  final double mantraSpeed;

  MalaSettingsState copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? leftHanded,
    double? mantraSpeed,
  }) => MalaSettingsState(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    leftHanded: leftHanded ?? this.leftHanded,
    mantraSpeed: mantraSpeed ?? this.mantraSpeed,
  );
}

class MalaSettingsNotifier extends StateNotifier<MalaSettingsState> {
  MalaSettingsNotifier() : super(const MalaSettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = MalaSettingsState(
      soundEnabled: prefs.getBool(StorageKeys.malaSoundEnabled) ?? true,
      vibrationEnabled: prefs.getBool(StorageKeys.malaVibrationEnabled) ?? true,
      leftHanded: prefs.getBool(StorageKeys.malaLeftHanded) ?? false,
      mantraSpeed: _clampSpeed(
        prefs.getDouble(StorageKeys.malaMantraSpeed) ?? kMalaMantraSpeedDefault,
      ),
    );
  }

  static double _clampSpeed(double speed) =>
      speed.clamp(kMalaMantraSpeedMin, kMalaMantraSpeedMax).toDouble();

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

  Future<void> setMantraSpeed(double speed) async {
    final clamped = _clampSpeed(speed);
    state = state.copyWith(mantraSpeed: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(StorageKeys.malaMantraSpeed, clamped);
  }
}

final malaSettingsProvider =
    StateNotifierProvider<MalaSettingsNotifier, MalaSettingsState>((ref) {
      return MalaSettingsNotifier();
    });
