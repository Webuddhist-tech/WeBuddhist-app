import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_unified_feed_providers.dart';
import 'package:flutter_pecha/features/home/presentation/providers/home_community_feed_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const _item = ConnectFeedItem(
  type: ConnectFeedItemType.post,
  groupId: 'g1',
  groupName: 'Group',
);

void main() {
  group('resolveHomeCommunityFeed', () {
    test('guests always get Discover', () {
      expect(
        resolveHomeCommunityFeed(
          isMember: false,
          myFeed: const UnifiedConnectFeedState(feedItems: [_item]),
        ),
        HomeCommunityFeed.discover,
      );
    });

    test('a member with followed-group cards gets their own feed', () {
      expect(
        resolveHomeCommunityFeed(
          isMember: true,
          myFeed: const UnifiedConnectFeedState(
            feedItems: [_item],
            isLoading: true,
            hasLoaded: true,
          ),
        ),
        HomeCommunityFeed.my,
      );
    });

    test('waits while the member feed has not loaded yet', () {
      expect(
        resolveHomeCommunityFeed(
          isMember: true,
          myFeed: const UnifiedConnectFeedState(),
        ),
        isNull,
      );
      expect(
        resolveHomeCommunityFeed(
          isMember: true,
          myFeed: const UnifiedConnectFeedState(
            isLoading: true,
            hasLoaded: true,
          ),
        ),
        isNull,
      );
    });

    test('a failed, empty member feed does not fall back to Discover', () {
      expect(
        resolveHomeCommunityFeed(
          isMember: true,
          myFeed: const UnifiedConnectFeedState(
            hasLoaded: true,
            error: 'offline',
          ),
        ),
        isNull,
      );
    });

    test('a member who follows nothing falls back to Discover', () {
      expect(
        resolveHomeCommunityFeed(
          isMember: true,
          myFeed: const UnifiedConnectFeedState(hasLoaded: true),
        ),
        HomeCommunityFeed.discover,
      );
    });
  });

  test('each feed keeps likes in the list it came from', () {
    expect(HomeCommunityFeed.my.includeUnfollowed, isFalse);
    expect(HomeCommunityFeed.discover.includeUnfollowed, isTrue);
    expect(HomeCommunityFeed.my.provider, same(myUnifiedConnectFeedProvider));
    expect(
      HomeCommunityFeed.discover.provider,
      same(discoverUnifiedConnectFeedProvider),
    );
  });
}
