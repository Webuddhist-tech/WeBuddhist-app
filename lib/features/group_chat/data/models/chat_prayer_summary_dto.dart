import 'package:equatable/equatable.dart';

/// Per-message result of praying or un-praying.
class ChatPrayerSummaryDTO extends Equatable {
  final String messageId;
  final int prayerCount;
  final bool prayedByMe;

  /// True when this call added the prayer; false when it was already there.
  final bool created;

  const ChatPrayerSummaryDTO({
    required this.messageId,
    required this.prayerCount,
    required this.prayedByMe,
    this.created = false,
  });

  factory ChatPrayerSummaryDTO.fromJson(Map<String, dynamic> json) {
    final count = json['prayer_count'];
    return ChatPrayerSummaryDTO(
      messageId: json['message_id'] as String? ?? '',
      prayerCount: count is num ? count.toInt() : 0,
      prayedByMe: json['prayed_by_me'] as bool? ?? false,
      created: json['created'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'prayer_count': prayerCount,
      'prayed_by_me': prayedByMe,
      'created': created,
    };
  }

  @override
  List<Object?> get props => [messageId, prayerCount, prayedByMe, created];
}
