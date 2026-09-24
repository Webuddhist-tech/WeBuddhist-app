import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Product analytics for groups and recitation collections: one method per
/// tracked action, so the event names and their property keys live in one
/// place. Every call fires and forgets; callers fire after the server
/// confirms, never optimistically.
class GroupAnalytics {
  const GroupAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// The group profile screen showed a group; fired once per visit.
  /// [source] only when the caller knows where the group was opened from.
  void groupViewed({
    required String groupId,
    required GroupType groupType,
    String? source,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.groupViewed, {
      AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.groupType: groupType.name,
      AnalyticsProperties.source: source,
    });
    _associateSangha(groupId);
  }

  /// The server confirmed the user now follows the group.
  void groupFollowed({required String groupId, required GroupType groupType}) {
    _analytics.trackInBackground(AnalyticsEvents.groupFollowed, {
      AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.groupType: groupType.name,
    });
    _associateSangha(groupId);
  }

  void groupUnfollowed({
    required String groupId,
    required GroupType groupType,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.groupUnfollowed, {
      AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.groupType: groupType.name,
    });
  }

  /// A recitation collection screen showed its items; fired once per visit.
  /// [groupId] is null for the user's own collections.
  void recitationCollectionOpened({
    required String collectionId,
    required String? groupId,
    required int itemCount,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.recitationCollectionOpened, {
      AnalyticsProperties.collectionId: collectionId,
      AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.itemCount: itemCount,
    });
  }

  /// One item of a collection was confirmed complete for today.
  void recitationCollectionItemCompleted({
    required String collectionId,
    required String textId,
    required int completedCount,
    required int itemCount,
  }) {
    _analytics
        .trackInBackground(AnalyticsEvents.recitationCollectionItemCompleted, {
          AnalyticsProperties.collectionId: collectionId,
          AnalyticsProperties.textId: textId,
          AnalyticsProperties.completedCount: completedCount,
          AnalyticsProperties.itemCount: itemCount,
        });
  }

  /// The last item of a collection was completed; fired right after the
  /// item event.
  void recitationCollectionCompleted({
    required String collectionId,
    required String? groupId,
  }) {
    _analytics
        .trackInBackground(AnalyticsEvents.recitationCollectionCompleted, {
          AnalyticsProperties.collectionId: collectionId,
          AnalyticsProperties.groupId: groupId,
        });
  }

  /// Ties later events in the session to the sangha for per-group dashboards.
  void _associateSangha(String groupId) {
    if (groupId.isEmpty) return;
    _analytics.groupInBackground(
      groupType: AnalyticsGroupTypes.sangha,
      groupKey: groupId,
    );
  }
}

final groupAnalyticsProvider = Provider<GroupAnalytics>((ref) {
  return GroupAnalytics(ref.watch(analyticsServiceProvider));
});
