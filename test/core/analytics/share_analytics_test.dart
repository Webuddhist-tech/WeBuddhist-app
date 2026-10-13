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
      'language': null,
      'format': 'image',
      'method': null,
      'group_id': null,
    });
  });

  test('contentShared carries the content language read at share time', () {
    final RecordingAnalyticsService service = RecordingAnalyticsService();
    String language = 'en';
    final ShareAnalytics analytics = ShareAnalytics(
      service,
      contentLanguage: () => language,
    );

    analytics.contentShared(surface: ShareSurface.poem, targetId: 'poem-1');
    language = 'bo';
    analytics.contentShared(surface: ShareSurface.poem, targetId: 'poem-1');

    expect(
      [for (final event in service.events) event.properties['language']],
      ['en', 'bo'],
    );
  });

  test('a failed language read still records the share', () {
    final RecordingAnalyticsService service = RecordingAnalyticsService();
    ShareAnalytics(
      service,
      contentLanguage: () => throw StateError('storage unavailable'),
    ).contentShared(surface: ShareSurface.mala, targetId: 'preset-1');

    expect(service.eventNames, [AnalyticsEvents.contentShared]);
    expect(service.events.single.properties['language'], isNull);
  });

  test('blank ids are sent as absent', () {
    final RecordingAnalyticsService service = RecordingAnalyticsService();
    ShareAnalytics(service).contentShared(
      surface: ShareSurface.post,
      targetId: 'post-1',
      groupId: '',
    );

    expect(service.events.single.properties['target_id'], 'post-1');
    expect(service.events.single.properties['group_id'], isNull);
  });

  test('new surfaces use snake_case keys', () {
    expect(
      [
        ShareSurface.post,
        ShareSurface.accumulator,
        ShareSurface.recitationCollection,
        ShareSurface.mala,
      ].map((surface) => surface.key).toList(),
      ['post', 'accumulator', 'recitation_collection', 'mala'],
    );
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
