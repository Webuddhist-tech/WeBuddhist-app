import 'package:equatable/equatable.dart';

/// One person praying: the `recent_prayers` avatar stack on a message, or a
/// row of the who-prayed roster (which adds email, time and their count).
class ChatPrayerUserDTO extends Equatable {
  final String userId;
  final String? name;
  final String? avatarUrl;
  final String? email;
  final String? createdAt;

  /// How many times this person prayed; 0 where the payload has no count.
  final int prayerCount;
  final String? lastPrayedAt;

  const ChatPrayerUserDTO({
    required this.userId,
    this.name,
    this.avatarUrl,
    this.email,
    this.createdAt,
    this.prayerCount = 0,
    this.lastPrayedAt,
  });

  factory ChatPrayerUserDTO.fromJson(Map<String, dynamic> json) {
    final count = json['prayer_count'];
    return ChatPrayerUserDTO(
      userId: json['user_id']?.toString() ?? '',
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      createdAt: json['created_at'] as String?,
      prayerCount: count is num ? count.toInt() : 0,
      lastPrayedAt: json['last_prayed_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (email != null) 'email': email,
      if (createdAt != null) 'created_at': createdAt,
      if (prayerCount > 0) 'prayer_count': prayerCount,
      if (lastPrayedAt != null) 'last_prayed_at': lastPrayedAt,
    };
  }

  @override
  List<Object?> get props => [
    userId,
    name,
    avatarUrl,
    email,
    createdAt,
    prayerCount,
    lastPrayedAt,
  ];
}
