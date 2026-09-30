import 'package:equatable/equatable.dart';

/// A member's push-notification choices for one group.
///
/// A fresh membership gets [defaults]: chat off, content on. Chat pushes only
/// start once the member opts in. The backend owns delivery, so these must
/// match its default for a member with no stored choice; the app only mirrors
/// it (community-hub#339).
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

  /// Values for a member who never touched the toggles.
  static const GroupNotificationPreferences defaults =
      GroupNotificationPreferences(chat: false, content: true);

  GroupNotificationPreferences copyWith({bool? chat, bool? content}) {
    return GroupNotificationPreferences(
      chat: chat ?? this.chat,
      content: content ?? this.content,
    );
  }

  @override
  List<Object?> get props => [chat, content];
}
