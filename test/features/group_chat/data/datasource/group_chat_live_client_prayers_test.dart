import 'dart:convert';

import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatLiveClient prayers', () {
    test('liveUri scopes the socket to an event', () {
      final uri = ChatLiveClient.liveUri(
        restBaseUrl: 'https://api.example.com/api/v1',
        token: 'tok',
        eventId: 'e1',
        roomId: 'r1',
      );
      expect(uri.path, '/api/v1/chat/live');
      expect(uri.queryParameters['event_id'], 'e1');
      expect(uri.queryParameters['room_id'], 'r1');
      expect(uri.queryParameters.containsKey('group_id'), isFalse);
    });

    test('parses a prayers_updated frame covering a batch', () {
      final event = ChatLiveClient.parseFrame(
        '{"type":"prayers_updated","prayers":['
        '{"message_id":"a1","prayer_count":12,"user_ids":["u1","u2"]},'
        '{"message_id":"b2","prayer_count":4,"user_ids":[]}]}',
      );

      expect(event, isA<ChatLivePrayersUpdated>());
      final prayers = (event! as ChatLivePrayersUpdated).prayers;
      expect(prayers, hasLength(2));
      expect(prayers.first.messageId, 'a1');
      expect(prayers.first.prayerCount, 12);
      expect(prayers.first.userIds, ['u1', 'u2']);
      expect(prayers.last.userIds, isEmpty);
    });

    test('parses a room_closed frame', () {
      final event = ChatLiveClient.parseFrame(
        '{"type":"room_closed","reason":"EVENT_CHAT_DISABLED"}',
      );
      expect(event, isA<ChatLiveRoomClosed>());
      expect((event! as ChatLiveRoomClosed).reason, 'EVENT_CHAT_DISABLED');
    });

    test('encodeMessage carries message_type only when given', () {
      final plain = jsonDecode(ChatLiveClient.encodeMessage(body: 'hi'));
      expect(plain, {'type': 'message', 'body': 'hi'});

      final prayer = jsonDecode(
        ChatLiveClient.encodeMessage(body: 'pray', messageType: 'PRAYER'),
      );
      expect(prayer, {
        'type': 'message',
        'body': 'pray',
        'message_type': 'PRAYER',
      });
    });
  });
}
