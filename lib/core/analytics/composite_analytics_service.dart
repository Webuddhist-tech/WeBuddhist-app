import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

final _logger = AppLogger('CompositeAnalytics');

/// Fans every call out to each backend so features keep depending on one
/// [AnalyticsService]. A failing backend never blocks the others.
class CompositeAnalyticsService implements AnalyticsService {
  const CompositeAnalyticsService(this._services);

  final List<AnalyticsService> _services;

  @override
  Future<void> initialize() => _each((service) => service.initialize());

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object?>? properties,
  }) => _each(
    (service) => service.identify(userId: userId, properties: properties),
  );

  @override
  Future<void> reset() => _each((service) => service.reset());

  @override
  Future<void> track(String event, {Map<String, Object?>? properties}) =>
      _each((service) => service.track(event, properties: properties));

  @override
  Future<void> setSuperProperties(Map<String, Object?> properties) =>
      _each((service) => service.setSuperProperties(properties));

  @override
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, Object?>? properties,
  }) => _each(
    (service) => service.group(
      groupType: groupType,
      groupKey: groupKey,
      properties: properties,
    ),
  );

  @override
  List<NavigatorObserver> get routeObservers => [
    for (final service in _services) ...service.routeObservers,
  ];

  Future<void> _each(Future<void> Function(AnalyticsService) call) async {
    for (final service in _services) {
      try {
        await call(service);
      } catch (e) {
        _logger.warning('${service.runtimeType} call failed: $e');
      }
    }
  }
}
