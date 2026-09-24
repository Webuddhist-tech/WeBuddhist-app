import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/clarity_screen_observer.dart';
import 'package:flutter_pecha/core/analytics/clarity_screen_tracker.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/env.dart';

final _logger = AppLogger('ClarityAnalytics');

/// Microsoft Clarity session recordings and heatmaps. [wrap] starts the SDK
/// with the first frame; the route observers keep its screen name current.
class ClarityAnalyticsService implements AnalyticsService {
  ClarityAnalyticsService._();

  static ClarityAnalyticsService? _instance;
  static ClarityAnalyticsService get instance =>
      _instance ??= ClarityAnalyticsService._();

  static bool get isEnabled {
    final String? projectId = Env.clarityProjectId;
    return Env.clarityEnabled && projectId != null && projectId.isNotEmpty;
  }

  final ClarityScreenTracker _screenTracker = ClarityScreenTracker(
    onScreenChanged: Clarity.setCurrentScreenName,
  );

  /// Wraps the app so Clarity records from the first frame. Returns [app]
  /// untouched when the project ID is missing or invalid.
  static Widget wrap(Widget app) {
    final String? projectId = Env.clarityProjectId;
    if (!Env.clarityEnabled || projectId == null || projectId.isEmpty) {
      _logger.info('Clarity disabled — CLARITY_PROJECT_ID not set');
      return app;
    }

    final ClarityConfig config = ClarityConfig(
      projectId: projectId,
      logLevel: Env.isDebug ? LogLevel.Info : LogLevel.None,
    );
    if (!config.isProjectIdValid()) {
      _logger.warning('CLARITY_PROJECT_ID is not a valid Clarity project id');
      return app;
    }

    // Buffered by the SDK and attached once the session starts.
    Clarity.setCustomTag('environment', Env.environment);
    Clarity.setCustomTag('app_flavor', Env.appFlavor);
    _logger.info('Clarity enabled for ${Env.appFlavor}');
    return ClarityWidget(app: app, clarityConfig: config);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object?>? properties,
  }) async {
    Clarity.setCustomUserId(userId);
    if (properties != null) await setSuperProperties(properties);
  }

  /// Clarity sessions are device scoped and cannot be reset; the next launch
  /// starts a fresh session.
  @override
  Future<void> reset() async {}

  @override
  Future<void> track(String event, {Map<String, Object?>? properties}) async {
    Clarity.sendCustomEvent(event);
  }

  @override
  Future<void> setSuperProperties(Map<String, Object?> properties) async {
    for (final MapEntry<String, Object?> entry in properties.entries) {
      final Object? value = entry.value;
      if (value == null) continue;
      Clarity.setCustomTag(entry.key, value.toString());
    }
  }

  @override
  List<NavigatorObserver> get routeObservers => [
    ClarityScreenObserver(_screenTracker),
  ];

  /// Bottom tab shown by the home shell; tabs are not routes, so the shell's
  /// screen name comes from here.
  void setTab(String tab) => _screenTracker.setTab(tab);
}
