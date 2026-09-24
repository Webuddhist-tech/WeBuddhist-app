import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';

/// No-op analytics used when PostHog is disabled or not configured.
class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object?>? properties,
  }) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> track(
    String event, {
    Map<String, Object?>? properties,
  }) async {}

  @override
  Future<void> setSuperProperties(Map<String, Object?> properties) async {}

  @override
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, Object?>? properties,
  }) async {}

  @override
  List<NavigatorObserver> get routeObservers => const [];
}
