import 'package:equatable/equatable.dart';

/// A member's push-notification choices for one group.
///
/// Both flags default to `true` on the backend when the user joins, so a
/// fresh membership receives everything until the member opts out.
///
/// - [chat] gates group chat message pushes.
/// - [content] gates everything else the group sends: new posts, new events
///   and reminders for events the member joined.
///
/// Real-time delivery over the chat WebSocket is unaffected by either flag.
class GroupNotificationPreferences extends Equatable {
  final bool chat;
  final bool content;

  const GroupNotificationPreferences({
    required this.chat,
    required this.content,
  });

  /// Backend defaults for a member who never touched the toggles.
  static const GroupNotificationPreferences allOn =
      GroupNotificationPreferences(chat: true, content: true);

  GroupNotificationPreferences copyWith({bool? chat, bool? content}) {
    return GroupNotificationPreferences(
      chat: chat ?? this.chat,
      content: content ?? this.content,
    );
  }

  @override
  List<Object?> get props => [chat, content];
}
