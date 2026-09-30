import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_selection_state.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _logger = AppLogger('TraditionSelectionNotifier');

class TraditionSelectionNotifier
    extends StateNotifier<TraditionSelectionState> {
  TraditionSelectionNotifier({
    required OnboardingRemoteDatasource remoteDatasource,
    required String language,
  }) : _remoteDatasource = remoteDatasource,
       _language = language,
       super(const TraditionSelectionState()) {
    loadPaths();
  }

  final OnboardingRemoteDatasource _remoteDatasource;
  final String _language;

  /// Codes this flow has saved on the server. A retry after a partial
  /// failure skips them, and removes any the user has since unchecked.
  final Set<String> _savedCodes = {};

  Future<void> loadPaths() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final paths = await _remoteDatasource.fetchTraditionOnboardingPaths(
        language: _language,
      );
      state = state.copyWith(paths: paths, isLoading: false);
    } catch (e, stackTrace) {
      _logger.error('Failed to load tradition paths', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load traditions',
      );
    }
  }

  /// Checks [code] if unchecked, unchecks it otherwise. Ignored while saving
  /// so the saved set always matches what was checked on Continue.
  void toggleTradition(String code) {
    if (state.isSaving) return;
    final codes = {...state.selectedCodes};
    if (!codes.remove(code)) codes.add(code);
    state = state.copyWith(selectedCodes: codes, clearError: true);
  }

  /// "Show me everything": checks every path, or clears them all when every
  /// path is already checked. Ignored while saving, like [toggleTradition].
  void toggleAll() {
    if (state.isSaving) return;
    state = state.copyWith(
      selectedCodes:
          state.isAllSelected ? {} : {for (final p in state.paths) p.code},
      clearError: true,
    );
  }

  /// Makes the server match the checked traditions: saves each new one (the
  /// API takes one tradition per call) and removes any this flow saved that
  /// the user has since unchecked. Returns false if any request failed; what
  /// succeeded is kept, so a retry only redoes what is left.
  Future<bool> submitSelection() async {
    if (!state.hasSelection || state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    final selected = state.selectedCodes;

    var allSaved = await _removeUnchecked(selected);
    for (final code in selected.difference(_savedCodes)) {
      try {
        await _remoteDatasource.saveUserTradition(
          SaveTraditionRequest(traditionCode: code),
        );
        _savedCodes.add(code);
      } catch (e, stackTrace) {
        _logger.error('Failed to save user tradition $code', e, stackTrace);
        allSaved = false;
      }
    }

    state = state.copyWith(
      isSaving: false,
      error: allSaved ? null : 'Failed to save tradition',
    );
    return allSaved;
  }

  /// Deletes traditions an earlier submit saved that are no longer in
  /// [selected]. Only touches what this flow saved.
  Future<bool> _removeUnchecked(Set<String> selected) async {
    final unchecked = _savedCodes.difference(selected);
    if (unchecked.isEmpty) return true;

    final List<UserTradition> saved;
    try {
      // Deleting needs the server id, which the save call does not return.
      saved = await _remoteDatasource.fetchUserTraditions(language: _language);
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch user traditions', e, stackTrace);
      return false;
    }

    var allRemoved = true;
    for (final code in unchecked) {
      try {
        for (final tradition in saved.where((t) => t.traditionCode == code)) {
          await _remoteDatasource.deleteUserTradition(tradition.id);
        }
        _savedCodes.remove(code);
      } catch (e, stackTrace) {
        _logger.error('Failed to remove user tradition $code', e, stackTrace);
        allRemoved = false;
      }
    }
    return allRemoved;
  }
}
