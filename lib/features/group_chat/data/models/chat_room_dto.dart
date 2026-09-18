import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';

class ChatRoomDTO extends Equatable {
  final String id;
  final String createdBy;
  final String? groupId;

  /// Set on an `EVENT` room, in place of [groupId].
  final String? eventId;
  final String? senderId;
  final String? receiverId;
  final String kind;
  final String name;
  final String? imgUrl;
  final int memberCount;
  final String updatedAt;
  final ChatMessageDTO? lastMessage;
  final int unreadCount;
  final String? otherUserId;
  final String? otherUserEmail;
  final String? otherUserName;

  const ChatRoomDTO({
    required this.id,
    required this.createdBy,
    this.groupId,
    this.eventId,
    this.senderId,
    this.receiverId,
    required this.kind,
    required this.name,
    this.imgUrl,
    this.memberCount = 0,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.otherUserId,
    this.otherUserEmail,
    this.otherUserName,
  });

  factory ChatRoomDTO.fromJson(Map<String, dynamic> json) {
    final lastMessageJson = json['last_message'];
    return ChatRoomDTO(
      id: json['id'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      groupId: json['group_id'] as String?,
      eventId: json['event_id'] as String?,
      senderId: json['sender_id'] as String?,
      receiverId: json['receiver_id'] as String?,
      kind: json['kind'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imgUrl: json['img_url'] as String?,
      memberCount: _readInt(json['member_count']),
      updatedAt: json['updated_at'] as String? ?? '',
      lastMessage:
          lastMessageJson is Map<String, dynamic>
              ? ChatMessageDTO.fromJson(lastMessageJson)
              : null,
      unreadCount: _readInt(json['unread_count']),
      otherUserId: json['other_user_id']?.toString(),
      otherUserEmail: json['other_user_email'] as String?,
      otherUserName: json['other_user_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy,
      if (groupId != null) 'group_id': groupId,
      if (eventId != null) 'event_id': eventId,
      if (senderId != null) 'sender_id': senderId,
      if (receiverId != null) 'receiver_id': receiverId,
      'kind': kind,
      'name': name,
      if (imgUrl != null) 'img_url': imgUrl,
      'member_count': memberCount,
      'updated_at': updatedAt,
      if (lastMessage != null) 'last_message': lastMessage!.toJson(),
      'unread_count': unreadCount,
      if (otherUserId != null) 'other_user_id': otherUserId,
      if (otherUserEmail != null) 'other_user_email': otherUserEmail,
      if (otherUserName != null) 'other_user_name': otherUserName,
    };
  }

  @override
  List<Object?> get props => [
    id,
    createdBy,
    groupId,
    eventId,
    senderId,
    receiverId,
    kind,
    name,
    imgUrl,
    memberCount,
    updatedAt,
    lastMessage,
    unreadCount,
    otherUserId,
    otherUserEmail,
    otherUserName,
  ];
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}
