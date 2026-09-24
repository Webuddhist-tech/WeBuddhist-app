import 'dart:async';

import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

final _logger = AppLogger('Analytics');

extension AnalyticsTracking on AnalyticsService {
  /// Fire and forget: analytics never delays a user action or turns a
  /// success into a failure, so a rejected capture is only logged.
  void trackInBackground(String event, Map<String, Object?> properties) {
    unawaited(
      track(event, properties: properties).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logger.warning('Failed to track $event', error, stackTrace);
      }),
    );
  }

  /// Fire and forget, like [trackInBackground], for a group association.
  void groupInBackground({
    required String groupType,
    required String groupKey,
    Map<String, Object?>? properties,
  }) {
    unawaited(
      group(
        groupType: groupType,
        groupKey: groupKey,
        properties: properties,
      ).catchError((Object error, StackTrace stackTrace) {
        _logger.warning('Failed to set group $groupType', error, stackTrace);
      }),
    );
  }
}
