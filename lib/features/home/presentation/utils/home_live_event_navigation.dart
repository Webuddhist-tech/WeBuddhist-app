import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
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

/// Pushes the event page straight away so it can show its own loading state.
/// The page then resolves the live destination with [resolveHomeLiveEntry].
void openHomeLiveEvent(BuildContext context, String eventId) {
  context.push(
    AppRoutes.groupEventPath(eventId),
    extra: const HomeLiveEventResolveEntry(),
  );
}

/// The live destination for a joined attendee once the event has loaded.
/// Null stays on the event page: the attendee has not chosen, or the live
/// session has no current text. An in-person attendee then opens today's
/// plan, which opens the text live tracking is on.
Future<HomeLiveEventEntry?> resolveHomeLiveEntry(
  WidgetRef ref,
  GroupEvent event,
) async {
  final isHybrid = isGroupEventHybrid(event);
  final isOnlineFormat = isGroupEventOnline(event);
  final participation = participationForHomeLiveShortcut(
    isJoined: event.isJoined,
    participationType: event.myParticipationType,
    isHybrid: isHybrid,
    isOnlineFormat: isOnlineFormat,
  );
  if (participation == null) return null;

  final position = await _currentLivePosition(ref, event.id);
  final kind = resolveHomeLiveEventKind(
    isJoined: event.isJoined,
    participationType: event.myParticipationType,
    isHybrid: isHybrid,
    isOnlineFormat: isOnlineFormat,
    liveSessionStarted: position != null,
  );
  return switch (kind) {
    HomeLiveEventKind.eventPage => null,
    HomeLiveEventKind.online => HomeLiveEventOnlineEntry(event),
    HomeLiveEventKind.inPerson => HomeLiveEventInPersonEntry(
      event: event,
      liveTextId: position!.textId,
      liveSegmentId: position.segmentId,
    ),
  };
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
