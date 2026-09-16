import 'dart:async';

import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('GroupChatAnalytics');

/// How the screen came to have a room, carried on `group_chat_joined`.
enum ChatJoinSource {
  /// The lookup on open found the group's existing room.
  resolved,

  /// This member's first send created the room.
  firstSend,

  /// The socket reported a room another member created while this screen
  /// was open.
  live,
}

/// What a confirmed reaction toggle did on the server.
enum ChatReactionAction { added, removed, swapped }

/// Names the toggle from what the member held on the message before the tap.
/// Mirrors how the thread decides between a POST, a DELETE and a swap.
ChatReactionAction chatReactionActionFor({
  required String? previousEmoji,
  required String emoji,
}) {
  if (previousEmoji == null) return ChatReactionAction.added;
  if (previousEmoji == emoji) return ChatReactionAction.removed;
  return ChatReactionAction.swapped;
}

/// Product analytics for group chat: one method per tracked action, so the
/// event names and their property keys live in one place.
///
/// Every method fires and forgets. Analytics must never delay a chat action
/// or turn a success into a failure, so a rejected capture is only logged.
/// Callers fire these after the server confirms, never optimistically.
class GroupChatAnalytics {
  const GroupChatAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// The screen has a room to talk in. Fired once per screen open by the
  /// screen itself; [source] says how the room was found.
  void chatJoined({
    required String groupId,
    required String roomId,
    required ChatJoinSource source,
  }) {
    _track(AnalyticsEvents.groupChatJoined, {
      AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.roomId: roomId,
      AnalyticsProperties.source: source.name,
    });
  }

  /// A message was accepted by the server. A reply is still a sent message,
  /// so it fires `group_message_sent` too, and `group_message_replied` on top.
  void messageSent({
    required String groupId,
    required String roomId,
    required String messageId,
    String? parentMessageId,
  }) {
    final isReply = parentMessageId != null && parentMessageId.isNotEmpty;
    _track(AnalyticsEvents.groupMessageSent, {
      AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.roomId: roomId,
      AnalyticsProperties.messageId: messageId,
      AnalyticsProperties.isReply: isReply,
    });
    if (!isReply) return;
    _track(AnalyticsEvents.groupMessageReplied, {
      AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.roomId: roomId,
      AnalyticsProperties.messageId: messageId,
      AnalyticsProperties.parentMessageId: parentMessageId,
    });
  }

  /// One event per message, whether it went through the bulk route or the
  /// one-call-each fallback.
  void messageDeleted({required String roomId, required String messageId}) {
    _track(AnalyticsEvents.groupMessageDeleted, {
      AnalyticsProperties.roomId: roomId,
      AnalyticsProperties.messageId: messageId,
    });
  }

  void messageReacted({
    required String roomId,
    required String messageId,
    required String emoji,
    required ChatReactionAction action,
  }) {
    _track(AnalyticsEvents.groupMessageReacted, {
      AnalyticsProperties.roomId: roomId,
      AnalyticsProperties.messageId: messageId,
      AnalyticsProperties.emoji: emoji,
      AnalyticsProperties.action: action.name,
    });
  }

  /// [reason] is the wire value sent to the server, not the localized label.
  void messageReported({
    required String roomId,
    required String messageId,
    required String reason,
  }) {
    _track(AnalyticsEvents.groupMessageReported, {
      AnalyticsProperties.roomId: roomId,
      AnalyticsProperties.messageId: messageId,
      AnalyticsProperties.reason: reason,
    });
  }

  void _track(String event, Map<String, Object?> properties) {
    unawaited(
      _analytics.track(event, properties: properties).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logger.warning('Failed to track $event', error, stackTrace);
      }),
    );
  }
}

final groupChatAnalyticsProvider = Provider<GroupChatAnalytics>((ref) {
  return GroupChatAnalytics(ref.watch(analyticsServiceProvider));
});
