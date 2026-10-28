import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/entry_analytics.dart';
import 'package:flutter_pecha/core/config/router/app_router.dart';
import 'package:flutter_pecha/core/config/router/launch_navigation.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/notifications/data/models/notification_nav.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

/// FCM `session_type` values carried in the push `data` payload.
/// See the "Push Notification Format" doc for the full contract.
class PushSessionType {
  PushSessionType._();

  static const String plan = 'PLAN';
  static const String series = 'SERIES';
  static const String recitation = 'RECITATION';
  static const String recitationCollection = 'RECITATION_COLLECTION';
  static const String accumulation = 'ACCUMULATION';
  static const String timer = 'TIMER';
  static const String verseOfDay = 'VERSE_OF_DAY';
  static const String verse = 'VERSE';
  static const String quote = 'QUOTE';
  static const String dailyVerse = 'DAILY_VERSE';
  static const String verseOfTheDay = 'VERSE_OF_THE_DAY';

  /// `CHAT_MESSAGE`, `PRAYER_REQUEST` and `PRAYER_RECEIVED` pushes — every
  /// push from a chat room, private, group, or event. See [PushChatKind].
  static const String chat = 'CHAT';

  /// `GROUP_POST` pushes — a new post in a group the user follows.
  static const String groupPost = 'GROUP_POST';

  /// `EVENT` pushes — a group event.
  static const String event = 'EVENT';

  /// `EVENT_REMINDER` pushes — "starting soon" / "starting now" for an event
  /// the user joined. Carries `reminder_type` (`T_MINUS_10` | `T_ZERO`) and
  /// `source_id` = event id, so it lands on the same screen as [event].
  static const String eventReminder = 'EVENT_REMINDER';

  /// Shared by `JOIN_REQUEST_CREATED` and `JOIN_REQUEST_DECIDED`; the backend
  /// does not distinguish them by `session_type`, and it doesn't need to —
  /// both currently land on the same screen.
  static const String group = 'GROUP';

  static bool isVerseOfDay(String sessionType) =>
      sessionType == verseOfDay ||
      sessionType == verse ||
      sessionType == quote ||
      sessionType == dailyVerse ||
      sessionType == verseOfTheDay;
}

/// FCM `chat_kind` values carried alongside [PushSessionType.chat].
class PushChatKind {
  PushChatKind._();

  static const String private = 'PRIVATE';

  /// Group room. Chat messages open group chat; prayer pushes open the
  /// space's prayer requests.
  static const String group = 'GROUP';

  /// Event room. Those rooms are the event's prayer requests, so a tap opens
  /// that list rather than group chat.
  static const String event = 'EVENT';
}

/// FCM `notification_type` values of the chat pushes that are about a prayer
/// request rather than a chat message.
class PushPrayerNotificationType {
  PushPrayerNotificationType._();

  static const String prayerRequest = 'PRAYER_REQUEST';
  static const String prayerReceived = 'PRAYER_RECEIVED';

  static bool matches(String notificationType) =>
      notificationType == prayerRequest || notificationType == prayerReceived;
}

/// Where a push-notification tap should land.
enum PushTapTarget {
  home,
  practice,
  practiceMyPractices,
  seriesDetail,
  timers,
  groupChat,

  /// A direct chat, keyed by room id.
  directChat,
  postDetail,
  eventDetail,
  groupProfile,

  /// The event's prayer-request sheet, keyed by event id.
  eventPrayerRequests,

  /// The space's prayer-request sheet, keyed by group id.
  groupPrayerRequests,
}

/// Result of mapping an FCM data payload to a navigation target.
class PushTapResolution {
  const PushTapResolution(
    this.target, {
    this.sourceId,
    this.resolvesRoom = false,
  });

  final PushTapTarget target;
  final String? sourceId;

  /// [sourceId] is a chat room id. The event or group id is loaded from that
  /// room before the prayer-request sheet opens. Chat pushes always set
  /// `source_id` to the room id; `event_id` / `group_id` is preferred when
  /// the payload carries it.
  final bool resolvesRoom;
}

/// Maps an FCM data map to a [PushTapResolution] without touching the router.
///
/// Isolated so routing can be unit-tested. Verse-of-day and unknown/empty
/// payloads land on Home (the verse card lives there). Practice is reserved
/// for recitation / accumulation until those have dedicated screens.
///
/// [PushTapResolution.sourceId] is "the id to route with", which is usually
/// the payload's own `source_id` — but not always. For chat pushes the backend
/// sets `source_id` = room id, while the app routes by group id, so the
/// resolution carries `group_id` instead.
PushTapResolution resolvePushTap(Map<String, dynamic> data) {
  final sessionType = _sessionTypeOf(data);
  final sourceId = (data['source_id'] as String?)?.trim() ?? '';

  switch (sessionType) {
    case PushSessionType.plan when sourceId.isNotEmpty:
      return PushTapResolution(
        PushTapTarget.practiceMyPractices,
        sourceId: sourceId,
      );
    case PushSessionType.series when sourceId.isNotEmpty:
      return PushTapResolution(PushTapTarget.seriesDetail, sourceId: sourceId);
    case PushSessionType.timer:
      return const PushTapResolution(PushTapTarget.timers);
    case PushSessionType.recitation:
    case PushSessionType.recitationCollection:
    case PushSessionType.accumulation:
      return const PushTapResolution(PushTapTarget.practice);
    case PushSessionType.chat:
      final prayer =
          _eventRoomResolution(data, roomId: sourceId) ??
          _groupPrayerResolution(data, roomId: sourceId);
      if (prayer != null) return prayer;
      // The payload's `source_id` is the *room* id, but group chat is keyed
      // by group id, so route with `group_id`.
      final groupId = _groupIdOf(data);
      if (_chatKindOf(data) == PushChatKind.group && groupId.isNotEmpty) {
        return PushTapResolution(PushTapTarget.groupChat, sourceId: groupId);
      }
      // Direct chat is keyed by room, which is exactly `source_id`.
      if (_chatKindOf(data) == PushChatKind.private && sourceId.isNotEmpty) {
        return PushTapResolution(PushTapTarget.directChat, sourceId: sourceId);
      }
      // Group chats missing a group id, and private ones missing a room id,
      // have nowhere to go but Home.
      return const PushTapResolution(PushTapTarget.home);
    case PushSessionType.groupPost when sourceId.isNotEmpty:
      return PushTapResolution(PushTapTarget.postDetail, sourceId: sourceId);
    case PushSessionType.event when sourceId.isNotEmpty:
    case PushSessionType.eventReminder when sourceId.isNotEmpty:
      return PushTapResolution(PushTapTarget.eventDetail, sourceId: sourceId);
    case PushSessionType.group when sourceId.isNotEmpty:
      // Both JOIN_REQUEST_CREATED and JOIN_REQUEST_DECIDED arrive with
      // `session_type: GROUP` and `source_id` = group id. There is no admin
      // join-request review screen in this app today, so both land on the
      // group's profile. When such a screen ships, JOIN_REQUEST_CREATED
      // should deep-link an admin there instead of the generic profile
      // (it will need `notification_type` to tell the two flavours apart).
      return PushTapResolution(PushTapTarget.groupProfile, sourceId: sourceId);
    default:
      return const PushTapResolution(PushTapTarget.home);
  }
}

String _sessionTypeOf(Map<String, dynamic> data) {
  final fromSession = (data['session_type'] as String?)?.trim();
  if (fromSession != null && fromSession.isNotEmpty) {
    return fromSession.toUpperCase();
  }
  final fromType = (data['type'] as String?)?.trim();
  return fromType?.toUpperCase() ?? '';
}

String _chatKindOf(Map<String, dynamic> data) =>
    (data['chat_kind'] as String?)?.trim().toUpperCase() ?? '';

String _eventIdOf(Map<String, dynamic> data) =>
    (data['event_id'] as String?)?.trim() ?? '';

String _groupIdOf(Map<String, dynamic> data) =>
    (data['group_id'] as String?)?.trim() ?? '';

String _notificationTypeOf(Map<String, dynamic> data) =>
    (data['notification_type'] as String?)?.trim().toUpperCase() ?? '';

/// The space's prayer requests for a prayer push from a group room, or null
/// for anything else. A group room also carries chat, so here the
/// `notification_type` decides. Without a `group_id` the group is looked up
/// from [roomId] (the payload's `source_id`).
PushTapResolution? _groupPrayerResolution(
  Map<String, dynamic> data, {
  required String roomId,
}) {
  if (_chatKindOf(data) != PushChatKind.group) return null;
  if (!PushPrayerNotificationType.matches(_notificationTypeOf(data))) {
    return null;
  }
  final groupId = _groupIdOf(data);
  if (groupId.isNotEmpty) {
    return PushTapResolution(
      PushTapTarget.groupPrayerRequests,
      sourceId: groupId,
    );
  }
  if (roomId.isEmpty) return null;
  return PushTapResolution(
    PushTapTarget.groupPrayerRequests,
    sourceId: roomId,
    resolvesRoom: true,
  );
}

/// The event's prayer requests for a push from an event room, or null for
/// any other room.
///
/// The room kind decides, not `notification_type`: an event room is only
/// prayer requests. `event_id` is only sent on PRAYER_RECEIVED; otherwise the
/// event is looked up from [roomId] (the payload's `source_id`).
PushTapResolution? _eventRoomResolution(
  Map<String, dynamic> data, {
  required String roomId,
}) {
  if (_chatKindOf(data) != PushChatKind.event) return null;
  final eventId = _eventIdOf(data);
  if (eventId.isNotEmpty) {
    return PushTapResolution(
      PushTapTarget.eventPrayerRequests,
      sourceId: eventId,
    );
  }
  if (roomId.isEmpty) return null;
  return PushTapResolution(
    PushTapTarget.eventPrayerRequests,
    sourceId: roomId,
    resolvesRoom: true,
  );
}

/// Single entry point for navigating after a push notification is opened.
///
/// Routing must behave the same no matter how the notification was tapped:
///   • foreground — tap on the locally shown heads-up (arrives via the shared
///     `flutter_local_notifications` callback as a decoded data map)
///   • background — `FirebaseMessaging.onMessageOpenedApp`
///   • terminated — `FirebaseMessaging.getInitialMessage`
///
/// Funnelling all three through this class keeps navigation consistent. The
/// actual navigation is deferred to the next frame so it is safe to call during
/// cold start, before the router and widget tree are ready.
class PushMessageNavigator {
  PushMessageNavigator(this._ref);

  final Ref _ref;

  /// Bumped on every routed tap so a slow lookup can tell it was superseded.
  int _tapGeneration = 0;

  /// Routes a domain [PushMessage] — used for background / terminated taps.
  void handle(PushMessage message, PushAppState appState) =>
      _schedule(message.data, appState);

  /// Routes a raw FCM data map — used for foreground taps, which reach us via
  /// the shared local-notifications callback as a decoded JSON payload.
  void handleData(Map<String, dynamic> data) =>
      _schedule(data, PushAppState.foreground);

  void _schedule(Map<String, dynamic> data, PushAppState appState) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _routeWhenSettled(data, appState),
    );
  }

  /// Defers routing until the router has left `/splash`.
  ///
  /// A cold start via notification tap (`getInitialMessage`) races auth
  /// restoration: [RouteGuard] sends every destination to `/splash` while
  /// [AuthState.isLoading] is true and does not remember it — the pending-route
  /// mechanism in [RouteGuard] only captures unauthenticated attempts, not
  /// loading ones — so pushing the real destination now would just get
  /// redirected away and lost, landing the user on Home once auth settles.
  /// The launch intro holds the splash the same way (`splashHoldProvider`).
  /// Shares [runWhenOffSplash] with the other launch-time navigations.
  void _routeWhenSettled(Map<String, dynamic> data, PushAppState appState) {
    runWhenOffSplash(
      _ref.read(appRouterProvider),
      () => _route(data, appState),
    );
  }

  void _route(Map<String, dynamic> data, PushAppState appState) {
    _tapGeneration++;
    final resolution = resolvePushTap(data);
    final router = _ref.read(appRouterProvider);
    final sourceId = resolution.sourceId ?? '';

    switch (resolution.target) {
      case PushTapTarget.practiceMyPractices:
        // For PLAN pushes the backend sends `source_id` = the enrolled plan id,
        // so it maps straight onto NotificationNav.planId (same field local
        // routine notifications use). RoutineFilledState then resolves the plan
        // + current day and pushes /practice/details. That widget only mounts
        // on the My Practices screen (the Practice *tab* shows the explore
        // screen, which doesn't consume the pending nav), so go there after
        // seeding it.
        _ref
            .read(pendingNotificationNavProvider.notifier)
            .state = NotificationNav(
          itemId: sourceId,
          itemType: RoutineItemType.plan.name,
          planId: sourceId,
        );
        _ref.read(mainNavigationIndexProvider.notifier).state =
            MainTab.practice.index;
        router.go(AppRoutes.home);
        router.push(AppRoutes.practiceMyPractices);

      case PushTapTarget.seriesDetail:
        router.go(AppRoutes.home);
        router.push('/home/series/$sourceId');

      case PushTapTarget.timers:
        router.go(AppRoutes.home);
        router.push('/home/timers');

      case PushTapTarget.groupChat:
        // Group chat is a top-level route, outside the /home shell, so it is
        // pushed directly — same as the in-app call sites on group profile.
        router.push(AppRoutes.groupChatPath(sourceId));

      case PushTapTarget.directChat:
        // Top-level as well, so pushed directly like group chat.
        router.push(AppRoutes.directChatPath(sourceId));

      case PushTapTarget.postDetail:
        router.go(AppRoutes.home);
        router.push('/home/posts/$sourceId');

      case PushTapTarget.eventDetail:
        router.go(AppRoutes.home);
        router.push('/home/events/$sourceId');

      case PushTapTarget.eventPrayerRequests:
      case PushTapTarget.groupPrayerRequests:
        if (resolution.resolvesRoom) {
          unawaited(_openPrayerRequestsFromRoom(sourceId));
        } else if (resolution.target == PushTapTarget.eventPrayerRequests) {
          _openPrayerRequests(sourceId);
        } else {
          _openGroupPrayerRequests(sourceId);
        }

      case PushTapTarget.groupProfile:
        router.go(AppRoutes.home);
        router.push('/home/group/$sourceId');

      case PushTapTarget.practice:
        _openPracticeTab(router);

      case PushTapTarget.home:
        _openHomeTab(router);
    }

    final sessionType = _sessionTypeOf(data);
    final payloadSourceId = (data['source_id'] as String?)?.trim() ?? '';
    _ref
        .read(entryAnalyticsProvider)
        .pushNotificationOpened(
          appState: appState,
          sessionType: sessionType.isEmpty ? null : sessionType,
          sourceId: payloadSourceId.isEmpty ? null : payloadSourceId,
        );
  }

  void _openPracticeTab(GoRouter router) {
    _ref.read(mainNavigationIndexProvider.notifier).state =
        MainTab.practice.index;
    router.go(AppRoutes.home);
  }

  void _openHomeTab(GoRouter router) {
    _ref.read(mainNavigationIndexProvider.notifier).state = MainTab.home.index;
    router.go(AppRoutes.home);
  }

  /// Chat pushes name the room in `source_id`. The prayer sheet is keyed by
  /// the event or the space, which that room carries.
  ///
  /// The result is dropped when another tap was routed, or the user moved,
  /// while the room was loading.
  Future<void> _openPrayerRequestsFromRoom(String roomId) async {
    final generation = _tapGeneration;
    final delegate = _ref.read(appRouterProvider).routerDelegate;
    var moved = false;
    void onMoved() => moved = true;
    delegate.addListener(onMoved);
    final Either<Failure, ChatRoomDTO> result;
    try {
      result = await _ref.read(groupChatRepositoryProvider).getRoom(roomId);
    } finally {
      delegate.removeListener(onMoved);
    }
    if (moved || generation != _tapGeneration) return;
    final room = result.fold<ChatRoomDTO?>((_) => null, (room) => room);
    final eventId = room?.eventId?.trim() ?? '';
    final groupId = room?.groupId?.trim() ?? '';
    if (eventId.isNotEmpty) {
      _openPrayerRequests(eventId);
    } else if (groupId.isNotEmpty) {
      _openGroupPrayerRequests(groupId);
    } else {
      _openHomeTab(_ref.read(appRouterProvider));
    }
  }

  /// Lands on the space page, which then opens its prayer-request sheet so
  /// closing it leaves the space underneath.
  void _openGroupPrayerRequests(String groupId) {
    if (groupId.isEmpty) {
      _openHomeTab(_ref.read(appRouterProvider));
      return;
    }
    final router = _ref.read(appRouterProvider);
    router.go(AppRoutes.home);
    router.push(AppRoutes.groupProfilePath(groupId, openPrayerRequests: true));
  }

  /// Lands on the event, then the event screen opens the prayer-request sheet
  /// so closing it leaves that event underneath.
  void _openPrayerRequests(String eventId) {
    if (eventId.isEmpty) {
      _openHomeTab(_ref.read(appRouterProvider));
      return;
    }
    final router = _ref.read(appRouterProvider);
    router.go(AppRoutes.home);
    router.push(AppRoutes.groupEventPath(eventId, openPrayerRequests: true));
  }
}

/// App-lifetime provider — the navigator only reads other providers on demand.
final pushMessageNavigatorProvider = Provider<PushMessageNavigator>(
  (ref) => PushMessageNavigator(ref),
);
