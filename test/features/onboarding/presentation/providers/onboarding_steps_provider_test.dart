import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_steps_provider.dart';
import 'package:flutter_pecha/features/onboarding/presentation/utils/onboarding_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a phone account sets its name after the welcome page', () {
    expect(onboardingStepsFor('sms|65f0c1d2e3'), [
      OnboardingStep.welcome,
      OnboardingStep.profile,
      OnboardingStep.language,
      OnboardingStep.tradition,
      OnboardingStep.finish,
    ]);
  });

  test('other accounts skip the profile page', () {
    for (final userId in ['google-oauth2|1', 'apple|1', 'auth0|1', null]) {
      expect(
        onboardingStepsFor(userId),
        isNot(contains(OnboardingStep.profile)),
        reason: '$userId',
      );
    }
  });
}
