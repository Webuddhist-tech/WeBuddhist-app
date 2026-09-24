import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_state.dart';
import 'package:flutter_pecha/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:flutter_pecha/features/onboarding/presentation/utils/onboarding_analytics.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _logger = AppLogger('OnboardingNotifier');

/// Notifier for managing onboarding flow state.
///
/// Uses domain use cases for all data operations, following clean architecture.
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier({
    required LoadSavedPreferencesUseCase loadSavedPreferencesUseCase,
    required SaveOnboardingPreferencesUseCase saveOnboardingPreferencesUseCase,
    required CompleteOnboardingUseCase completeOnboardingUseCase,
    required ClearOnboardingPreferencesUseCase clearOnboardingPreferencesUseCase,
    required OnboardingAnalytics analytics,
    void Function()? onCompleted,
  })  : _loadSavedPreferencesUseCase = loadSavedPreferencesUseCase,
        _saveOnboardingPreferencesUseCase = saveOnboardingPreferencesUseCase,
        _completeOnboardingUseCase = completeOnboardingUseCase,
        _clearOnboardingPreferencesUseCase = clearOnboardingPreferencesUseCase,
        _analytics = analytics,
        _onCompleted = onCompleted,
        super(OnboardingState.initial()) {
    loadSavedPreferences();
  }

  final LoadSavedPreferencesUseCase _loadSavedPreferencesUseCase;
  final SaveOnboardingPreferencesUseCase _saveOnboardingPreferencesUseCase;
  final CompleteOnboardingUseCase _completeOnboardingUseCase;
  final ClearOnboardingPreferencesUseCase _clearOnboardingPreferencesUseCase;
  final OnboardingAnalytics _analytics;
  /// Called when onboarding is successfully completed so the auth layer can
  /// update its in-state flag without a network round-trip.
  final void Function()? _onCompleted;

  /// Load saved preferences from local storage on initialization.
  Future<void> loadSavedPreferences() async {
    try {
      final result = await _loadSavedPreferencesUseCase(const NoParams());
      result.fold(
        (failure) {
          _logger.error('Error loading saved preferences', failure);
        },
        (entity) {
          if (entity != null) {
            state = state.copyWithPreferences(entity);
            _logger.debug('Loaded saved preferences');
          }
        },
      );
    } catch (e) {
      _logger.error('Error loading saved preferences', e);
    }
  }

  /// Set preferred language and save locally.
  Future<void> setPreferredLanguage(String language) async {
    final updatedEntity = state.preferences.copyWith(primaryLanguage: language);
    state = state.copyWithPreferences(updatedEntity);
    await _savePreferences();
  }

  /// Set selected Buddhist paths and save locally.
  Future<void> setSelectedPaths(List<String> paths) async {
    final updatedEntity = state.preferences.copyWith(selectedPaths: paths);
    state = state.copyWithPreferences(updatedEntity);
    await _savePreferences();
  }

  /// Navigate to next page.
  void goToNextPage() {
    state = state.copyWithPage(state.currentPage + 1);
  }

  /// Navigate to previous page.
  void goToPreviousPage() {
    if (state.currentPage > 0) {
      state = state.copyWithPage(state.currentPage - 1);
    }
  }

  /// Save current preferences via use case.
  Future<void> _savePreferences() async {
    try {
      final result = await _saveOnboardingPreferencesUseCase(
        SavePreferencesParams(preferences: state.preferences),
      );
      result.fold(
        (failure) {
          _logger.error('Error saving preferences', failure);
          state = state.copyWithError(
            'Failed to save preferences: ${failure.message}',
          );
        },
        (_) {
          _logger.debug('Preferences saved successfully');
        },
      );
    } catch (e) {
      _logger.error('Error saving preferences', e);
      state = state.copyWithError('Failed to save preferences: $e');
    }
  }

  /// Submit preferences and mark onboarding as complete via the API.
  /// Returns true only when completion was successfully persisted.
  Future<bool> submitPreferences() async {
    state = state.copyWithLoading(true);
    try {
      final saveResult = await _saveOnboardingPreferencesUseCase(
        SavePreferencesParams(preferences: state.preferences),
      );
      saveResult.fold(
        (failure) => _logger.error('Error saving preferences', failure),
        (_) => _logger.debug('Preferences saved'),
      );

      bool completed = false;
      final completeResult = await _completeOnboardingUseCase(const NoParams());
      completeResult.fold(
        (failure) {
          _logger.error('Error completing onboarding', failure);
          state = state.copyWithError('Failed to save progress. Please try again.');
        },
        (_) {
          _logger.debug('Onboarding completed');
          completed = true;
        },
      );

      if (completed) {
        _analytics.onboardingCompleted(
          eventPlanSelected: state.preferences.enrolledEventPlanIds.isNotEmpty,
        );
        _onCompleted?.call();
      }

      state = state.copyWithLoading(false);
      return completed;
    } catch (e) {
      _logger.error('Error submitting preferences', e);
      state = state.copyWithLoading(false);
      return false;
    }
  }

  /// Records plans enrolled from the onboarding event page.
  /// Persists plan IDs to preferences and stores the full models for post-onboarding navigation.
  Future<void> setEnrolledPlans(List<UserPlansModel> plans) async {
    final planIds = plans.map((p) => p.id).toList();
    final updatedPrefs = state.preferences.copyWith(enrolledEventPlanIds: planIds);
    state = state.copyWith(preferences: updatedPrefs, enrolledPlans: plans);
    await _savePreferences();
    for (final plan in plans) {
      _analytics.eventPlanSelected(planId: plan.id, planName: plan.title);
    }
  }

  /// Clear all preferences and reset state.
  Future<void> clearPreferences() async {
    try {
      final result = await _clearOnboardingPreferencesUseCase(const NoParams());
      result.fold(
        (failure) {
          _logger.error('Error clearing preferences', failure);
        },
        (_) {
          state = OnboardingState.initial();
          _logger.debug('Preferences cleared successfully');
        },
      );
    } catch (e) {
      _logger.error('Error clearing preferences', e);
    }
  }
}
