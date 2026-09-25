import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/notifications/presentation/utils/notification_settings_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/analytics/recording_analytics_service.dart';

void main() {
  late RecordingAnalyticsService service;
  late NotificationSettingsAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = NotificationSettingsAnalytics(service);
  });

  test('settingChanged names the toggle and its new value', () {
    analytics.settingChanged(
      setting: NotificationSetting.master,
      enabled: false,
    );
    analytics.settingChanged(
      setting: NotificationSetting.recitation,
      enabled: true,
    );

    expect(service.eventNames, [
      AnalyticsEvents.notificationSettingChanged,
      AnalyticsEvents.notificationSettingChanged,
    ]);
    expect(service.events.first.properties, {
      'setting': 'master',
      'enabled': false,
    });
    expect(service.events.last.properties, {
      'setting': 'recitation',
      'enabled': true,
    });
  });
}
