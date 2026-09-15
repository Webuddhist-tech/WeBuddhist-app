import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_summary_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class GroupChatRepositoryImpl implements GroupChatRepository {
  GroupChatRepositoryImpl({required GroupChatRemoteDatasource remote})
    : _remote = remote;

  final GroupChatRemoteDatasource _remote;

  @override
  Future<Either<Failure, ChatRoomsPage>> listRooms({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      return Right(await _remote.listRooms(skip: skip, limit: limit));
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'listRooms'));
    }
  }

  @override
  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId) async {
    try {
      return Right(await _remote.getRoom(roomId));
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'getRoom'));
    }
  }

  @override
  Future<Either<Failure, ChatRoomDTO>> getEventRoom(String eventId) async {
    try {
      return Right(await _remote.getEventRoom(eventId));
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'getEventRoom'));
    }
  }

  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
    String? messageType,
  }) async {
    try {
      return Right(
        await _remote.listMessages(
          roomId,
          skip: skip,
          limit: limit,
          messageType: messageType,
        ),
      );
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'listMessages'));
    }
  }

  @override
  Future<Either<Failure, ChatMessageDTO>> sendGroupMessage(
    String groupId, {
    required String body,
    String? parentMessageId,
    String? messageType,
  }) async {
    try {
      return Right(
        await _remote.sendGroupMessage(
          groupId,
          body: body,
          parentMessageId: parentMessageId,
          messageType: messageType,
        ),
      );
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'sendGroupMessage'));
    }
  }

  @override
  Future<Either<Failure, ChatMessageDTO>> sendEventMessage(
    String eventId, {
    required String body,
    String? parentMessageId,
    String? messageType,
  }) async {
    try {
      return Right(
        await _remote.sendEventMessage(
          eventId,
          body: body,
          parentMessageId: parentMessageId,
          messageType: messageType,
        ),
      );
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'sendEventMessage'));
    }
  }

  @override
  Future<Either<Failure, List<ChatPrayerSummaryDTO>>> prayFor(
    String roomId, {
    required List<String> messageIds,
  }) async {
    try {
      return Right(await _remote.prayFor(roomId, messageIds: messageIds));
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'prayFor'));
    }
  }

  @override
  Future<Either<Failure, ChatPrayerSummaryDTO>> removePrayer(
    String messageId,
  ) async {
    try {
      return Right(await _remote.removePrayer(messageId));
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'removePrayer'));
    }
  }

  @override
  Future<Either<Failure, ChatRoomMembersPage>> listRoomMembers(
    String roomId, {
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      return Right(
        await _remote.listRoomMembers(roomId, skip: skip, limit: limit),
      );
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'listRoomMembers'));
    }
  }

  @override
  Future<Either<Failure, Unit>> markRoomRead(String roomId) async {
    try {
      await _remote.markRoomRead(roomId);
      return const Right(unit);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'markRoomRead'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMessage(
    String roomId, {
    required String messageId,
  }) async {
    try {
      await _remote.deleteMessage(roomId, messageId: messageId);
      return const Right(unit);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'deleteMessage'));
    }
  }

  @override
  Future<Either<Failure, Unit>> reportMessage(
    String roomId, {
    required String messageId,
    required String reason,
    String? description,
  }) async {
    try {
      await _remote.reportMessage(
        roomId,
        messageId: messageId,
        reason: reason,
        description: description,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'reportMessage'));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageReactionDTO>>> addReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async {
    try {
      return Right(
        await _remote.addReaction(roomId, messageId: messageId, emoji: emoji),
      );
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'addReaction'));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageReactionDTO>>> removeReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async {
    try {
      return Right(
        await _remote.removeReaction(
          roomId,
          messageId: messageId,
          emoji: emoji,
        ),
      );
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'removeReaction'));
    }
  }
}
