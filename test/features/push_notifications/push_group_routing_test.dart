import 'package:flutter_pecha/features/push_notifications/presentation/push_message_navigator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolvePushTap for group pushes', () {
    test('EVENT_REMINDER opens the event, same as EVENT', () {
      final reminder = resolvePushTap({
        'session_type': 'EVENT_REMINDER',
        'notification_type': 'EVENT_REMINDER',
        'reminder_type': 'T_MINUS_10',
        'event_id': 'evt-1',
        'source_id': 'evt-1',
      });
      expect(reminder.target, PushTapTarget.eventDetail);
      expect(reminder.sourceId, 'evt-1');

      final created = resolvePushTap({
        'session_type': 'EVENT',
        'source_id': 'evt-1',
      });
      expect(created.target, reminder.target);
      expect(created.sourceId, reminder.sourceId);
    });

    test('EVENT_REMINDER without a source id falls back to Home', () {
      expect(
        resolvePushTap({'session_type': 'EVENT_REMINDER'}).target,
        PushTapTarget.home,
      );
    });

    test('group chat push opens the group chat by group id', () {
      final resolution = resolvePushTap({
        'session_type': 'CHAT',
        'chat_kind': 'GROUP',
        'room_id': 'room-1',
        'group_id': 'grp-1',
        'source_id': 'room-1',
      });
      expect(resolution.target, PushTapTarget.groupChat);
      expect(resolution.sourceId, 'grp-1');
    });

    test('group post push opens the post', () {
      final resolution = resolvePushTap({
        'session_type': 'GROUP_POST',
        'post_id': 'post-1',
        'source_id': 'post-1',
      });
      expect(resolution.target, PushTapTarget.postDetail);
      expect(resolution.sourceId, 'post-1');
    });
  });
}
