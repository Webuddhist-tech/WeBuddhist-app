import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';

/// One captured `track` call.
class TrackedEvent {
  const TrackedEvent(this.name, this.properties);

  final String name;
  final Map<String, Object?> properties;

  @override
  String toString() => 'TrackedEvent($name, $properties)';
}

/// Records every `track` call so a test can assert on what was fired.
class RecordingAnalyticsService implements AnalyticsService {
  final List<TrackedEvent> events = [];

  /// Every `group` call as `type:key`.
  final List<String> groups = [];

  List<String> get eventNames => [for (final e in events) e.name];

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
  Future<void> track(String event, {Map<String, Object?>? properties}) async {
    events.add(TrackedEvent(event, properties ?? const {}));
  }

  @override
  Future<void> setSuperProperties(Map<String, Object?> properties) async {}

  @override
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, Object?>? properties,
  }) async {
    groups.add('$groupType:$groupKey');
  }

  @override
  List<NavigatorObserver> get routeObservers => [NavigatorObserver()];
}
