import 'package:equatable/equatable.dart';

/// One person in a prayer request's `recent_prayers` avatar stack.
class ChatPrayerUserDTO extends Equatable {
  final String userId;
  final String? name;
  final String? avatarUrl;

  const ChatPrayerUserDTO({required this.userId, this.name, this.avatarUrl});

  factory ChatPrayerUserDTO.fromJson(Map<String, dynamic> json) {
    return ChatPrayerUserDTO(
      userId: json['user_id']?.toString() ?? '',
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }

  @override
  List<Object?> get props => [userId, name, avatarUrl];
}
