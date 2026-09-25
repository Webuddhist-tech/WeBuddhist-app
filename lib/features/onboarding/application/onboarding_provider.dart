import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_notifier.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_state.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/onboarding/presentation/utils/onboarding_analytics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider for onboarding state management
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier(
        loadSavedPreferencesUseCase:
            ref.read(loadSavedPreferencesUseCaseProvider),
        saveOnboardingPreferencesUseCase:
            ref.read(saveOnboardingPreferencesUseCaseProvider),
        completeOnboardingUseCase:
            ref.read(completeOnboardingUseCaseProvider),
        clearOnboardingPreferencesUseCase:
            ref.read(clearOnboardingPreferencesUseCaseProvider),
        analytics: ref.read(onboardingAnalyticsProvider),
        onCompleted: () => ref.read(authProvider.notifier).markOnboardingCompleted(),
      );
    });
