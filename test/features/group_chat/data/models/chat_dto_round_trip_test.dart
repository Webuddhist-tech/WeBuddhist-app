import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_parent_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Section 2.5 DTO round-trip', () {
    test('ChatMessageParentDTO', () {
      const json = {
        'id': 'p1',
        'sender_id': 'u1',
        'sender_email': 'parent@example.com',
        'body': 'hello',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final first = ChatMessageParentDTO.fromJson(json);
      final encoded = first.toJson();
      expect(encoded['sender_email'], 'parent@example.com');
      expect(ChatMessageParentDTO.fromJson(encoded), first);
      // Absent until the backend adds it; must parse as "still standing".
      expect(first.deletedAt, isNull);
      expect(encoded.containsKey('deleted_at'), isFalse);
    });

    test('ChatMessageParentDTO carries deleted_at once the server sends it', () {
      const json = {
        'id': 'p1',
        'sender_id': 'u1',
        'sender_email': 'parent@example.com',
        'body': 'hello',
        'created_at': '2026-01-01T00:00:00Z',
        'deleted_at': '2026-01-02T00:00:00Z',
      };
      final first = ChatMessageParentDTO.fromJson(json);
      final encoded = first.toJson();
      expect(encoded['deleted_at'], '2026-01-02T00:00:00Z');
      expect(ChatMessageParentDTO.fromJson(encoded), first);
      // The first timestamp stands.
      expect(first.copyWith(deletedAt: 'later').deletedAt, 'later');
      expect(first.copyWith().deletedAt, '2026-01-02T00:00:00Z');
    });

    test('ChatMessageReactionUserDTO', () {
      const json = {
        'user_id': 'u2',
        'email': 'react@example.com',
        'name': 'Ada',
      };
      final first = ChatMessageReactionUserDTO.fromJson(json);
      final encoded = first.toJson();
      expect(encoded['user_id'], 'u2');
      expect(ChatMessageReactionUserDTO.fromJson(encoded), first);
    });

    test('ChatMessageReactionDTO', () {
      const json = {
        'emoji': '🙏',
        'count': 2,
        'reacted_by_me': true,
        'user_ids': ['u2', 'u3'],
        'users': [
          {'user_id': 'u2', 'email': 'a@b.c', 'name': 'A'},
        ],
      };
      final first = ChatMessageReactionDTO.fromJson(json);
      final encoded = first.toJson();
      expect(encoded['reacted_by_me'], isTrue);
      expect(encoded['user_ids'], ['u2', 'u3']);
      expect(ChatMessageReactionDTO.fromJson(encoded), first);
    });

    test('ChatMessageDTO with parent and reactions', () {
      const json = {
        'id': 'm1',
        'room_id': 'r1',
        'sender_id': 'u9',
        'sender_email': 'sender@example.com',
        'sender_name': 'Pema Yangchen',
        'sender_avatar_url': 'https://cdn.example/p.png',
        'body': 'metta',
        'created_at': '2026-01-02T00:00:00Z',
        'parent': {
          'id': 'p1',
          'sender_id': 'u1',
          'sender_email': 'parent@example.com',
          'sender_name': 'Tenzin Tamdin',
          'sender_avatar_url': 'images/profile_images/u1.webp',
          'body': 'hello',
          'created_at': '2026-01-01T00:00:00Z',
        },
        'reactions': [
          {
            'emoji': '🙏',
            'count': 1,
            'reacted_by_me': false,
            'user_ids': ['u2'],
            'users': [
              {'user_id': 'u2'},
            ],
          },
        ],
      };
      final first = ChatMessageDTO.fromJson(json);
      final encoded = first.toJson();
      expect(encoded['room_id'], 'r1');
      expect(encoded['sender_email'], 'sender@example.com');
      expect(encoded['sender_name'], 'Pema Yangchen');
      expect(encoded['sender_avatar_url'], 'https://cdn.example/p.png');
      final parent = encoded['parent'] as Map<String, dynamic>;
      expect(parent['sender_name'], 'Tenzin Tamdin');
      expect(parent['sender_avatar_url'], 'images/profile_images/u1.webp');
      expect(ChatMessageDTO.fromJson(encoded), first);
      // Absent on the wire and absent again on the way out, rather than
      // round-tripping as an explicit null.
      expect(first.deletedAt, isNull);
      expect(encoded.containsKey('deleted_at'), isFalse);
    });

    test('ChatMessageDTO carries deleted_at through a round trip', () {
      const json = {
        'id': 'm1',
        'room_id': 'r1',
        'sender_id': 'u9',
        'sender_email': 'sender@example.com',
        'body': 'metta',
        'created_at': '2026-01-02T00:00:00Z',
        // A deleted message still arrives with its body: nothing may infer
        // deletion from an empty one.
        'deleted_at': '2026-01-03T09:30:00Z',
      };

      final first = ChatMessageDTO.fromJson(json);
      expect(first.deletedAt, '2026-01-03T09:30:00Z');
      expect(first.body, 'metta');

      final encoded = first.toJson();
      expect(encoded['deleted_at'], '2026-01-03T09:30:00Z');
      expect(ChatMessageDTO.fromJson(encoded), first);
    });

    test('ChatMessageDTO tolerates a null deleted_at', () {
      const json = {
        'id': 'm1',
        'room_id': 'r1',
        'sender_id': 'u9',
        'sender_email': 'sender@example.com',
        'body': 'metta',
        'created_at': '2026-01-02T00:00:00Z',
        'deleted_at': null,
      };

      expect(ChatMessageDTO.fromJson(json).deletedAt, isNull);
    });

    test('ChatRoomDTO group room', () {
      const json = {
        'id': 'r1',
        'created_by': 'u9',
        'group_id': 'g1',
        'kind': 'GROUP',
        'name': 'Sangha',
        'img_url': 'https://cdn.example/g.png',
        'member_count': 12,
        'updated_at': '2026-01-03T00:00:00Z',
        'unread_count': 4,
        'last_message': {
          'id': 'm1',
          'room_id': 'r1',
          'sender_id': 'u9',
          'sender_email': 'sender@example.com',
          'body': 'metta',
          'created_at': '2026-01-02T00:00:00Z',
        },
      };
      final first = ChatRoomDTO.fromJson(json);
      final encoded = first.toJson();
      expect(encoded['img_url'], 'https://cdn.example/g.png');
      expect(encoded['unread_count'], 4);
      expect(encoded['group_id'], 'g1');
      expect(ChatRoomDTO.fromJson(encoded), first);
    });

    test('ChatRoomDTO private other_user fields', () {
      const json = {
        'id': 'r2',
        'created_by': 'u1',
        'sender_id': 'u1',
        'receiver_id': 'u2',
        'kind': 'PRIVATE',
        'name': 'Ada',
        'member_count': 2,
        'updated_at': '2026-01-03T00:00:00Z',
        'unread_count': 0,
        'other_user_id': 'u2',
        'other_user_email': 'ada@example.com',
        'other_user_name': 'Ada',
      };
      final first = ChatRoomDTO.fromJson(json);
      final encoded = first.toJson();
      expect(encoded['other_user_email'], 'ada@example.com');
      expect(ChatRoomDTO.fromJson(encoded), first);
    });
  });
}
