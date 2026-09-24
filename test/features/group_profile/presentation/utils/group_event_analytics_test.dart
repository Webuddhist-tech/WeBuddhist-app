import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_analytics.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_link_utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

void main() {
  late RecordingAnalyticsService service;
  late GroupEventAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = GroupEventAnalytics(service);
  });

  test('eventViewed carries the event, its group and format', () {
    analytics.eventViewed(
      eventId: 'e1',
      groupId: 'g1',
      eventTitle: 'Tara Feast Offerings',
      eventFormat: 'hybrid',
      isRecurring: true,
    );

    expect(service.eventNames, [AnalyticsEvents.groupEventViewed]);
    expect(service.events.single.properties, {
      'event_id': 'e1',
      'group_id': 'g1',
      'event_title': 'Tara Feast Offerings',
      'event_format': 'hybrid',
      'is_recurring': true,
    });
  });

  test('attending a single-format event has no participation', () {
    analytics.eventAttended(eventId: 'e1', groupId: 'g1', participation: null);

    expect(service.events.single.properties, {
      'event_id': 'e1',
      'group_id': 'g1',
      'participation': null,
    });
  });

  test('participation is reported by its API value', () {
    analytics.eventParticipationChanged(
      eventId: 'e1',
      groupId: 'g1',
      participation: GroupEventParticipationType.offline,
    );
    analytics.eventLiveEntered(
      eventId: 'e1',
      groupId: 'g1',
      participation: GroupEventParticipationType.online,
      target: GroupEventLiveTarget.series,
    );

    expect(service.eventNames, [
      AnalyticsEvents.groupEventParticipationChanged,
      AnalyticsEvents.groupEventLiveEntered,
    ]);
    expect(service.events.first.properties['participation'], 'offline');
    expect(service.events.last.properties, {
      'event_id': 'e1',
      'group_id': 'g1',
      'participation': 'online',
      'target': 'series',
    });
  });

  test('leave and link open fire their own events', () {
    analytics.eventLeft(eventId: 'e1', groupId: 'g1');
    analytics.eventLinkOpened(eventId: 'e1', kind: GroupEventLinkKind.meeting);

    expect(service.eventNames, [
      AnalyticsEvents.groupEventLeft,
      AnalyticsEvents.groupEventLinkOpened,
    ]);
    expect(service.events.last.properties, {
      'event_id': 'e1',
      'link_type': 'meeting',
    });
  });
}
