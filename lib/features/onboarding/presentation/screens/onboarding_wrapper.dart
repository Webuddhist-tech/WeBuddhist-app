import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_steps_provider.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_1.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_profile.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_tradition.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_5.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_language.dart';
import 'package:flutter_pecha/features/onboarding/presentation/utils/onboarding_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Wrapper for onboarding screens with Riverpod state management.
/// Page order comes from [onboardingStepsProvider]:
///   Welcome → (Profile, phone accounts only) → Language → Tradition →
///   Finish / "You're all set"
class OnboardingWrapper extends ConsumerStatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper> {
  final PageController _pageController = PageController();

  /// Fixed for the life of the flow so pages never shift under the user.
  late final List<OnboardingStep> _steps;

  /// The steps with a progress bar: all but Welcome and Finish.
  late final List<OnboardingStep> _progressSteps;

  @override
  void initState() {
    super.initState();
    _steps = ref.read(onboardingStepsProvider);
    _progressSteps =
        _steps
            .where(
              (s) => s != OnboardingStep.welcome && s != OnboardingStep.finish,
            )
            .toList();
    final analytics = ref.read(onboardingAnalyticsProvider);
    analytics.onboardingStarted();
    _trackStepViewed(ref.read(onboardingProvider).currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _trackStepViewed(int page) {
    if (page < 0 || page >= _steps.length) return;
    ref
        .read(onboardingAnalyticsProvider)
        .stepViewed(step: _steps[page], stepIndex: page);
  }

  /// Advances only while [page] is still the current page, so a double tap
  /// (or a callback that lands mid-animation) cannot skip the next step.
  VoidCallback _nextFrom(int page) => () {
    if (ref.read(onboardingProvider).currentPage != page) return;
    ref.read(onboardingProvider.notifier).goToNextPage();
  };

  VoidCallback _previousFrom(int page) => () {
    if (ref.read(onboardingProvider).currentPage != page) return;
    ref.read(onboardingProvider.notifier).goToPreviousPage();
  };

  Future<void> _completeOnboarding() async {
    final completed =
        await ref.read(onboardingProvider.notifier).submitPreferences();
    if (!mounted || !completed) return;

    if (mounted) context.go(AppRoutes.home);
  }

  Widget _buildPage(int page) {
    final step = _steps[page];
    final progressIndex = _progressSteps.indexOf(step);
    final progressCount = _progressSteps.length;
    return switch (step) {
      OnboardingStep.welcome => OnboardingScreen1(onNext: _nextFrom(page)),
      OnboardingStep.profile => OnboardingScreenProfile(
        onNext: _nextFrom(page),
        stepIndex: progressIndex,
        stepCount: progressCount,
      ),
      OnboardingStep.language => OnboardingScreenLanguage(
        onNext: _nextFrom(page),
        stepIndex: progressIndex,
        stepCount: progressCount,
      ),
      OnboardingStep.tradition => OnboardingScreenTradition(
        onNext: _nextFrom(page),
        onBack: _previousFrom(page),
        stepIndex: progressIndex,
        stepCount: progressCount,
      ),
      OnboardingStep.finish => OnboardingScreen5(
        onComplete: _completeOnboarding,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(
      onboardingProvider.select((state) => state.currentPage),
    );

    ref.listen<int>(onboardingProvider.select((state) => state.currentPage), (
      previous,
      next,
    ) {
      if (previous != next) _trackStepViewed(next);
      if (_pageController.hasClients && previous != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (int page) {
              if (page != currentPage) {
                if (page > currentPage) {
                  ref.read(onboardingProvider.notifier).goToNextPage();
                } else {
                  ref.read(onboardingProvider.notifier).goToPreviousPage();
                }
              }
            },
            children: [
              for (var page = 0; page < _steps.length; page++) _buildPage(page),
            ],
          ),
        ],
      ),
    );
  }
}
