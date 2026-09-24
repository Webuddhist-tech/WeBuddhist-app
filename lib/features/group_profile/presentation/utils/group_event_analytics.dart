import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_link_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What "enter the live event" opened, carried on `group_event_live_entered`.
enum GroupEventLiveTarget { series, plan }

/// Product analytics for group events: one method per tracked action, so the
/// event names and their property keys live in one place. Every call fires
/// and forgets; callers fire after the server confirms, never optimistically.
class GroupEventAnalytics {
  const GroupEventAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// The event detail screen showed an event; fired once per visit.
  void eventViewed({
    required String eventId,
    required String groupId,
    required String eventTitle,
    required String? eventFormat,
    required bool isRecurring,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.groupEventViewed, {
      AnalyticsProperties.eventId: eventId,
      AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.eventTitle: eventTitle,
      AnalyticsProperties.eventFormat: eventFormat,
      AnalyticsProperties.isRecurring: isRecurring,
    });
    if (groupId.isNotEmpty) {
      _analytics.groupInBackground(
        groupType: AnalyticsGroupTypes.sangha,
        groupKey: groupId,
      );
    }
  }

  /// The embedded live stream started playing for this viewer.
  void eventLiveOpened({required String eventId, required String groupId}) {
    _analytics.trackInBackground(AnalyticsEvents.groupEventLiveOpened, {
      AnalyticsProperties.eventId: eventId,
      AnalyticsProperties.groupId: groupId,
    });
  }

  /// The live stream stopped or the screen left; [durationSeconds] is the
  /// time it was actually playing.
  void eventLiveEnded({
    required String eventId,
    required String groupId,
    required int durationSeconds,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.groupEventLiveEnded, {
      AnalyticsProperties.eventId: eventId,
      AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.durationSeconds: durationSeconds,
    });
  }

  void accumulatorViewed({
    required String groupId,
    required String accumulatorId,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.groupAccumulatorViewed, {
      AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.accumulatorId: accumulatorId,
    });
    _analytics.groupInBackground(
      groupType: AnalyticsGroupTypes.sangha,
      groupKey: groupId,
    );
  }

  /// [participation] is null when the event has a single format and the
  /// server chose it.
  void eventAttended({
    required String eventId,
    required String groupId,
    required GroupEventParticipationType? participation,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.groupEventAttended, {
      AnalyticsProperties.eventId: eventId,
      AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.participation: participation?.apiValue,
    });
  }

  void eventLeft({required String eventId, required String groupId}) {
    _analytics.trackInBackground(AnalyticsEvents.groupEventLeft, {
      AnalyticsProperties.eventId: eventId,
      AnalyticsProperties.groupId: groupId,
    });
  }

  /// An attendee of a hybrid event switched between online and in person.
  void eventParticipationChanged({
    required String eventId,
    required String groupId,
    required GroupEventParticipationType participation,
  }) {
    _analytics
        .trackInBackground(AnalyticsEvents.groupEventParticipationChanged, {
          AnalyticsProperties.eventId: eventId,
          AnalyticsProperties.groupId: groupId,
          AnalyticsProperties.participation: participation.apiValue,
        });
  }

  /// The attendee opened the event's practice (series or plan) from the
  /// detail screen, with the live stream when attending online.
  void eventLiveEntered({
    required String eventId,
    required String groupId,
    required GroupEventParticipationType? participation,
    required GroupEventLiveTarget target,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.groupEventLiveEntered, {
      AnalyticsProperties.eventId: eventId,
      AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.participation: participation?.apiValue,
      AnalyticsProperties.target: target.name,
    });
  }


  /// A meeting, video or web link on the event was opened.
  void eventLinkOpened({
    required String eventId,
    required GroupEventLinkKind kind,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.groupEventLinkOpened, {
      AnalyticsProperties.eventId: eventId,
      AnalyticsProperties.linkType: kind.name,
    });
  }
}

final groupEventAnalyticsProvider = Provider<GroupEventAnalytics>((ref) {
  return GroupEventAnalytics(ref.watch(analyticsServiceProvider));
});
