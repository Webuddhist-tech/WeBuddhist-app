import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/home/presentation/utils/home_live_event_entry.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitation_live_client.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitation_live_peek.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_live_position.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Where a tap on the home live pill should go.
enum HomeLiveEventKind { eventPage, online, inPerson }

/// Joined attendees with a known format can skip the event page. A hybrid
/// event with no choice, and anyone who has not joined, stays on the page
/// so they can pick.
GroupEventParticipationType? participationForHomeLiveShortcut({
  required bool isJoined,
  required GroupEventParticipationType? participationType,
  required bool isHybrid,
  required bool isOnlineFormat,
}) {
  if (!isJoined) return null;
  if (participationType != null) return participationType;
  if (isHybrid) return null;
  return isOnlineFormat
      ? GroupEventParticipationType.online
      : GroupEventParticipationType.offline;
}

/// [liveSessionStarted] is true only when the recitation room already has a
/// position. Without one, every path opens the event page.
HomeLiveEventKind resolveHomeLiveEventKind({
  required bool isJoined,
  required GroupEventParticipationType? participationType,
  required bool isHybrid,
  required bool isOnlineFormat,
  required bool liveSessionStarted,
}) {
  final participation = participationForHomeLiveShortcut(
    isJoined: isJoined,
    participationType: participationType,
    isHybrid: isHybrid,
    isOnlineFormat: isOnlineFormat,
  );
  if (participation == null || !liveSessionStarted) {
    return HomeLiveEventKind.eventPage;
  }
  return participation == GroupEventParticipationType.online
      ? HomeLiveEventKind.online
      : HomeLiveEventKind.inPerson;
}

/// Opens the event page, or the event page with the live destination above
/// it. Falls back to the event page when the attendee has not chosen, or
/// when the live session has no current text. An in-person attendee then
/// opens today's plan, which opens the text live tracking is on.
Future<void> openHomeLiveEvent(
  BuildContext context,
  WidgetRef ref,
  String eventId,
) async {
  final path = AppRoutes.groupEventPath(eventId);
  void openEventPage() {
    if (!context.mounted) return;
    context.push(path);
  }

  final GroupEvent? event;
  try {
    final either = await ref.read(groupEventDetailProvider(eventId).future);
    event = either.fold((_) => null, (loaded) => loaded);
  } catch (_) {
    openEventPage();
    return;
  }
  if (!context.mounted) return;
  if (event == null) {
    openEventPage();
    return;
  }

  final participation = participationForHomeLiveShortcut(
    isJoined: event.isJoined,
    participationType: event.myParticipationType,
    isHybrid: isGroupEventHybrid(event),
    isOnlineFormat: isGroupEventOnline(event),
  );
  if (participation == null) {
    openEventPage();
    return;
  }

  final position = await _currentLivePosition(ref, eventId);
  if (!context.mounted) return;
  final kind = resolveHomeLiveEventKind(
    isJoined: event.isJoined,
    participationType: event.myParticipationType,
    isHybrid: isGroupEventHybrid(event),
    isOnlineFormat: isGroupEventOnline(event),
    liveSessionStarted: position != null,
  );
  switch (kind) {
    case HomeLiveEventKind.eventPage:
      openEventPage();
    case HomeLiveEventKind.online:
      context.push(path, extra: HomeLiveEventOnlineEntry(event));
    case HomeLiveEventKind.inPerson:
      context.push(
        path,
        extra: HomeLiveEventInPersonEntry(
          event: event,
          liveTextId: position!.textId,
          liveSegmentId: position.segmentId,
        ),
      );
  }
}

Future<RecitationLivePosition?> _currentLivePosition(
  WidgetRef ref,
  String eventId,
) async {
  final String? token;
  try {
    token = await ref.read(authServiceProvider).getValidAccessToken();
  } catch (_) {
    return null;
  }
  if (token == null || token.isEmpty) return null;

  final uri = RecitationLiveClient.liveUri(
    restBaseUrl: ref.read(apiConfigProvider).baseUrl,
    token: token,
    eventId: eventId,
  );
  return peekRecitationLivePosition(
    client: RecitationLiveClient(),
    uri: uri,
  );
}
