import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

void main() {
  late RecordingAnalyticsService service;
  late GroupChatAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = GroupChatAnalytics(service);
  });

  group('chatReactionActionFor', () {
    test('a plain POST is an add', () {
      expect(
        chatReactionActionFor(isRemoval: false, isSwap: false),
        ChatReactionAction.added,
      );
    });

    test('a DELETE is a removal', () {
      expect(
        chatReactionActionFor(isRemoval: true, isSwap: false),
        ChatReactionAction.removed,
      );
    });

    test('a POST that replaces another emoji is a swap', () {
      expect(
        chatReactionActionFor(isRemoval: false, isSwap: true),
        ChatReactionAction.swapped,
      );
    });
  });

  group('GroupChatAnalytics', () {
    test('chatOpened carries the group, the room and how it was found', () {
      analytics.chatOpened(
        groupId: 'group-1',
        roomId: 'room-1',
        source: ChatOpenSource.resolved,
      );

      expect(service.eventNames, [AnalyticsEvents.groupChatOpened]);
      expect(service.events.single.properties, {
        'group_id': 'group-1',
        'room_id': 'room-1',
        'source': 'resolved',
      });
    });

    test('a plain send fires group_message_sent only', () {
      analytics.messageSent(
        groupId: 'group-1',
        roomId: 'room-1',
        messageId: 'm1',
      );

      expect(service.eventNames, [AnalyticsEvents.groupMessageSent]);
      expect(service.events.single.properties, {
        'group_id': 'group-1',
        'room_id': 'room-1',
        'message_id': 'm1',
        'is_reply': false,
      });
    });

    test('a reply fires group_message_sent and group_message_replied', () {
      analytics.messageSent(
        groupId: 'group-1',
        roomId: 'room-1',
        messageId: 'm2',
        parentMessageId: 'm1',
      );

      expect(service.eventNames, [
        AnalyticsEvents.groupMessageSent,
        AnalyticsEvents.groupMessageReplied,
      ]);
      expect(service.events.first.properties['is_reply'], isTrue);
      expect(service.events.last.properties, {
        'group_id': 'group-1',
        'room_id': 'room-1',
        'message_id': 'm2',
        'parent_message_id': 'm1',
      });
    });

    test('an empty parent id is not a reply', () {
      analytics.messageSent(
        groupId: 'group-1',
        roomId: 'room-1',
        messageId: 'm2',
        parentMessageId: '',
      );

      expect(service.eventNames, [AnalyticsEvents.groupMessageSent]);
      expect(service.events.single.properties['is_reply'], isFalse);
    });

    test('messageDeleted names the room and the message', () {
      analytics.messageDeleted(roomId: 'room-1', messageId: 'm1');

      expect(service.eventNames, [AnalyticsEvents.groupMessageDeleted]);
      expect(service.events.single.properties, {
        'room_id': 'room-1',
        'message_id': 'm1',
      });
    });

    test('messageReacted carries the emoji and what the tap did', () {
      analytics.messageReacted(
        roomId: 'room-1',
        messageId: 'm1',
        emoji: '\u{1F44D}',
        action: ChatReactionAction.swapped,
      );

      expect(service.eventNames, [AnalyticsEvents.groupMessageReacted]);
      expect(service.events.single.properties, {
        'room_id': 'room-1',
        'message_id': 'm1',
        'emoji': '\u{1F44D}',
        'action': 'swapped',
      });
    });

    test('messageReported carries the wire reason', () {
      analytics.messageReported(
        roomId: 'room-1',
        messageId: 'm1',
        reason: 'SPAM',
      );

      expect(service.eventNames, [AnalyticsEvents.groupMessageReported]);
      expect(service.events.single.properties, {
        'room_id': 'room-1',
        'message_id': 'm1',
        'reason': 'SPAM',
      });
    });

    test('a capture that throws is swallowed, not surfaced', () async {
      final throwing = GroupChatAnalytics(_ThrowingAnalyticsService());

      // Would fail the test as an unhandled async error if it escaped.
      throwing.messageDeleted(roomId: 'room-1', messageId: 'm1');
      await Future<void>.delayed(Duration.zero);
    });
  });

  group('ChatOpenTracker', () {
    late ChatOpenTracker tracker;

    setUp(() => tracker = ChatOpenTracker());

    void track(
      String roomId, {
      ChatOpenSource source = ChatOpenSource.resolved,
      bool screenDisposed = false,
    }) {
      tracker.track(
        analytics,
        groupId: 'group-1',
        roomId: roomId,
        source: source,
        screenDisposed: screenDisposed,
      );
    }

    test('fires once for a screen, however the room shows up again', () {
      track('room-1');
      track('room-1', source: ChatOpenSource.live);
      track('room-1', source: ChatOpenSource.firstSend);

      expect(service.eventNames, [AnalyticsEvents.groupChatOpened]);
      expect(service.events.single.properties['source'], 'resolved');
    });

    test('a new screen for the same chat fires again', () {
      track('room-1');
      ChatOpenTracker().track(
        analytics,
        groupId: 'group-1',
        roomId: 'room-1',
        source: ChatOpenSource.resolved,
        screenDisposed: false,
      );

      expect(service.eventNames, [
        AnalyticsEvents.groupChatOpened,
        AnalyticsEvents.groupChatOpened,
      ]);
    });

    test('an empty room id does not use up the event', () {
      track('');
      track('room-1', source: ChatOpenSource.firstSend);

      expect(service.events.single.properties['source'], 'firstSend');
    });

    test('a lookup or socket frame after the screen is gone fires nothing', () {
      track('room-1', screenDisposed: true);
      track('room-1', source: ChatOpenSource.live, screenDisposed: true);

      expect(service.events, isEmpty);
    });

    test('a first send confirmed after the screen is gone still counts', () {
      track('room-1', source: ChatOpenSource.firstSend, screenDisposed: true);

      expect(service.events.single.properties, {
        'group_id': 'group-1',
        'room_id': 'room-1',
        'source': 'firstSend',
      });
    });
  });
}

class _ThrowingAnalyticsService extends RecordingAnalyticsService {
  @override
  Future<void> track(String event, {Map<String, Object?>? properties}) async {
    throw StateError('capture failed');
  }
}
