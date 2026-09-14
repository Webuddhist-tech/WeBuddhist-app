import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class GroupChatRepository {
  Future<Either<Failure, ChatRoomsPage>> listRooms({
    int skip = 0,
    int limit = 20,
  });

  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId);

  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
  });

  Future<Either<Failure, ChatMessageDTO>> sendGroupMessage(
    String groupId, {
    required String body,
    String? parentMessageId,
  });

  Future<Either<Failure, ChatRoomMembersPage>> listRoomMembers(
    String roomId, {
    int skip = 0,
    int limit = 100,
  });

  Future<Either<Failure, Unit>> markRoomRead(String roomId);

  Future<Either<Failure, Unit>> deleteMessage(
    String roomId, {
    required String messageId,
  });

  /// One request for several messages, all or nothing. Left with
  /// `ChatBulkDeleteUnsupportedFailure` when the server has no such route.
  Future<Either<Failure, Unit>> deleteMessages(
    String roomId, {
    required List<String> messageIds,
  });

  Future<Either<Failure, Unit>> reportMessage(
    String roomId, {
    required String messageId,
    required String reason,
    String? description,
  });

  Future<Either<Failure, List<ChatMessageReactionDTO>>> addReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  });

  Future<Either<Failure, List<ChatMessageReactionDTO>>> removeReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  });
}
