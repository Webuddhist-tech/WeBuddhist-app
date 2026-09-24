import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

void main() {
  late RecordingAnalyticsService service;
  late GroupAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = GroupAnalytics(service);
  });

  test('groupViewed carries the group, its type and joins the sangha', () {
    analytics.groupViewed(groupId: 'g1', groupType: GroupType.page);

    expect(service.eventNames, [AnalyticsEvents.groupViewed]);
    expect(service.groups, ['sangha:g1']);
    expect(service.events.single.properties, {
      'group_id': 'g1',
      'group_type': 'page',
      'source': null,
    });
  });

  test('follow joins the sangha, unfollow does not', () {
    analytics.groupFollowed(groupId: 'g1', groupType: GroupType.community);
    analytics.groupUnfollowed(groupId: 'g1', groupType: GroupType.community);

    expect(service.eventNames, [
      AnalyticsEvents.groupFollowed,
      AnalyticsEvents.groupUnfollowed,
    ]);
    expect(service.groups, ['sangha:g1']);
    expect(service.events.last.properties, {
      'group_id': 'g1',
      'group_type': 'community',
    });
  });

  test('a personal collection opens with no group', () {
    analytics.recitationCollectionOpened(
      collectionId: 'c1',
      groupId: null,
      itemCount: 4,
    );

    expect(service.eventNames, [AnalyticsEvents.recitationCollectionOpened]);
    expect(service.groups, isEmpty);
    expect(service.events.single.properties, {
      'collection_id': 'c1',
      'group_id': null,
      'item_count': 4,
    });
  });

  test('item and collection completion carry progress and ids', () {
    analytics.recitationCollectionItemCompleted(
      collectionId: 'c1',
      textId: 't9',
      completedCount: 4,
      itemCount: 4,
    );
    analytics.recitationCollectionCompleted(collectionId: 'c1', groupId: 'g1');

    expect(service.eventNames, [
      AnalyticsEvents.recitationCollectionItemCompleted,
      AnalyticsEvents.recitationCollectionCompleted,
    ]);
    expect(service.events.first.properties, {
      'collection_id': 'c1',
      'text_id': 't9',
      'completed_count': 4,
      'item_count': 4,
    });
    expect(service.events.last.properties, {
      'collection_id': 'c1',
      'group_id': 'g1',
    });
  });
}
