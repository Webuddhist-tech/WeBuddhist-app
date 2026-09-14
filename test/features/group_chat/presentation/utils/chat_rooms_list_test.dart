import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_rooms_list.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessageDTO _message({
  String id = 'm1',
  String body = 'hello',
  String createdAt = '2026-09-01T10:00:00Z',
  String? deletedAt,
  String? senderName,
}) {
  return ChatMessageDTO(
    id: id,
    roomId: 'r1',
    senderId: 'u1',
    senderEmail: 'u1@example.com',
    senderName: senderName,
    body: body,
    createdAt: createdAt,
    deletedAt: deletedAt,
  );
}

ChatRoomDTO _room({
  required String id,
  String? groupId = 'g1',
  String updatedAt = '2026-09-01T10:00:00Z',
  int unreadCount = 0,
  ChatMessageDTO? lastMessage,
}) {
  return ChatRoomDTO(
    id: id,
    createdBy: 'u9',
    groupId: groupId,
    kind: 'group',
    name: 'Room $id',
    memberCount: 3,
    updatedAt: updatedAt,
    unreadCount: unreadCount,
    lastMessage: lastMessage,
  );
}

void main() {
  group('groupChatRooms', () {
    test('drops direct rooms, which have no group', () {
      final rooms = [
        _room(id: 'a'),
        _room(id: 'b', groupId: null),
        _room(id: 'c', groupId: ''),
      ];

      expect(groupChatRooms(rooms).map((r) => r.id), ['a']);
    });

    test('drops a room with no id, which cannot be opened', () {
      expect(groupChatRooms([_room(id: '')]), isEmpty);
    });

    test('orders most recently active first', () {
      final rooms = [
        _room(id: 'old', updatedAt: '2026-08-01T10:00:00Z'),
        _room(id: 'new', updatedAt: '2026-09-03T10:00:00Z'),
        _room(id: 'mid', updatedAt: '2026-09-01T10:00:00Z'),
      ];

      expect(groupChatRooms(rooms).map((r) => r.id), ['new', 'mid', 'old']);
    });

    test('a newer last message outranks a stale updated_at', () {
      final rooms = [
        _room(id: 'quiet', updatedAt: '2026-09-02T10:00:00Z'),
        // The room record was touched long ago, but someone just posted.
        _room(
          id: 'busy',
          updatedAt: '2026-08-01T10:00:00Z',
          lastMessage: _message(createdAt: '2026-09-03T10:00:00Z'),
        ),
      ];

      expect(groupChatRooms(rooms).map((r) => r.id), ['busy', 'quiet']);
    });

    test('ties break stably rather than shuffling between refreshes', () {
      final rooms = [_room(id: 'b'), _room(id: 'a')];

      expect(groupChatRooms(rooms).map((r) => r.id), ['a', 'b']);
      expect(groupChatRooms(rooms.reversed.toList()).map((r) => r.id), [
        'a',
        'b',
      ]);
    });
  });

  group('hasUnreadChatRooms', () {
    test('is true when any group room is unread', () {
      expect(
        hasUnreadChatRooms([_room(id: 'a'), _room(id: 'b', unreadCount: 2)]),
        isTrue,
      );
    });

    test('ignores unread direct rooms — this list is group chats', () {
      expect(
        hasUnreadChatRooms([_room(id: 'a', groupId: null, unreadCount: 5)]),
        isFalse,
      );
    });

    test('is false when everything is read', () {
      expect(hasUnreadChatRooms([_room(id: 'a')]), isFalse);
    });
  });

  group('isChatPushPayload', () {
    test('reads session_type', () {
      expect(isChatPushPayload({'session_type': 'CHAT'}), isTrue);
      expect(isChatPushPayload({'session_type': 'GROUP_POST'}), isFalse);
    });

    test('falls back to type, and is case and space insensitive', () {
      // Matching how resolvePushTap reads the same map, so the two cannot
      // disagree about what a chat push is.
      expect(isChatPushPayload({'type': ' chat '}), isTrue);
      expect(isChatPushPayload({'session_type': '', 'type': 'CHAT'}), isTrue);
    });

    test('an empty payload is not a chat push', () {
      expect(isChatPushPayload(const {}), isFalse);
    });
  });

  group('chatPushTargets', () {
    const chat = {'session_type': 'CHAT'};

    test('matches the room by source_id', () {
      // The backend sets source_id to the room id, not the group id.
      expect(
        chatPushTargets({...chat, 'source_id': 'r1'}, roomId: 'r1'),
        isTrue,
      );
      expect(
        chatPushTargets({...chat, 'source_id': 'other'}, roomId: 'r1'),
        isFalse,
      );
    });

    test('matches the group when the room is not yet known', () {
      // A thread opened by group can receive its first push before the room
      // id has been resolved.
      expect(
        chatPushTargets(
          {...chat, 'group_id': 'g1'},
          roomId: null,
          groupId: 'g1',
        ),
        isTrue,
      );
    });

    test('ignores a chat push for somewhere else', () {
      expect(
        chatPushTargets(
          {...chat, 'source_id': 'r9', 'group_id': 'g9'},
          roomId: 'r1',
          groupId: 'g1',
        ),
        isFalse,
      );
    });

    test('ignores a push that is not a chat message at all', () {
      expect(
        chatPushTargets({
          'session_type': 'GROUP_POST',
          'source_id': 'r1',
        }, roomId: 'r1'),
        isFalse,
      );
    });

    test('empty ids never match', () {
      expect(
        chatPushTargets({...chat, 'source_id': ''}, roomId: '', groupId: ''),
        isFalse,
      );
    });
  });

  group('chatRoomPreviewBody', () {
    test('is null for a room nobody has written in', () {
      expect(
        chatRoomPreviewBody(_room(id: 'a'), deletedLabel: 'deleted'),
        isNull,
      );
    });

    test('flattens newlines so the preview stays on two tidy lines', () {
      final room = _room(
        id: 'a',
        lastMessage: _message(body: 'first\n\n  second\nthird'),
      );

      expect(
        chatRoomPreviewBody(room, deletedLabel: 'deleted'),
        'first second third',
      );
    });

    test('a deleted message never shows its body', () {
      // The body still arrives on the wire; showing it would contradict the
      // tombstone one tap away.
      final room = _room(
        id: 'a',
        lastMessage: _message(
          body: 'the original text',
          deletedAt: '2026-09-03T11:00:00Z',
        ),
      );

      expect(chatRoomPreviewBody(room, deletedLabel: 'deleted'), 'deleted');
    });

    test('is null when the body is only whitespace', () {
      final room = _room(id: 'a', lastMessage: _message(body: '   \n  '));

      expect(chatRoomPreviewBody(room, deletedLabel: 'deleted'), isNull);
    });
  });
}
