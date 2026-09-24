import 'package:flutter/widgets.dart';

/// Product analytics abstraction. Features depend on this interface, not PostHog.
abstract class AnalyticsService {
  Future<void> initialize();

  Future<void> identify({
    required String userId,
    Map<String, Object?>? properties,
  });

  Future<void> reset();

  Future<void> track(String event, {Map<String, Object?>? properties});

  Future<void> setSuperProperties(Map<String, Object?> properties);

  /// Ties this device's later events to a group (a sangha) so dashboards
  /// can be cut per group.
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, Object?>? properties,
  });

  /// Fresh observers for one navigator; wired into the root and shell
  /// navigators so screen transitions are tracked.
  List<NavigatorObserver> get routeObservers;
}
