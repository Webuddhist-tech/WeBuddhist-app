import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The lists a post card appears in, carried as `surface`.
enum ConnectPostSurface {
  homePreview,
  communityFeed,
  space;

  String get key => switch (this) {
    ConnectPostSurface.homePreview => 'home_preview',
    ConnectPostSurface.communityFeed => 'community_feed',
    ConnectPostSurface.space => 'space',
  };
}

/// Where a post card sits: its list and its index in that list.
class ConnectPostPlacement {
  const ConnectPostPlacement({required this.surface, required this.position});

  final ConnectPostSurface surface;
  final int position;
}

/// Product analytics for the Connect tab and its posts: one method per tracked
/// action, so the event names and their property keys live in one place. Every
/// call fires and forgets; callers fire once the tab really is on screen or
/// the action really happened.
class ConnectAnalytics {
  const ConnectAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// A Connect sub-tab settled on screen; [followedGroupCount] only when the
  /// my-groups provider already holds it.
  void tabViewed({required String subTab, required int? followedGroupCount}) {
    _analytics.trackInBackground(AnalyticsEvents.connectTabViewed, {
      AnalyticsProperties.subTab: subTab,
      AnalyticsProperties.followedGroupCount: followedGroupCount,
    });
  }

  /// A card stayed at least half visible for a second; once per card per
  /// visit, see [ConnectPostViewTracker].
  void postViewed({
    required ConnectPost post,
    required ConnectPostPlacement placement,
  }) {
    _analytics.trackInBackground(
      AnalyticsEvents.postViewed,
      _placedPostProperties(post, placement),
    );
  }

  /// A card opened its comment drawer or image viewer.
  void postOpened({
    required ConnectPost post,
    required ConnectPostPlacement placement,
  }) {
    _analytics.trackInBackground(
      AnalyticsEvents.postOpened,
      _placedPostProperties(post, placement),
    );
  }

  /// A link on a card opened. [link] is the one tapped; its URL is never sent.
  void postLinkOpened({
    required ConnectPost post,
    required ConnectPostPlacement placement,
    required ConnectPostLink link,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.postLinkOpened, {
      ..._placedPostProperties(post, placement),
      AnalyticsProperties.linkType: _linkTypeKey(link),
    });
  }

  /// The server confirmed a new post, not an edit.
  void groupPostCreated({required ConnectPost post, required String groupId}) {
    _analytics.trackInBackground(AnalyticsEvents.groupPostCreated, {
      ..._postProperties(post),
      AnalyticsProperties.groupId: groupId,
    });
  }

  Map<String, Object?> _placedPostProperties(
    ConnectPost post,
    ConnectPostPlacement placement,
  ) => {
    ..._postProperties(post),
    AnalyticsProperties.position: placement.position,
    AnalyticsProperties.surface: placement.surface.key,
  };

  Map<String, Object?> _postProperties(ConnectPost post) {
    final links = post.links.where((link) => link.url.trim().isNotEmpty);
    return {
      AnalyticsProperties.postId: post.id,
      AnalyticsProperties.groupId: post.groupId,
      AnalyticsProperties.hasMedia: post.media.isNotEmpty,
      AnalyticsProperties.linkType:
          links.isEmpty ? null : _linkTypeKey(links.first),
    };
  }

  String? _linkTypeKey(ConnectPostLink link) {
    final type = link.type.trim().toLowerCase();
    return type.isEmpty ? null : type;
  }
}

final connectAnalyticsProvider = Provider<ConnectAnalytics>((ref) {
  return ConnectAnalytics(ref.watch(analyticsServiceProvider));
});

/// Remembers which posts one surface has reported as viewed. A list recycles
/// its cards as it scrolls, so a card cannot remember this itself.
class ConnectPostViewTracker {
  final Set<String> _viewed = {};

  /// True the first time [postId] is seen during this visit.
  bool markViewed(String postId) => _viewed.add(postId);
}

/// One visit lasts while the surface watches this: leaving the screen disposes
/// it, and coming back starts a new visit.
final connectPostViewTrackerProvider = Provider.autoDispose
    .family<ConnectPostViewTracker, ConnectPostSurface>(
      (ref, surface) => ConnectPostViewTracker(),
    );
