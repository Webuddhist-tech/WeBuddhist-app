import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/features/onboarding/presentation/utils/onboarding_analytics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The onboarding pages for the signed-in account, in order.
///
/// Auth0 creates a phone account with a generated display name and username,
/// so phone accounts set their own on an extra [OnboardingStep.profile] page.
/// Accounts that already finished onboarding never see it.
final onboardingStepsProvider = Provider.autoDispose<List<OnboardingStep>>((
  ref,
) {
  // Stored before auth state flips, so it is set by the time onboarding opens.
  final userId = SharedPreferencesService.instance.getSync<String>(
    StorageKeys.currentUserId,
  );
  return onboardingStepsFor(userId);
});

/// [userId] is the Auth0 `sub`; SMS logins have the form `sms|<id>`.
List<OnboardingStep> onboardingStepsFor(String? userId) {
  final isPhoneAccount = userId?.startsWith('sms|') ?? false;
  return [
    OnboardingStep.welcome,
    if (isPhoneAccount) OnboardingStep.profile,
    OnboardingStep.language,
    OnboardingStep.tradition,
    OnboardingStep.finish,
  ];
}
