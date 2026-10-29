import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_room_cache.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';

/// Outcome of looking up the chat room that backs a group.
sealed class GroupChatRoomLookup {
  const GroupChatRoomLookup();
}

/// The group has a room this user can open.
class GroupChatRoomFound extends GroupChatRoomLookup {
  final String roomId;

  const GroupChatRoomFound(this.roomId);
}

/// The lookup itself failed, so the room is unknown for now; a flaky network
/// must never present an existing conversation as an empty one.
class GroupChatRoomUnavailable extends GroupChatRoomLookup {
  const GroupChatRoomUnavailable();
}

/// Finds the room for a group without requiring the user to send first.
///
/// The local cache is only a shortcut: it is checked first because it costs
/// one request, but a miss falls through to the server so a reinstall or a
/// fresh device still opens straight into the conversation.
class ResolveGroupChatRoom {
  ResolveGroupChatRoom({
    required GroupChatRepository repository,
    required GroupChatRoomCache cache,
  }) : _repository = repository,
       _cache = cache;

  final GroupChatRepository _repository;
  final GroupChatRoomCache _cache;

  Future<GroupChatRoomLookup> call({
    required String userId,
    required String groupId,
  }) async {
    if (groupId.isEmpty) return const GroupChatRoomUnavailable();
    final cached = await _readFromCache(userId: userId, groupId: groupId);
    if (cached != null) return cached;
    return _fetchGroupRoom(userId: userId, groupId: groupId);
  }

  /// Returns null when the cache cannot answer and the server should be asked.
  Future<GroupChatRoomLookup?> _readFromCache({
    required String userId,
    required String groupId,
  }) async {
    final roomId = await _cache.read(userId: userId, groupId: groupId);
    if (roomId == null) return null;
    final result = await _repository.getRoom(roomId);
    final room = result.fold<ChatRoomDTO?>((_) => null, (room) => room);
    if (room != null && room.id.isNotEmpty) return GroupChatRoomFound(room.id);
    final isStale = result.fold<bool>(
      (failure) => failure is NotFoundFailure,
      (_) => false,
    );
    if (!isStale) return const GroupChatRoomUnavailable();
    await _cache.clear(userId: userId, groupId: groupId);
    return null;
  }

  /// `GET /chat/groups/{id}/room` creates the room and joins the caller on
  /// first use, so a member always gets an id to listen on.
  Future<GroupChatRoomLookup> _fetchGroupRoom({
    required String userId,
    required String groupId,
  }) async {
    final result = await _repository.getGroupRoom(groupId);
    final room = result.fold<ChatRoomDTO?>((_) => null, (room) => room);
    if (room == null || room.id.isEmpty) return const GroupChatRoomUnavailable();
    await _cache.write(userId: userId, groupId: groupId, roomId: room.id);
    return GroupChatRoomFound(room.id);
  }
}
