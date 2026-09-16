import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Events received on `WS /chat/live`.
sealed class ChatLiveEvent {
  const ChatLiveEvent();
}

class ChatLiveRoomInfo extends ChatLiveEvent {
  final String roomId;
  const ChatLiveRoomInfo({required this.roomId});
}

class ChatLiveMessageCreated extends ChatLiveEvent {
  final Map<String, dynamic> message;
  const ChatLiveMessageCreated({required this.message});
}

class ChatLiveReactionsUpdated extends ChatLiveEvent {
  final String messageId;
  final List<dynamic> reactions;
  const ChatLiveReactionsUpdated({
    required this.messageId,
    required this.reactions,
  });
}

/// A message was deleted for everyone.
///
/// [deletedBy] is carried even though the tombstone label does not currently
/// need it — deletion is sender-only, so the deleter is always the sender. It
/// becomes the right signal the day moderators can delete, and dropping a
/// field the server sends only hides it from whoever reads this next.
class ChatLiveMessageDeleted extends ChatLiveEvent {
  final String messageId;
  final String deletedBy;
  final String deletedAt;
  const ChatLiveMessageDeleted({
    required this.messageId,
    required this.deletedBy,
    required this.deletedAt,
  });
}

class ChatLiveTyping extends ChatLiveEvent {
  final String userId;
  final String email;
  final bool isTyping;
  const ChatLiveTyping({
    required this.userId,
    required this.email,
    required this.isTyping,
  });
}

class ChatLivePresence extends ChatLiveEvent {
  final int count;
  final List<dynamic> online;
  const ChatLivePresence({required this.count, required this.online});
}

/// Someone prayed or un-prayed. One frame covers a whole batch.
class ChatLivePrayersUpdated extends ChatLiveEvent {
  final List<ChatLivePrayerUpdate> prayers;
  const ChatLivePrayersUpdated({required this.prayers});
}

/// Shared by every member: derive `prayed_by_me` from [userIds].
class ChatLivePrayerUpdate {
  final String messageId;
  final int prayerCount;
  final List<String> userIds;
  const ChatLivePrayerUpdate({
    required this.messageId,
    required this.prayerCount,
    required this.userIds,
  });

  factory ChatLivePrayerUpdate.fromJson(Map<String, dynamic> json) {
    final count = json['prayer_count'];
    return ChatLivePrayerUpdate(
      messageId: json['message_id'] as String? ?? '',
      prayerCount: count is num ? count.toInt() : 0,
      userIds:
          (json['user_ids'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          const [],
    );
  }
}

/// The room stopped serving: chat switched off, event deleted, group
/// unpublished.
class ChatLiveRoomClosed extends ChatLiveEvent {
  final String reason;
  const ChatLiveRoomClosed({required this.reason});
}

class ChatLiveError extends ChatLiveEvent {
  final String code;
  final String message;
  const ChatLiveError({required this.code, required this.message});
}

class ChatLiveUnknown extends ChatLiveEvent {
  final Map<String, dynamic> raw;
  const ChatLiveUnknown({required this.raw});
}

/// Builds and talks to `WS /chat/live`.
class ChatLiveClient {
  ChatLiveClient({WebSocketChannel Function(Uri uri)? connect})
    : _connect = connect ?? WebSocketChannel.connect;

  final WebSocketChannel Function(Uri uri) _connect;
  WebSocketChannel? _channel;

  /// Exactly one of [groupId] / [eventId] scopes the socket.
  static Uri liveUri({
    required String restBaseUrl,
    required String token,
    String? groupId,
    String? eventId,
    String? roomId,
  }) {
    assert(
      (groupId != null) != (eventId != null),
      'liveUri needs exactly one of groupId or eventId',
    );
    final rest = Uri.parse(restBaseUrl);
    final scheme = rest.scheme == 'http' ? 'ws' : 'wss';
    final basePath = rest.path.replaceAll(RegExp(r'/+$'), '');
    return rest.replace(
      scheme: scheme,
      path: '$basePath/chat/live',
      queryParameters: {
        'token': token,
        if (groupId != null) 'group_id': groupId,
        if (eventId != null) 'event_id': eventId,
        if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
      },
    );
  }

  /// Parses a server JSON frame. Unknown or invalid payloads become
  /// [ChatLiveUnknown] or null if [raw] is not JSON.
  static ChatLiveEvent? parseFrame(String raw) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    final json = Map<String, dynamic>.from(decoded);
    final type = json['type'] as String? ?? '';
    return switch (type) {
      'room_info' => ChatLiveRoomInfo(roomId: json['room_id'] as String? ?? ''),
      'message_created' => ChatLiveMessageCreated(
        message:
            json['message'] is Map
                ? Map<String, dynamic>.from(json['message'] as Map)
                : const {},
      ),
      'reactions_updated' => ChatLiveReactionsUpdated(
        messageId: json['message_id'] as String? ?? '',
        reactions: json['reactions'] as List<dynamic>? ?? const [],
      ),
      'message_deleted' => ChatLiveMessageDeleted(
        messageId: json['message_id'] as String? ?? '',
        deletedBy: json['deleted_by'] as String? ?? '',
        deletedAt: json['deleted_at'] as String? ?? '',
      ),
      'typing' => ChatLiveTyping(
        userId: json['user_id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        isTyping: json['is_typing'] as bool? ?? false,
      ),
      'presence' => ChatLivePresence(
        count: json['count'] is num ? (json['count'] as num).toInt() : 0,
        online: json['online'] as List<dynamic>? ?? const [],
      ),
      'prayers_updated' => ChatLivePrayersUpdated(
        prayers:
            (json['prayers'] as List<dynamic>?)
                ?.whereType<Map>()
                .map(
                  (item) => ChatLivePrayerUpdate.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList() ??
            const [],
      ),
      'room_closed' => ChatLiveRoomClosed(
        reason: json['reason'] as String? ?? '',
      ),
      'error' => ChatLiveError(
        code: json['code'] as String? ?? '',
        message: json['message'] as String? ?? '',
      ),
      _ => ChatLiveUnknown(raw: json),
    };
  }

  static String encodeMessage({
    required String body,
    String? parentMessageId,
    String? messageType,
  }) {
    return jsonEncode({
      'type': 'message',
      'body': body,
      if (parentMessageId != null) 'parent_message_id': parentMessageId,
      if (messageType != null) 'message_type': messageType,
    });
  }

  static String encodeTyping({required bool isTyping}) {
    return jsonEncode({'type': 'typing', 'is_typing': isTyping});
  }

  Stream<ChatLiveEvent> connect(Uri uri) {
    _channel = _connect(uri);
    return _channel!.stream.map((event) {
      try {
        final parsed = parseFrame(event.toString());
        return parsed ?? const ChatLiveUnknown(raw: {});
      } on FormatException {
        return const ChatLiveUnknown(raw: {});
      }
    });
  }

  void sendMessage({
    required String body,
    String? parentMessageId,
    String? messageType,
  }) {
    _channel?.sink.add(
      encodeMessage(
        body: body,
        parentMessageId: parentMessageId,
        messageType: messageType,
      ),
    );
  }

  void sendTyping({required bool isTyping}) {
    _channel?.sink.add(encodeTyping(isTyping: isTyping));
  }

  Future<void> dispose() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
