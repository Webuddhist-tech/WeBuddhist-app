import 'dart:async';

import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_accumulation_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MalaAccumulationSelectionNotifier
    extends StateNotifier<MalaAccumulationSelection> {
  MalaAccumulationSelectionNotifier(this._presetId)
    : super(const MalaAccumulationSelection.personal()) {
    _load();
  }

  final String _presetId;
  String? _navigationGroupAccumulatorId;
  bool _loadedFromStorage = false;
  final _loaded = Completer<void>();

  /// Resolves once the persisted selection has been applied.
  Future<void> get loaded => _loaded.future;

  /// Applies a one-shot group selection from navigation (e.g. group accumulator
  /// "Recite now"). Takes precedence over persisted selection when [_load] has
  /// not finished yet; otherwise selects immediately.
  Future<void> applyNavigationIntent(String groupAccumulatorId) async {
    if (groupAccumulatorId.isEmpty) return;
    if (!_loadedFromStorage) {
      _navigationGroupAccumulatorId = groupAccumulatorId;
      return;
    }
    await selectGroup(groupAccumulatorId);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      '${StorageKeys.malaAccumulationSelectionPrefix}$_presetId',
    );
    final navigationGroupId = _navigationGroupAccumulatorId;
    if (navigationGroupId != null && navigationGroupId.isNotEmpty) {
      state = MalaAccumulationSelection.group(navigationGroupId);
      _navigationGroupAccumulatorId = null;
      await _persist();
    } else {
      state = MalaAccumulationSelection.fromStorage(raw);
    }
    _loadedFromStorage = true;
    _loaded.complete();
  }

  Future<void> selectPersonal() async {
    state = const MalaAccumulationSelection.personal();
    await _persist();
  }

  Future<void> selectGroup(String groupAccumulatorId) async {
    state = MalaAccumulationSelection.group(groupAccumulatorId);
    await _persist();
  }

  /// Falls back to personal when the saved group is no longer joined.
  Future<void> validateAgainst(List<AccumulatorGroup> groups) async {
    final id = state.groupAccumulatorId;
    if (id == null) return;
    final stillJoined = groups.any((g) => g.groupAccumulatorId == id);
    if (!stillJoined) await selectPersonal();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${StorageKeys.malaAccumulationSelectionPrefix}$_presetId',
      state.toStorage(),
    );
  }
}

final malaAccumulationSelectionProvider = StateNotifierProvider.autoDispose
    .family<MalaAccumulationSelectionNotifier, MalaAccumulationSelection, String>(
      (ref, presetId) => MalaAccumulationSelectionNotifier(presetId),
    );
