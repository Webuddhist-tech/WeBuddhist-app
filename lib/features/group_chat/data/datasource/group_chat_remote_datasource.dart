import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_member_dto.dart';

class ChatRoomsPage {
  final List<ChatRoomDTO> rooms;
  final int skip;
  final int limit;
  final int total;

  const ChatRoomsPage({
    required this.rooms,
    required this.skip,
    required this.limit,
    required this.total,
  });
}

class ChatMessagesPage {
  final List<ChatMessageDTO> messages;
  final int skip;
  final int limit;
  final int total;

  const ChatMessagesPage({
    required this.messages,
    required this.skip,
    required this.limit,
    required this.total,
  });
}

class ChatRoomMembersPage {
  final List<ChatRoomMemberDTO> members;
  final int skip;
  final int limit;
  final int total;

  const ChatRoomMembersPage({
    required this.members,
    required this.skip,
    required this.limit,
    required this.total,
  });
}

class GroupChatRemoteDatasource {
  GroupChatRemoteDatasource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static final _noCache = Options(extra: {'no_cache': true});

  Future<ChatRoomsPage> listRooms({int skip = 0, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/chat/rooms',
        queryParameters: {'skip': skip, 'limit': limit},
        options: _noCache,
      );
      final data = response.data as Map<String, dynamic>;
      return ChatRoomsPage(
        rooms:
            (data['rooms'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(ChatRoomDTO.fromJson)
                .toList() ??
            const [],
        skip: _readInt(data['skip']),
        limit: _readInt(data['limit']),
        total: _readInt(data['total']),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<ChatRoomDTO> getRoom(String roomId) async {
    try {
      final response = await _dio.get('/chat/rooms/$roomId', options: _noCache);
      return ChatRoomDTO.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<ChatMessagesPage> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/chat/rooms/$roomId/messages',
        queryParameters: {'skip': skip, 'limit': limit},
        options: _noCache,
      );
      final data = response.data as Map<String, dynamic>;
      return ChatMessagesPage(
        messages:
            (data['messages'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(ChatMessageDTO.fromJson)
                .toList() ??
            const [],
        skip: _readInt(data['skip']),
        limit: _readInt(data['limit']),
        total: _readInt(data['total']),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<ChatMessageDTO> sendGroupMessage(
    String groupId, {
    required String body,
    String? parentMessageId,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/groups/$groupId/messages',
        data: {
          'body': body,
          if (parentMessageId != null) 'parent_message_id': parentMessageId,
        },
      );
      return ChatMessageDTO.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  /// Active members of a room. Names only — the payload has no avatar field.
  Future<ChatRoomMembersPage> listRoomMembers(
    String roomId, {
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        '/chat/rooms/$roomId/members',
        queryParameters: {'skip': skip, 'limit': limit},
        options: _noCache,
      );
      final data = response.data as Map<String, dynamic>;
      return ChatRoomMembersPage(
        members:
            (data['members'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(ChatRoomMemberDTO.fromJson)
                .toList() ??
            const [],
        skip: _readInt(data['skip']),
        limit: _readInt(data['limit']),
        total: _readInt(data['total']),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  /// Reacts to a message. Idempotent, and returns the message's full updated
  /// reaction summary rather than an ack.
  Future<List<ChatMessageReactionDTO>> addReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/rooms/$roomId/messages/$messageId/reactions',
        data: {'emoji': emoji},
      );
      return _readReactions(response.data);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  /// Removes the caller's reaction. Idempotent, and returns the same full
  /// summary as [addReaction].
  ///
  /// The emoji travels in the path, so it must be percent-encoded — several of
  /// the quick reactions are multi-code-point sequences.
  Future<List<ChatMessageReactionDTO>> removeReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async {
    try {
      final encoded = Uri.encodeComponent(emoji);
      final response = await _dio.delete(
        '/chat/rooms/$roomId/messages/$messageId/reactions/$encoded',
      );
      return _readReactions(response.data);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  static List<ChatMessageReactionDTO> _readReactions(Object? data) {
    return (data as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(ChatMessageReactionDTO.fromJson)
            .toList() ??
        const [];
  }

  /// Deletes one of the caller's own messages, for everyone. Returns 204
  /// with no body.
  ///
  /// Sender-only, enforced server side. Nothing is broadcast over the socket,
  /// so other members see it gone on their next fetch rather than live.
  Future<void> deleteMessage(String roomId, {required String messageId}) async {
    try {
      await _dio.delete('/chat/rooms/$roomId/messages/$messageId');
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  /// Reports a message. Returns 204 with no body.
  ///
  /// `description` is omitted rather than sent as null when there is nothing
  /// to say, so the payload carries only what the member actually chose.
  ///
  /// A second report of the same message answers 409 `ALREADY_REPORTED`.
  /// From the member's side that is not a failure — the report is on file —
  /// so it completes normally here, where the status is still in hand, rather
  /// than being told apart from a real rejection by its message text later.
  Future<void> reportMessage(
    String roomId, {
    required String messageId,
    required String reason,
    String? description,
  }) async {
    try {
      await _dio.post(
        '/chat/rooms/$roomId/messages/$messageId/report',
        data: {
          'reason': reason,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) return;
      throw _unwrap(e);
    }
  }

  /// Bumps the caller's `last_read_at`. Returns 204 with no body.
  Future<void> markRoomRead(String roomId) async {
    try {
      await _dio.post('/chat/rooms/$roomId/read');
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  static Exception _unwrap(DioException error) {
    final inner = error.error;
    if (inner is Exception) return inner;
    return NetworkException(error.message ?? 'Network error');
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
