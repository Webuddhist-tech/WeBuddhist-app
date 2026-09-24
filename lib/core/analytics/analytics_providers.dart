import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/clarity_analytics_service.dart';
import 'package:flutter_pecha/core/analytics/composite_analytics_service.dart';
import 'package:flutter_pecha/core/analytics/posthog_analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton analytics service: PostHog (or no-op) plus Clarity when enabled.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final AnalyticsService posthog = PostHogAnalyticsService.create();
  if (!ClarityAnalyticsService.isEnabled) return posthog;
  return CompositeAnalyticsService([posthog, ClarityAnalyticsService.instance]);
});
