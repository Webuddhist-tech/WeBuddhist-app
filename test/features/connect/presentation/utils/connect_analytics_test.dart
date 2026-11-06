import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

void main() {
  late RecordingAnalyticsService service;
  late ConnectAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = ConnectAnalytics(service);
  });

  test('tabViewed carries the sub-tab and the followed count', () {
    analytics.tabViewed(subTab: 'events', followedGroupCount: 3);

    expect(service.eventNames, [AnalyticsEvents.connectTabViewed]);
    expect(service.events.single.properties, {
      'sub_tab': 'events',
      'followed_group_count': 3,
    });
  });

  test('the followed count is null until my groups have loaded', () {
    analytics.tabViewed(subTab: 'feed', followedGroupCount: null);

    expect(service.events.single.properties, {
      'sub_tab': 'feed',
      'followed_group_count': null,
    });
  });

  group('post events', () {
    const placement = ConnectPostPlacement(
      surface: ConnectPostSurface.homePreview,
      position: 2,
    );
    const youtube = ConnectPostLink(
      id: 'l1',
      type: 'YOUTUBE',
      url: 'https://youtu.be/dQw4w9WgXcQ',
    );
    const website = ConnectPostLink(
      id: 'l2',
      type: 'WEBSITE',
      url: 'https://example.com/private-path',
    );
    const post = ConnectPost(
      id: 'p1',
      groupId: 'g1',
      caption: 'A caption that must never be sent',
      status: 'PUBLISHED',
      creatorName: 'A creator that must never be sent',
      media: [ConnectPostMedia(id: 'm1', mediaType: 'IMAGE', url: 'u')],
      links: [youtube, website],
    );
    const placedProperties = {
      'post_id': 'p1',
      'group_id': 'g1',
      'has_media': true,
      'link_type': 'youtube',
      'position': 2,
      'surface': 'home_preview',
    };

    test('viewed and opened carry the post and where it sits', () {
      analytics.postViewed(post: post, placement: placement);
      analytics.postOpened(post: post, placement: placement);

      expect(service.eventNames, [
        AnalyticsEvents.postViewed,
        AnalyticsEvents.postOpened,
      ]);
      expect(service.events.first.properties, placedProperties);
      expect(service.events.last.properties, placedProperties);
    });

    test('a link open names the tapped link, not its URL', () {
      analytics.postLinkOpened(post: post, placement: placement, link: website);

      expect(service.eventNames, [AnalyticsEvents.postLinkOpened]);
      expect(service.events.single.properties, {
        ...placedProperties,
        'link_type': 'website',
      });
    });

    test('a post with no media or links says so', () {
      const plain = ConnectPost(
        id: 'p2',
        groupId: 'g1',
        caption: '',
        status: 'PUBLISHED',
        creatorName: '',
      );

      analytics.postViewed(post: plain, placement: placement);

      expect(service.events.single.properties['has_media'], isFalse);
      expect(service.events.single.properties['link_type'], isNull);
    });

    test('a created post uses the group it was published to', () {
      analytics.groupPostCreated(post: post, groupId: 'g9');

      expect(service.eventNames, [AnalyticsEvents.groupPostCreated]);
      expect(service.events.single.properties, {
        'post_id': 'p1',
        'group_id': 'g9',
        'has_media': true,
        'link_type': 'youtube',
      });
    });

    test('the view tracker reports each post once per visit', () {
      final tracker = ConnectPostViewTracker();

      expect(tracker.markViewed('p1'), isTrue);
      expect(tracker.markViewed('p1'), isFalse);
      expect(tracker.markViewed('p2'), isTrue);
      expect(ConnectPostViewTracker().markViewed('p1'), isTrue);
    });

    test('every surface has a snake_case key', () {
      for (final surface in ConnectPostSurface.values) {
        expect(surface.key, matches(RegExp(r'^[a-z_]+$')));
      }
    });
  });
}
