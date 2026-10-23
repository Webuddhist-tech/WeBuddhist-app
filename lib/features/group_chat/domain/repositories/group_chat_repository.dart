import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_summary_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class GroupChatRepository {
  Future<Either<Failure, ChatRoomsPage>> listRooms({
    int skip = 0,
    int limit = 20,
  });

  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId);

  Future<Either<Failure, ChatRoomDTO>> getEventRoom(String eventId);

  Future<Either<Failure, ChatRoomDTO>> getGroupRoom(String groupId);

  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
    String? messageType,
    String? sort,
    String? intention,
    String? translationLanguage,
  });

  Future<Either<Failure, ChatMessageDTO>> sendGroupMessage(
    String groupId, {
    required String body,
    String? parentMessageId,
    String? messageType,
    String? intention,
  });

  Future<Either<Failure, ChatMessageDTO>> sendEventMessage(
    String eventId, {
    required String body,
    String? parentMessageId,
    String? messageType,
    String? intention,
  });

  /// Sends [body] to the direct room the viewer shares with [userId].
  Future<Either<Failure, ChatMessageDTO>> sendDirectMessage(
    String userId, {
    required String body,
    String? parentMessageId,
  });

  Future<Either<Failure, List<ChatPrayerIntentionDTO>>> listIntentions();

  Future<Either<Failure, List<ChatPrayerSummaryDTO>>> prayFor(
    String roomId, {
    required List<String> messageIds,
    int count = 1,
  });

  /// The caller's own prayer requests; [eventId] keeps to one event's chat.
  Future<Either<Failure, ChatMessagesPage>> listMyPrayerRequests({
    int skip = 0,
    int limit = 20,
    String? eventId,
    bool? isCompleted,
  });

  /// One request for the caller to pray for; Left(NotFoundFailure) when
  /// nobody else has posted one.
  Future<Either<Failure, ChatMessageDTO>> pickRandomPrayerRequest(
    String roomId, {
    List<String> excludeIds = const [],
    String? translationLanguage,
  });

  Future<Either<Failure, ChatPrayersPage>> listPrayers(
    String messageId, {
    int skip = 0,
    int limit = 20,
  });

  Future<Either<Failure, ChatRoomMembersPage>> listRoomMembers(
    String roomId, {
    int skip = 0,
    int limit = 100,
  });

  Future<Either<Failure, Unit>> markRoomRead(String roomId);

  /// Right with the server's copy, or null when it answered without one.
  Future<Either<Failure, ChatMessageDTO?>> updateMessage(
    String roomId, {
    required String messageId,
    required String body,
    String? intention,
  });

  /// Marks one of the caller's own prayer requests accomplished or active.
  /// Right with the server's copy, or null when it answered without one.
  Future<Either<Failure, ChatMessageDTO?>> setMessageCompleted(
    String roomId, {
    required String messageId,
    required bool isCompleted,
  });

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
