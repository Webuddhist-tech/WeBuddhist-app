import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/onboarding/presentation/utils/onboarding_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

void main() {
  late RecordingAnalyticsService service;
  late DateTime now;
  late OnboardingAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    now = DateTime(2026, 9, 24, 10);
    analytics = OnboardingAnalytics(service, now: () => now);
  });

  test('onboardingStarted has no properties', () {
    analytics.onboardingStarted();

    expect(service.eventNames, [AnalyticsEvents.onboardingStarted]);
    expect(service.events.single.properties, isEmpty);
  });

  test('stepViewed names the page by its wrapper index', () {
    analytics.stepViewed(stepIndex: 0);
    analytics.stepViewed(stepIndex: 3);

    expect(service.eventNames, [
      AnalyticsEvents.onboardingStepViewed,
      AnalyticsEvents.onboardingStepViewed,
    ]);
    expect(service.events.first.properties, {
      'step': 'language',
      'step_index': 0,
    });
    expect(service.events.last.properties, {
      'step': 'how_it_works',
      'step_index': 3,
    });
  });

  test('a page the wrapper does not know sends only its index', () {
    analytics.stepViewed(stepIndex: 9);

    expect(service.events.single.properties, {'step': null, 'step_index': 9});
  });

  test('every wrapper page has a snake_case key', () {
    for (final step in OnboardingStep.values) {
      expect(step.key, matches(RegExp(r'^[a-z_]+$')));
    }
  });

  test('languageSelected carries the language code', () {
    analytics.languageSelected(uiLanguage: 'bo');

    expect(service.eventNames, [AnalyticsEvents.onboardingLanguageSelected]);
    expect(service.events.single.properties, {'ui_language': 'bo'});
  });

  test('eventPlanSelected names the plan', () {
    analytics.eventPlanSelected(planId: 'p1', planName: 'Daily Tipitaka');

    expect(service.eventNames, [AnalyticsEvents.onboardingEventPlanSelected]);
    expect(service.events.single.properties, {
      'plan_id': 'p1',
      'plan_name': 'Daily Tipitaka',
    });
  });

  test('onboardingCompleted measures from the start and counts traditions', () {
    analytics.onboardingStarted();
    analytics.traditionsChosen(count: 1);
    now = now.add(const Duration(seconds: 42));

    analytics.onboardingCompleted(eventPlanSelected: true);

    expect(service.events.last.name, AnalyticsEvents.onboardingCompleted);
    expect(service.events.last.properties, {
      'duration_ms': 42000,
      'traditions_count': 1,
      'event_plan_selected': true,
    });
  });

  test('completing without a seen start has no duration', () {
    analytics.onboardingCompleted(eventPlanSelected: false);

    expect(service.events.single.properties, {
      'duration_ms': null,
      'traditions_count': 0,
      'event_plan_selected': false,
    });
  });

  test('a new start forgets the previous traditions count', () {
    analytics.onboardingStarted();
    analytics.traditionsChosen(count: 1);
    analytics.onboardingStarted();
    analytics.onboardingCompleted(eventPlanSelected: false);

    expect(service.events.last.properties['traditions_count'], 0);
  });
}
