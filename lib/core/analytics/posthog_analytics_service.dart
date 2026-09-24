import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/no_op_analytics_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/env.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

final _logger = AppLogger('PostHogAnalytics');

/// Property keys blanked before an event leaves the device.
const List<String> _redactedKeys = [
  'email',
  'id_token',
  'access_token',
  'phone',
  'name',
  'username',
];

/// PostHog-backed analytics. Initialized manually after dotenv is loaded.
class PostHogAnalyticsService implements AnalyticsService {
  PostHogAnalyticsService._();

  static PostHogAnalyticsService? _instance;
  static PostHogAnalyticsService get instance =>
      _instance ??= PostHogAnalyticsService._();

  bool _isInitialized = false;

  static AnalyticsService create() {
    if (!Env.posthogEnabled) {
      _logger.info('PostHog disabled — using no-op analytics');
      return const NoOpAnalyticsService();
    }
    return PostHogAnalyticsService.instance;
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized || !Env.posthogEnabled) return;

    final String? apiKey = Env.posthogApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      _logger.warning('POSTHOG_API_KEY missing — analytics disabled');
      return;
    }

    final PostHogConfig config = PostHogConfig(apiKey);
    config.host = Env.posthogHost;
    config.debug = Env.isDebug;
    config.personProfiles = PostHogPersonProfiles.identifiedOnly;
    config.beforeSend = [_redactPii];

    if (kReleaseMode) {
      config.sessionReplay = true;
      config.sessionReplayConfig.maskAllTexts = true;
      // Avatars, banners and user uploads must not reach replay.
      config.sessionReplayConfig.maskAllImages = true;
    }

    await Posthog().setup(config);
    await _registerDefaultSuperProperties();

    _isInitialized = true;
    _logger.info('PostHog initialized for ${Env.appFlavor}');
  }

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object?>? properties,
  }) async {
    if (!_isInitialized) return;

    await Posthog().identify(
      userId: userId,
      userProperties: _sanitizeProperties(properties),
    );
  }

  @override
  Future<void> reset() async {
    if (!_isInitialized) return;

    await Posthog().reset();
    await _registerDefaultSuperProperties();
  }

  @override
  Future<void> track(
    String event, {
    Map<String, Object?>? properties,
  }) async {
    if (!_isInitialized) return;

    await Posthog().capture(
      eventName: event,
      properties: _sanitizeProperties(properties),
    );
  }

  @override
  Future<void> setSuperProperties(Map<String, Object?> properties) async {
    if (!_isInitialized) return;

    for (final MapEntry<String, Object?> entry in properties.entries) {
      final Object? value = entry.value;
      if (value != null) {
        await Posthog().register(entry.key, value);
      }
    }
  }

  @override
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, Object?>? properties,
  }) async {
    if (!_isInitialized) return;

    await Posthog().group(
      groupType: groupType,
      groupKey: groupKey,
      groupProperties: _sanitizeProperties(properties),
    );
  }

  @override
  List<NavigatorObserver> get routeObservers => [PosthogObserver()];

  /// Session replay only records inside [PostHogWidget]; it must mount after
  /// [initialize], which main() guarantees. Returns [child] untouched when
  /// PostHog is off.
  static Widget wrap(Widget child) {
    if (!Env.posthogEnabled) return child;
    return PostHogWidget(child: child);
  }

  Future<void> _registerDefaultSuperProperties() async {
    PackageInfo? packageInfo;
    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (_) {
      // Unavailable in test environments — version properties skipped.
    }

    await setSuperProperties({
      'environment': Env.environment,
      'app_flavor': Env.appFlavor,
      'platform': Platform.operatingSystem,
      if (packageInfo != null) 'app_version': packageInfo.version,
      if (packageInfo != null) 'build_number': packageInfo.buildNumber,
    });
  }

  static Map<String, Object>? _sanitizeProperties(
    Map<String, Object?>? properties,
  ) {
    if (properties == null || properties.isEmpty) {
      return null;
    }

    final Map<String, Object> sanitized = <String, Object>{};
    for (final MapEntry<String, Object?> entry in properties.entries) {
      final Object? value = entry.value;
      if (value != null) {
        sanitized[entry.key] = value;
      }
    }
    return sanitized.isEmpty ? null : sanitized;
  }

  static PostHogEvent? _redactPii(PostHogEvent event) {
    final Map<String, Object>? properties = event.properties;
    if (properties == null) {
      return event;
    }

    for (final String key in _redactedKeys) {
      if (properties.containsKey(key)) {
        properties[key] = '***';
      }
    }

    return event;
  }
}
