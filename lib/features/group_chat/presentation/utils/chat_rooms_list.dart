import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_message_time.dart';

/// The group rooms among [rooms], most recently active first.
///
/// `/chat/rooms` also returns direct messages — the DTO carries `sender_id`,
/// `receiver_id` and `other_user_*` — and this list is group chats only.
/// Membership is decided by `group_id` rather than `kind`: the spec types
/// `kind` as a bare string with no enum and nothing in the app reads it, while
/// `resolve_group_chat_room` already identifies a group room by its `group_id`.
/// One rule, already proven.
///
/// Sorted here rather than trusted from the server: the endpoint documents no
/// ordering, and "most recent first" is the requirement.
List<ChatRoomDTO> groupChatRooms(List<ChatRoomDTO> rooms) {
  final groups =
      rooms
          .where(
            (room) => (room.groupId ?? '').isNotEmpty && room.id.isNotEmpty,
          )
          .toList();

  groups.sort((a, b) {
    final byRecency = chatRoomSortKey(b).compareTo(chatRoomSortKey(a));
    if (byRecency != 0) return byRecency;
    // A stable tiebreak, so rooms with identical timestamps do not swap
    // places between refreshes.
    return a.id.compareTo(b.id);
  });
  return groups;
}

/// When a room last changed, for ordering.
///
/// The last message wins over `updated_at` when it is newer: `updated_at` also
/// moves for edits to the room itself, and an ordering that disagrees with the
/// visible preview line reads as a bug.
DateTime chatRoomSortKey(ChatRoomDTO room) {
  final updated = parseChatTimestamp(room.updatedAt);
  final message = room.lastMessage;
  if (message == null) return updated;

  final sent = message.createdAtLocal;
  return sent.isAfter(updated) ? sent : updated;
}

/// Whether the room has anything unread.
bool chatRoomIsUnread(ChatRoomDTO room) => room.unreadCount > 0;

/// Whether any group room has something unread — the Connect dot.
bool hasUnreadChatRooms(List<ChatRoomDTO> rooms) {
  return groupChatRooms(rooms).any(chatRoomIsUnread);
}

/// Whether an FCM payload is a chat message.
///
/// Mirrors how `resolvePushTap` reads the same map — `session_type` first,
/// falling back to `type`, upper-cased — so the two cannot disagree about what
/// a chat push is.
bool isChatPushPayload(Map<String, dynamic> data) {
  final session = (data['session_type'] as String?)?.trim();
  final raw =
      session != null && session.isNotEmpty
          ? session
          : (data['type'] as String?)?.trim() ?? '';
  return raw.toUpperCase() == 'CHAT';
}

/// The room a chat push names. The backend sets `source_id` to the room id.
String chatPushRoomId(Map<String, dynamic> data) =>
    (data['source_id'] as String?)?.trim() ?? '';

/// The group a chat push names.
String chatPushGroupId(Map<String, dynamic> data) =>
    (data['group_id'] as String?)?.trim() ?? '';

/// Whether a chat push is about the room or group currently on screen.
bool chatPushTargets(
  Map<String, dynamic> data, {
  String? roomId,
  String? groupId,
}) {
  if (!isChatPushPayload(data)) return false;

  final room = (roomId ?? '').trim();
  if (room.isNotEmpty && chatPushRoomId(data) == room) return true;

  final group = (groupId ?? '').trim();
  return group.isNotEmpty && chatPushGroupId(data) == group;
}

/// The preview line's message text, with newlines flattened so a multi-line
/// message stays tidy on two lines.
///
/// Returns null when the room has never been written in, and [deletedLabel]
/// when the last message has been deleted — a deleted message still arrives
/// carrying its body, and showing that here would contradict the tombstone one
/// tap away.
String? chatRoomPreviewBody(ChatRoomDTO room, {required String deletedLabel}) {
  final message = room.lastMessage;
  if (message == null) return null;
  if (message.deletedAt != null) return deletedLabel;

  final body = message.body.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();
  return body.isEmpty ? null : body;
}
