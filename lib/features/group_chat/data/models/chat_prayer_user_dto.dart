import 'package:equatable/equatable.dart';

/// One person praying: the `recent_prayers` avatar stack on a message, or a
/// row of the who-prayed roster (which adds email and time).
class ChatPrayerUserDTO extends Equatable {
  final String userId;
  final String? name;
  final String? avatarUrl;
  final String? email;
  final String? createdAt;

  const ChatPrayerUserDTO({
    required this.userId,
    this.name,
    this.avatarUrl,
    this.email,
    this.createdAt,
  });

  factory ChatPrayerUserDTO.fromJson(Map<String, dynamic> json) {
    return ChatPrayerUserDTO(
      userId: json['user_id']?.toString() ?? '',
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (email != null) 'email': email,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => [userId, name, avatarUrl, email, createdAt];
}
