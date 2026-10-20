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
  String? eventId,
  String? otherUserId,
  String updatedAt = '2026-09-01T10:00:00Z',
  int unreadCount = 0,
  ChatMessageDTO? lastMessage,
}) {
  return ChatRoomDTO(
    id: id,
    createdBy: 'u9',
    groupId: groupId,
    eventId: eventId,
    kind: 'group',
    name: 'Room $id',
    memberCount: 3,
    updatedAt: updatedAt,
    unreadCount: unreadCount,
    lastMessage: lastMessage,
    otherUserId: otherUserId,
  );
}

ChatRoomDTO _direct({required String id, int unreadCount = 0}) =>
    _room(id: id, groupId: null, otherUserId: 'team', unreadCount: unreadCount);

void main() {
  group('isDirectChatRoom', () {
    test('is a room with no group or event that names the other person', () {
      expect(isDirectChatRoom(_direct(id: 'd')), isTrue);
    });

    test('a group or event room is not direct', () {
      expect(isDirectChatRoom(_room(id: 'g', otherUserId: 'u2')), isFalse);
      expect(
        isDirectChatRoom(
          _room(id: 'e', groupId: null, eventId: 'ev1', otherUserId: 'u2'),
        ),
        isFalse,
      );
    });

    test('a room without the other person cannot be replied to', () {
      expect(isDirectChatRoom(_room(id: 'x', groupId: null)), isFalse);
      expect(
        isDirectChatRoom(_room(id: 'x', groupId: null, otherUserId: '')),
        isFalse,
      );
    });
  });

  group('chatListRooms', () {
    test('keeps group and direct rooms, drops event rooms', () {
      final rooms = [
        _room(id: 'a'),
        _room(id: 'b', groupId: null),
        _room(id: 'c', groupId: ''),
        _room(id: 'e', groupId: null, eventId: 'ev1'),
        _direct(id: 'd'),
      ];

      expect(chatListRooms(rooms).map((r) => r.id), ['a', 'd']);
    });

    test('drops a room with no id, which cannot be opened', () {
      expect(chatListRooms([_room(id: '')]), isEmpty);
      expect(chatListRooms([_direct(id: '')]), isEmpty);
    });

    test('orders direct and group rooms together by recency', () {
      final rooms = [
        _room(id: 'group', updatedAt: '2026-09-01T10:00:00Z'),
        _room(
          id: 'team',
          groupId: null,
          otherUserId: 'team',
          updatedAt: '2026-09-02T10:00:00Z',
        ),
      ];

      expect(chatListRooms(rooms).map((r) => r.id), ['team', 'group']);
    });

    test('orders most recently active first', () {
      final rooms = [
        _room(id: 'old', updatedAt: '2026-08-01T10:00:00Z'),
        _room(id: 'new', updatedAt: '2026-09-03T10:00:00Z'),
        _room(id: 'mid', updatedAt: '2026-09-01T10:00:00Z'),
      ];

      expect(chatListRooms(rooms).map((r) => r.id), ['new', 'mid', 'old']);
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

      expect(chatListRooms(rooms).map((r) => r.id), ['busy', 'quiet']);
    });

    test('ties break stably rather than shuffling between refreshes', () {
      final rooms = [_room(id: 'b'), _room(id: 'a')];

      expect(chatListRooms(rooms).map((r) => r.id), ['a', 'b']);
      expect(chatListRooms(rooms.reversed.toList()).map((r) => r.id), [
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

    test('counts an unread direct room, such as a reply from the Team', () {
      expect(hasUnreadChatRooms([_direct(id: 'd', unreadCount: 1)]), isTrue);
    });

    test('ignores unread event rooms, which are not in the list', () {
      expect(
        hasUnreadChatRooms([
          _room(id: 'e', groupId: null, eventId: 'ev1', unreadCount: 5),
        ]),
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

    test('a Help & contact message previews what the user wrote', () {
      final room = _room(
        id: 'd',
        groupId: null,
        otherUserId: 'team',
        lastMessage: _message(
          body:
              'Sent from Help & contact · Help or collaborate\n\n'
              'I translate dharma texts into Nepali',
        ),
      );

      expect(
        chatRoomPreviewBody(room, deletedLabel: 'deleted'),
        'I translate dharma texts into Nepali',
      );
    });
  });
}
