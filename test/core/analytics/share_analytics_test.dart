import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import 'recording_analytics_service.dart';

void main() {
  test('contentShared names the surface in snake_case', () {
    final RecordingAnalyticsService service = RecordingAnalyticsService();
    ShareAnalytics(service).contentShared(
      surface: ShareSurface.planDay,
      targetId: 'p1',
      format: 'image',
    );

    expect(service.eventNames, [AnalyticsEvents.contentShared]);
    expect(service.events.single.properties, {
      'surface': 'plan_day',
      'target_id': 'p1',
      'format': 'image',
      'method': null,
    });
  });

  test('only a confirmed share counts', () {
    expect(
      ShareAnalytics.wasUsed(const ShareResult('', ShareResultStatus.success)),
      isTrue,
    );
    expect(
      ShareAnalytics.wasUsed(
        const ShareResult('', ShareResultStatus.unavailable),
      ),
      isFalse,
    );
    expect(
      ShareAnalytics.wasUsed(
        const ShareResult('', ShareResultStatus.dismissed),
      ),
      isFalse,
    );
  });
}
