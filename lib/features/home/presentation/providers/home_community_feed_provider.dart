import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_unified_feed_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which Connect feed Home's "From the community" shows.
enum HomeCommunityFeed {
  /// Posts, events and practices from the groups the member follows.
  my,

  /// Everything public, for guests and members whose own feed is empty.
  discover;

  bool get includeUnfollowed => this == discover;

  AutoDisposeStateNotifierProvider<
    UnifiedConnectFeedNotifier,
    UnifiedConnectFeedState
  >
  get provider => switch (this) {
    my => myUnifiedConnectFeedProvider,
    discover => discoverUnifiedConnectFeedProvider,
  };
}

/// Home shows the member's own feed and falls back to Discover once that has
/// loaded empty; guests always get Discover. Null while the member's feed is
/// still on its first load, and while it has failed with nothing to show.
HomeCommunityFeed? resolveHomeCommunityFeed({
  required bool isMember,
  required UnifiedConnectFeedState myFeed,
}) {
  if (!isMember) return HomeCommunityFeed.discover;
  final myIsEmpty = myFeed.feedItems.isEmpty && myFeed.practices.isEmpty;
  if (!myIsEmpty) return HomeCommunityFeed.my;
  if (!myFeed.hasLoaded || myFeed.isLoading || myFeed.error != null) {
    return null;
  }
  return HomeCommunityFeed.discover;
}

final homeCommunityFeedProvider = Provider.autoDispose<HomeCommunityFeed?>((
  ref,
) {
  final isMember = ref.watch(
    authProvider.select((auth) => auth.isLoggedIn && !auth.isGuest),
  );
  if (!isMember) return HomeCommunityFeed.discover;
  return resolveHomeCommunityFeed(
    isMember: true,
    myFeed: ref.watch(myUnifiedConnectFeedProvider),
  );
});
