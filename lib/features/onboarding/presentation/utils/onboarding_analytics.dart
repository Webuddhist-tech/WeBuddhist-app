import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The onboarding pages in the order the wrapper shows them. [profile] is
/// shown to phone accounts only.
enum OnboardingStep {
  welcome,
  profile,
  language,
  tradition,
  finish;

  String get key => name;
}

/// Product analytics for onboarding: one method per tracked action, so the
/// event names and their property keys live in one place. Every call fires
/// and forgets; callers fire after the action happened, never optimistically.
///
/// One instance lives for the whole flow, so it carries what
/// `onboarding_completed` needs from earlier pages: when the flow started and
/// how many traditions were chosen.
class OnboardingAnalytics {
  OnboardingAnalytics(this._analytics, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AnalyticsService _analytics;
  final DateTime Function() _now;
  DateTime? _startedAt;
  int _traditionsCount = 0;

  /// The first onboarding page is on screen.
  void onboardingStarted() {
    _startedAt = _now();
    _traditionsCount = 0;
    _analytics.trackInBackground(AnalyticsEvents.onboardingStarted, const {});
  }

  /// [stepIndex] is the wrapper's page index. Phone accounts get an extra
  /// page, so the same index can name different steps; [step] says which.
  void stepViewed({required OnboardingStep step, required int stepIndex}) {
    _analytics.trackInBackground(AnalyticsEvents.onboardingStepViewed, {
      AnalyticsProperties.step: step.key,
      AnalyticsProperties.stepIndex: stepIndex,
    });
  }

  /// [uiLanguage] is the language code the app switched to.
  void languageSelected({required String uiLanguage}) {
    _analytics.trackInBackground(AnalyticsEvents.onboardingLanguageSelected, {
      AnalyticsProperties.uiLanguage: uiLanguage,
    });
  }

  /// No event: remembered for `onboarding_completed`. Only how many, never
  /// which traditions.
  void traditionsChosen({required int count}) {
    _traditionsCount = count;
  }

  void eventPlanSelected({required String planId, required String planName}) {
    _analytics.trackInBackground(AnalyticsEvents.onboardingEventPlanSelected, {
      AnalyticsProperties.planId: planId,
      AnalyticsProperties.planName: planName,
    });
  }

  /// Onboarding was marked complete on the server. `duration_ms` is null when
  /// this instance never saw the flow start.
  void onboardingCompleted({required bool eventPlanSelected}) {
    final startedAt = _startedAt;
    _analytics.trackInBackground(AnalyticsEvents.onboardingCompleted, {
      AnalyticsProperties.durationMs:
          startedAt == null
              ? null
              : _now().difference(startedAt).inMilliseconds,
      AnalyticsProperties.traditionsCount: _traditionsCount,
      AnalyticsProperties.eventPlanSelected: eventPlanSelected,
    });
  }
}

final onboardingAnalyticsProvider = Provider<OnboardingAnalytics>((ref) {
  return OnboardingAnalytics(ref.watch(analyticsServiceProvider));
});
