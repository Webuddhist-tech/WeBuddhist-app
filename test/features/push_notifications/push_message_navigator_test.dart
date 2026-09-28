import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/config/router/app_router.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/push_message_navigator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/recording_analytics_service.dart';

/// `getRoom` stays pending until the test completes it, so the order in which
/// lookups finish is under the test's control.
class _FakeChatRepository extends Fake implements GroupChatRepository {
  final List<String> requested = [];
  final Map<String, Completer<Either<Failure, ChatRoomDTO>>> _pending = {};

  @override
  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId) {
    requested.add(roomId);
    return (_pending[roomId] = Completer()).future;
  }

  void complete(String roomId, Either<Failure, ChatRoomDTO> result) =>
      _pending.remove(roomId)!.complete(result);
}

ChatRoomDTO _room(String id, {String? eventId}) => ChatRoomDTO(
  id: id,
  createdBy: 'user-1',
  eventId: eventId,
  kind: 'EVENT',
  name: 'Prayers',
  updatedAt: '',
);

void main() {
  group('resolvePushTap', () {
    test('verse of the day session types open Home', () {
      const types = [
        'VERSE_OF_DAY',
        'verse_of_day',
        'VERSE',
        'QUOTE',
        'DAILY_VERSE',
        'VERSE_OF_THE_DAY',
      ];

      for (final type in types) {
        final fromSession = resolvePushTap({'session_type': type});
        expect(
          fromSession.target,
          PushTapTarget.home,
          reason: 'session_type=$type should open Home',
        );

        final fromType = resolvePushTap({'type': type});
        expect(
          fromType.target,
          PushTapTarget.home,
          reason: 'type=$type should open Home',
        );
      }
    });

    test('empty or unknown payloads open Home, not Practice', () {
      expect(resolvePushTap(const {}).target, PushTapTarget.home);
      expect(resolvePushTap({'session_type': ''}).target, PushTapTarget.home);
      expect(
        resolvePushTap({'session_type': 'ANNOUNCEMENT'}).target,
        PushTapTarget.home,
      );
    });

    test('PLAN with source_id opens My Practices', () {
      final actual = resolvePushTap({
        'session_type': 'PLAN',
        'source_id': 'plan-1',
      });
      expect(actual.target, PushTapTarget.practiceMyPractices);
      expect(actual.sourceId, 'plan-1');
    });

    test('PLAN without source_id falls back to Home', () {
      expect(
        resolvePushTap({'session_type': 'PLAN'}).target,
        PushTapTarget.home,
      );
    });

    test('SERIES with source_id opens series detail', () {
      final actual = resolvePushTap({
        'session_type': 'SERIES',
        'source_id': 'series-1',
      });
      expect(actual.target, PushTapTarget.seriesDetail);
      expect(actual.sourceId, 'series-1');
    });

    test('TIMER opens timers', () {
      expect(
        resolvePushTap({'session_type': 'TIMER'}).target,
        PushTapTarget.timers,
      );
    });

    test('recitation and accumulation still open Practice', () {
      expect(
        resolvePushTap({'session_type': 'RECITATION'}).target,
        PushTapTarget.practice,
      );
      expect(
        resolvePushTap({'session_type': 'RECITATION_COLLECTION'}).target,
        PushTapTarget.practice,
      );
      expect(
        resolvePushTap({'session_type': 'ACCUMULATION'}).target,
        PushTapTarget.practice,
      );
    });

    test('group CHAT routes by group_id, not the room id in source_id', () {
      final actual = resolvePushTap({
        'notification_type': 'CHAT_MESSAGE',
        'session_type': 'CHAT',
        'chat_kind': 'GROUP',
        'room_id': 'room-1',
        'group_id': 'group-1',
        'source_id': 'room-1',
      });
      expect(actual.target, PushTapTarget.groupChat);
      expect(
        actual.sourceId,
        'group-1',
        reason: 'chat pushes route by group_id, while source_id is the room id',
      );
    });

    test('private CHAT falls back to Home (no private chat screen yet)', () {
      final actual = resolvePushTap({
        'notification_type': 'CHAT_MESSAGE',
        'session_type': 'CHAT',
        'chat_kind': 'PRIVATE',
        'room_id': 'room-1',
        'group_id': '',
        'source_id': 'room-1',
      });
      expect(actual.target, PushTapTarget.home);
    });

    test('event prayer chat opens prayer requests by event id', () {
      final actual = resolvePushTap({
        'notification_type': 'CHAT_MESSAGE',
        'session_type': 'CHAT',
        'chat_kind': 'EVENT',
        'event_id': 'event-1',
        'room_id': 'room-1',
        'source_id': 'room-1',
        'message_type': 'PRAYER',
      });
      expect(actual.target, PushTapTarget.eventPrayerRequests);
      expect(actual.sourceId, 'event-1');
      expect(actual.resolvesRoom, isFalse);
    });

    test('event prayer chat without event_id keeps the room id to resolve', () {
      final actual = resolvePushTap({
        'session_type': 'CHAT',
        'kind': 'EVENT',
        'source_id': 'room-1',
      });
      expect(actual.target, PushTapTarget.eventPrayerRequests);
      expect(actual.sourceId, 'room-1');
      expect(actual.resolvesRoom, isTrue);
    });

    test('a PRAYER message on a chat push opens prayer requests', () {
      final actual = resolvePushTap({
        'session_type': 'CHAT',
        'message_type': 'PRAYER',
        'event_id': 'event-1',
        'source_id': 'room-1',
      });
      expect(actual.target, PushTapTarget.eventPrayerRequests);
      expect(actual.sourceId, 'event-1');
    });

    test('PRAYER_REQUEST opens prayer requests by source id', () {
      final actual = resolvePushTap({
        'session_type': 'PRAYER_REQUEST',
        'source_id': 'event-1',
      });
      expect(actual.target, PushTapTarget.eventPrayerRequests);
      expect(actual.sourceId, 'event-1');
      expect(actual.resolvesRoom, isFalse);
    });

    test('a prayer notification with only source_id treats it as the event', () {
      final actual = resolvePushTap({
        'notification_type': 'PRAYER',
        'source_id': 'event-1',
      });
      expect(actual.target, PushTapTarget.eventPrayerRequests);
      expect(actual.sourceId, 'event-1');
      expect(actual.resolvesRoom, isFalse);
    });

    test('a prayer notification type without session_type still opens prayers', () {
      final actual = resolvePushTap({
        'notification_type': 'PRAYER',
        'event_id': 'event-1',
      });
      expect(actual.target, PushTapTarget.eventPrayerRequests);
      expect(actual.sourceId, 'event-1');
    });

    test('group CHAT without a group_id falls back to Home', () {
      expect(
        resolvePushTap({
          'session_type': 'CHAT',
          'chat_kind': 'GROUP',
          'group_id': '',
          'source_id': 'room-1',
        }).target,
        PushTapTarget.home,
      );
      expect(
        resolvePushTap({
          'session_type': 'CHAT',
          'chat_kind': 'GROUP',
          'source_id': 'room-1',
        }).target,
        PushTapTarget.home,
      );
    });

    test('GROUP_POST with source_id opens the post detail', () {
      final actual = resolvePushTap({
        'notification_type': 'GROUP_POST',
        'session_type': 'GROUP_POST',
        'post_id': 'post-1',
        'group_id': 'group-1',
        'source_id': 'post-1',
      });
      expect(actual.target, PushTapTarget.postDetail);
      expect(actual.sourceId, 'post-1');
    });

    test('GROUP_POST without source_id falls back to Home', () {
      expect(
        resolvePushTap({'session_type': 'GROUP_POST'}).target,
        PushTapTarget.home,
      );
    });

    test('EVENT with source_id opens the event detail', () {
      final actual = resolvePushTap({
        'notification_type': 'EVENT',
        'session_type': 'EVENT',
        'event_id': 'event-1',
        'group_id': 'group-1',
        'source_id': 'event-1',
      });
      expect(actual.target, PushTapTarget.eventDetail);
      expect(actual.sourceId, 'event-1');
    });

    test('EVENT without source_id falls back to Home', () {
      expect(
        resolvePushTap({'session_type': 'EVENT'}).target,
        PushTapTarget.home,
      );
    });

    test('a created join request opens the group profile', () {
      final actual = resolvePushTap({
        'notification_type': 'JOIN_REQUEST_CREATED',
        'session_type': 'GROUP',
        'join_request_id': 'jr-1',
        'group_id': 'group-1',
        'status': 'PENDING',
        'source_id': 'group-1',
      });
      expect(actual.target, PushTapTarget.groupProfile);
      expect(actual.sourceId, 'group-1');
    });

    test('a decided join request opens the same group profile', () {
      final actual = resolvePushTap({
        'notification_type': 'JOIN_REQUEST_DECIDED',
        'session_type': 'GROUP',
        'join_request_id': 'jr-1',
        'group_id': 'group-1',
        'status': 'APPROVED',
        'source_id': 'group-1',
      });
      expect(actual.target, PushTapTarget.groupProfile);
      expect(actual.sourceId, 'group-1');
    });

    test('GROUP without source_id falls back to Home', () {
      expect(
        resolvePushTap({
          'notification_type': 'JOIN_REQUEST_CREATED',
          'session_type': 'GROUP',
          'status': 'PENDING',
        }).target,
        PushTapTarget.home,
      );
    });
  });

  group('PushMessageNavigator room lookup', () {
    late _FakeChatRepository repository;
    late GoRouter router;
    late ProviderContainer container;

    Future<void> pumpApp(WidgetTester tester) async {
      repository = _FakeChatRepository();
      router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const Text('home'),
            routes: [
              GoRoute(
                path: 'events/:eventId',
                builder: (_, state) {
                  final eventId = state.pathParameters['eventId'];
                  final prayers =
                      state.uri.queryParameters[AppRoutes.eventPrayersQuery];
                  return Text('event $eventId prayers=$prayers');
                },
              ),
            ],
          ),
          GoRoute(path: '/other', builder: (_, __) => const Text('other')),
        ],
      );
      container = ProviderContainer(
        overrides: [
          appRouterProvider.overrideWithValue(router),
          groupChatRepositoryProvider.overrideWithValue(repository),
          analyticsServiceProvider.overrideWithValue(
            RecordingAnalyticsService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
    }

    Future<void> tap(WidgetTester tester, String roomId) async {
      container.read(pushMessageNavigatorProvider).handleData({
        'session_type': 'CHAT',
        'chat_kind': 'EVENT',
        'source_id': roomId,
      });
      tester.binding.scheduleFrame();
      await tester.pump();
    }

    String location() => router.state.uri.toString();

    testWidgets('opens the looked-up event with its prayer requests', (
      tester,
    ) async {
      await pumpApp(tester);
      await tap(tester, 'room-1');
      expect(repository.requested, ['room-1']);

      repository.complete('room-1', Right(_room('room-1', eventId: 'event-1')));
      await tester.pumpAndSettle();

      expect(location(), '/home/events/event-1?prayers=1');
      expect(find.text('event event-1 prayers=1'), findsOneWidget);
    });

    testWidgets('falls back to Home when the room cannot be loaded', (
      tester,
    ) async {
      await pumpApp(tester);
      router.go('/other');
      await tester.pumpAndSettle();
      await tap(tester, 'room-1');

      repository.complete('room-1', const Left(NetworkFailure('offline')));
      await tester.pumpAndSettle();

      expect(location(), AppRoutes.home);
    });

    testWidgets('falls back to Home when the room has no event', (
      tester,
    ) async {
      await pumpApp(tester);
      router.go('/other');
      await tester.pumpAndSettle();
      await tap(tester, 'room-1');

      repository.complete('room-1', Right(_room('room-1')));
      await tester.pumpAndSettle();

      expect(location(), AppRoutes.home);
    });

    testWidgets('a lookup superseded by a newer tap does not navigate', (
      tester,
    ) async {
      await pumpApp(tester);
      await tap(tester, 'room-1');
      await tap(tester, 'room-2');

      repository.complete('room-2', Right(_room('room-2', eventId: 'event-2')));
      await tester.pumpAndSettle();
      repository.complete('room-1', Right(_room('room-1', eventId: 'event-1')));
      await tester.pumpAndSettle();

      expect(location(), '/home/events/event-2?prayers=1');
    });

    testWidgets('a lookup is dropped once the user opens another screen', (
      tester,
    ) async {
      await pumpApp(tester);
      await tap(tester, 'room-1');
      unawaited(router.push('/other'));
      await tester.pumpAndSettle();

      repository.complete('room-1', Right(_room('room-1', eventId: 'event-1')));
      await tester.pumpAndSettle();

      expect(location(), '/other');
    });
  });

  group('PushSessionType.isVerseOfDay', () {
    test('recognises verse-of-day aliases', () {
      expect(PushSessionType.isVerseOfDay('VERSE_OF_DAY'), isTrue);
      expect(PushSessionType.isVerseOfDay('PLAN'), isFalse);
    });
  });
}
