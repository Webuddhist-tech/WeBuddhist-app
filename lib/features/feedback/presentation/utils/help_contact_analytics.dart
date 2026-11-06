import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/help_topic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What opened Help & contact, carried as `source`.
enum HelpContactSource {
  settings,
  homePrompt;

  String get key => switch (this) {
    HelpContactSource.settings => 'settings',
    HelpContactSource.homePrompt => 'home_prompt',
  };
}

/// Product analytics for Help & contact, the one form that takes problems,
/// ideas, content suggestions and offers to help: one method per tracked
/// action, so the event names and their property keys live in one place. Every
/// call fires and forgets. The message itself is never sent.
class HelpContactAnalytics {
  const HelpContactAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// A signed-in user is taken to the form. Guests get the login drawer
  /// instead, which `login_prompt_shown` already counts. [topic] is the one
  /// the form opens with, if any.
  void opened({required HelpContactSource source, HelpTopic? topic}) {
    _analytics.trackInBackground(AnalyticsEvents.helpContactOpened, {
      AnalyticsProperties.source: source.key,
      AnalyticsProperties.topic: topic?.slug,
    });
  }

  /// The server accepted the message. [topic] is null when none was picked.
  void messageSent({required HelpTopic? topic, required int imageCount}) {
    _analytics.trackInBackground(AnalyticsEvents.helpMessageSent, {
      AnalyticsProperties.topic: topic?.slug,
      AnalyticsProperties.imageCount: imageCount,
    });
  }
}

final helpContactAnalyticsProvider = Provider<HelpContactAnalytics>((ref) {
  return HelpContactAnalytics(ref.watch(analyticsServiceProvider));
});
