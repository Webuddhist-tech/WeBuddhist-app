import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_1.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_2.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_tradition.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_5.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_language.dart';
import 'package:flutter_pecha/features/onboarding/presentation/utils/onboarding_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Wrapper for onboarding screens with Riverpod state management.
/// Page order:
///   0 – Language selection
///   1 – Welcome
///   2 – Tradition selection
///   3 – How it works
///   4 – Finish / "Begin Your Practice"
class OnboardingWrapper extends ConsumerStatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    final analytics = ref.read(onboardingAnalyticsProvider);
    analytics.onboardingStarted();
    analytics.stepViewed(stepIndex: ref.read(onboardingProvider).currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    ref.read(onboardingProvider.notifier).goToNextPage();
  }

  void _previousPage() {
    ref.read(onboardingProvider.notifier).goToPreviousPage();
  }

  Future<void> _completeOnboarding() async {
    final completed =
        await ref.read(onboardingProvider.notifier).submitPreferences();
    if (!mounted || !completed) return;

    if (mounted) context.go(AppRoutes.home);
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
      if (previous != next) {
        ref.read(onboardingAnalyticsProvider).stepViewed(stepIndex: next);
      }
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
              OnboardingScreenLanguage(onNext: _nextPage),
              OnboardingScreen1(onNext: _nextPage),
              OnboardingScreenTradition(
                onNext: _nextPage,
                onBack: _previousPage,
              ),
              OnboardingScreen2(onNext: _nextPage, onBack: _previousPage),
              OnboardingScreen5(onComplete: _completeOnboarding),
            ],
          ),
        ],
      ),
    );
  }
}
