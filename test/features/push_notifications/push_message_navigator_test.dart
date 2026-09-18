import 'package:flutter_pecha/features/push_notifications/presentation/push_message_navigator.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('PushSessionType.isVerseOfDay', () {
    test('recognises verse-of-day aliases', () {
      expect(PushSessionType.isVerseOfDay('VERSE_OF_DAY'), isTrue);
      expect(PushSessionType.isVerseOfDay('PLAN'), isFalse);
    });
  });
}
