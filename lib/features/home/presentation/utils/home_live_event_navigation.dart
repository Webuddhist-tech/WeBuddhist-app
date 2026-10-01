import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/home/presentation/utils/home_live_event_entry.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/plan_list_view.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
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

/// Reader context for [position]. When that text is in today's plan, the
/// day's sequence is attached so the reader can follow the operator onto
/// the next text. Otherwise the reader opens that text on its own.
NavigationContext readerContextForLivePosition({
  required String eventId,
  required RecitationLivePosition position,
  String? planId,
  int? dayNumber,
  String? dayAudioUrl,
  List<PlanTextItem> items = const [],
}) {
  final index = items.indexWhere(
    (item) => item.isSourceReference && item.textId == position.textId,
  );
  if (index < 0) {
    return NavigationContext(
      source: NavigationSource.normal,
      eventId: eventId,
      isOnlineAttendee: false,
      targetSegmentId: position.segmentId,
    );
  }
  return NavigationContext(
    source: NavigationSource.plan,
    planId: planId,
    dayNumber: dayNumber,
    targetSegmentId: position.segmentId,
    planTextItems: items,
    currentTextIndex: index,
    dayAudioUrl: dayAudioUrl,
    eventId: eventId,
    isOnlineAttendee: false,
  );
}

/// Opens the event page, or the event page with the live destination above
/// it. Falls back to the event page when the attendee has not chosen, or
/// when the live session has no current text.
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
      final navigationContext = await _readerContext(ref, event, position!);
      if (!context.mounted) return;
      context.push(
        path,
        extra: HomeLiveEventInPersonEntry(
          textId: position.textId,
          navigationContext: navigationContext,
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

Future<NavigationContext> _readerContext(
  WidgetRef ref,
  GroupEvent event,
  RecitationLivePosition position,
) async {
  final reading = await _loadTodayReading(ref, event);
  return readerContextForLivePosition(
    eventId: event.id,
    position: position,
    planId: reading?.planId,
    dayNumber: reading?.dayNumber,
    dayAudioUrl: reading?.dayAudioUrl,
    items: reading?.items ?? const [],
  );
}

class _TodayReading {
  const _TodayReading({
    required this.planId,
    required this.dayNumber,
    required this.items,
    this.dayAudioUrl,
  });

  final String planId;
  final int dayNumber;
  final String? dayAudioUrl;
  final List<PlanTextItem> items;
}

Future<_TodayReading?> _loadTodayReading(
  WidgetRef ref,
  GroupEvent event,
) async {
  try {
    final plan = await _resolvePlan(ref, event);
    if (plan == null || plan.totalDays < 1) return null;

    final enrolled =
        ref
            .read(myPlansPaginatedProvider)
            .plans
            .where((item) => item.id == plan.id)
            .firstOrNull;
    final userPlan = enrolled ?? userPlanFromCatalogPlan(plan);
    if (userPlan.totalDays < 1) return null;
    final dayNumber = selectedDayForStart(
      userPlan.effectiveStartDate,
      userPlan.totalDays,
    );
    final either = await ref.read(
      planDayContentFutureProvider(
        PlanDaysParams(planId: plan.id, dayNumber: dayNumber),
      ).future,
    );
    final day = either.fold((_) => null, (loaded) => loaded);
    final tasks = day?.tasks;
    if (day == null || tasks == null) return null;
    return _TodayReading(
      planId: plan.id,
      dayNumber: dayNumber,
      dayAudioUrl: day.audioUrl,
      items: PlanSubtaskNavigation.fromPlanTasks(tasks),
    );
  } catch (_) {
    return null;
  }
}

Future<Plan?> _resolvePlan(WidgetRef ref, GroupEvent event) async {
  final seriesId = event.series?.id ?? event.seriesId;
  if (seriesId != null && seriesId.isNotEmpty) {
    final either = await ref.read(seriesByIdProvider(seriesId).future);
    return either.fold<Series?>(
      (_) => null,
      (series) => series,
    )?.plans.firstOrNull;
  }
  final planId = event.plan?.id ?? event.planId;
  if (planId == null || planId.isEmpty) return null;
  final either = await ref.read(planByIdFutureProvider(planId).future);
  return either.fold((_) => null, (plan) => plan);
}
