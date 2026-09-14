import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_parent_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';

class ChatMessageDTO extends Equatable {
  final String id;
  final String roomId;
  final String senderId;
  final String senderEmail;

  /// Display identity carried by the message itself. Null on rows written
  /// before the API supplied it, which is what keeps the directory lookup and
  /// the email fallback alive.
  final String? senderName;
  final String? senderAvatarUrl;
  final String body;
  final String createdAt;

  /// When the sender deleted this message, or null while it stands.
  ///
  /// Optional on the wire, and [body] stays required beside it — a deleted
  /// message can still arrive carrying its original text. Everything that
  /// decides whether a message is gone reads this field, never an empty body.
  final String? deletedAt;

  final ChatMessageParentDTO? parent;
  final List<ChatMessageReactionDTO> reactions;

  const ChatMessageDTO({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderEmail,
    this.senderName,
    this.senderAvatarUrl,
    required this.body,
    required this.createdAt,
    this.deletedAt,
    this.parent,
    this.reactions = const [],
  });

  factory ChatMessageDTO.fromJson(Map<String, dynamic> json) {
    final parentJson = json['parent'];
    return ChatMessageDTO(
      id: json['id'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderEmail: json['sender_email'] as String? ?? '',
      senderName: json['sender_name'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      deletedAt: json['deleted_at'] as String?,
      parent:
          parentJson is Map<String, dynamic>
              ? ChatMessageParentDTO.fromJson(parentJson)
              : null,
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ChatMessageReactionDTO.fromJson)
              .toList() ??
          const [],
    );
  }

  /// Additive: only the fields a live update rewrites are parameterised, so
  /// the task 0 round-trip tests are untouched.
  ///
  /// [deletedAt] only ever goes from null to a timestamp — nothing undeletes a
  /// message — so the usual `?? this` idiom loses nothing here.
  ChatMessageDTO copyWith({
    String? body,
    String? deletedAt,
    ChatMessageParentDTO? parent,
    List<ChatMessageReactionDTO>? reactions,
  }) {
    return ChatMessageDTO(
      id: id,
      roomId: roomId,
      senderId: senderId,
      senderEmail: senderEmail,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      body: body ?? this.body,
      createdAt: createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      parent: parent ?? this.parent,
      reactions: reactions ?? this.reactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'sender_email': senderEmail,
      if (senderName != null) 'sender_name': senderName,
      if (senderAvatarUrl != null) 'sender_avatar_url': senderAvatarUrl,
      'body': body,
      'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (parent != null) 'parent': parent!.toJson(),
      'reactions': reactions.map((reaction) => reaction.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    roomId,
    senderId,
    senderEmail,
    senderName,
    senderAvatarUrl,
    body,
    createdAt,
    deletedAt,
    parent,
    reactions,
  ];
}
