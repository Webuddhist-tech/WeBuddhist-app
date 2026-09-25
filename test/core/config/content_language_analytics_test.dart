import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/config/locale/content_language_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../analytics/recording_analytics_service.dart';

void main() {
  late RecordingAnalyticsService service;
  late ContentLanguageAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = ContentLanguageAnalytics(service);
  });

  test('contentLanguageChanged carries both codes and the source', () {
    analytics.contentLanguageChanged(
      from: 'en',
      to: 'bo',
      source: ContentLanguageSource.settings,
    );

    expect(service.eventNames, [AnalyticsEvents.contentLanguageChanged]);
    expect(service.events.single.properties, {
      'from': 'en',
      'to': 'bo',
      'source': 'settings',
    });
  });

  test('an unknown source is sent as null', () {
    analytics.contentLanguageChanged(from: 'en', to: 'zh');

    expect(service.events.single.properties['source'], isNull);
  });
}
