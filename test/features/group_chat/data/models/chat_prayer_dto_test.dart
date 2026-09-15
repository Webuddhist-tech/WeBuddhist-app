import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_summary_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prayer request DTOs', () {
    test('a PRAYER message carries its prayer fields', () {
      final message = ChatMessageDTO.fromJson({
        'id': 'm1',
        'room_id': 'r1',
        'sender_id': 'u1',
        'sender_email': 'u1@example.com',
        'sender_name': 'Tenzin',
        'body': 'Please pray for my mother',
        'created_at': '2026-09-11T10:04:00+00:00',
        'message_type': 'PRAYER',
        'prayer_count': 12,
        'prayed_by_me': true,
        'recent_prayers': [
          {'user_id': 'u2', 'name': 'Pema', 'avatar_url': 'https://a/p.png'},
        ],
      });

      expect(message.isPrayerRequest, isTrue);
      expect(message.prayerCount, 12);
      expect(message.prayedByMe, isTrue);
      expect(message.recentPrayers, [
        const ChatPrayerUserDTO(
          userId: 'u2',
          name: 'Pema',
          avatarUrl: 'https://a/p.png',
        ),
      ]);
      expect(ChatMessageDTO.fromJson(message.toJson()), message);
    });

    test('a message without message_type is TEXT with no prayer fields', () {
      final message = ChatMessageDTO.fromJson({
        'id': 'm1',
        'room_id': 'r1',
        'sender_id': 'u1',
        'sender_email': 'u1@example.com',
        'body': 'hello',
        'created_at': '2026-09-11T10:04:00+00:00',
      });

      expect(message.isPrayerRequest, isFalse);
      expect(message.messageType, ChatMessageDTO.typeText);
      final json = message.toJson();
      expect(json['message_type'], 'TEXT');
      expect(json.containsKey('prayer_count'), isFalse);
      expect(json.containsKey('prayed_by_me'), isFalse);
      expect(json.containsKey('recent_prayers'), isFalse);
    });

    test('copyWith keeps message_type and rewrites prayer state', () {
      final message = ChatMessageDTO.fromJson({
        'id': 'm1',
        'room_id': 'r1',
        'sender_id': 'u1',
        'sender_email': 'u1@example.com',
        'body': 'hello',
        'created_at': '2026-09-11T10:04:00+00:00',
        'message_type': 'PRAYER',
        'prayer_count': 1,
        'prayed_by_me': false,
      });

      final updated = message.copyWith(prayerCount: 2, prayedByMe: true);
      expect(updated.isPrayerRequest, isTrue);
      expect(updated.prayerCount, 2);
      expect(updated.prayedByMe, isTrue);
      expect(updated.body, 'hello');
    });

    test('ChatPrayerSummaryDTO round-trips', () {
      final summary = ChatPrayerSummaryDTO.fromJson({
        'message_id': 'm1',
        'prayer_count': 4,
        'prayed_by_me': true,
        'created': false,
      });
      expect(summary.created, isFalse);
      expect(ChatPrayerSummaryDTO.fromJson(summary.toJson()), summary);
    });

    test('an EVENT room carries event_id instead of group_id', () {
      final room = ChatRoomDTO.fromJson({
        'id': 'r1',
        'created_by': 'u1',
        'kind': 'EVENT',
        'event_id': 'e1',
        'name': 'Tara puja',
        'updated_at': '2026-09-11T10:04:00+00:00',
      });
      expect(room.eventId, 'e1');
      expect(room.groupId, isNull);
      expect(ChatRoomDTO.fromJson(room.toJson()), room);
    });
  });
}
