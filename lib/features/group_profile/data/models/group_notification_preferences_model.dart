import 'package:flutter_pecha/features/group_profile/domain/entities/group_notification_preferences.dart';

/// Backend notification types behind the two toggles the sheet shows.
///
/// The backend keeps one row per type; the app collapses them into "Group
/// chat" and "Group content". Reminders for joined events are deliberately
/// not part of content, and series is global-only on the backend, so neither
/// appears here.
abstract final class GroupNotificationTypes {
  static const String chatMessage = 'CHAT_MESSAGE';
  static const String groupPost = 'GROUP_POST';
  static const String event = 'EVENT';
  static const String accumulation = 'ACCUMULATION';

  static const List<String> chat = [chatMessage];
  static const List<String> content = [groupPost, event, accumulation];
}

/// Wire shape of `GET` / `PATCH /users/me/notification-preferences/groups/{id}`:
///
/// ```json
/// {
///   "group_id": "…", "channel": "PUSH",
///   "preferences": [
///     { "notification_type": "CHAT_MESSAGE", "enabled": true,
///       "muted_until": null, "source": "DEFAULT" },
///     …
///   ]
/// }
/// ```
///
/// A toggle reads on only when every type behind it is enabled and not
/// currently muted; a type the backend does not list falls back to the
/// default, on. A tap writes every type behind the toggle to the same value.
class GroupNotificationPreferencesModel {
  final bool chat;
  final bool content;

  const GroupNotificationPreferencesModel({
    required this.chat,
    required this.content,
  });

  factory GroupNotificationPreferencesModel.fromJson(
    Map<String, dynamic> json, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now().toUtc();
    final delivering = <String, bool>{};
    final entries = json['preferences'];
    if (entries is List) {
      for (final entry in entries.whereType<Map<String, dynamic>>()) {
        final type = entry['notification_type'] as String?;
        if (type == null) continue;
        delivering[type] = _isDelivering(entry, clock);
      }
    }
    bool allOn(List<String> types) =>
        types.every((type) => delivering[type] ?? true);
    return GroupNotificationPreferencesModel(
      chat: allOn(GroupNotificationTypes.chat),
      content: allOn(GroupNotificationTypes.content),
    );
  }

  /// Enabled and not under an active `muted_until`. A snooze set elsewhere
  /// would otherwise read as on while nothing arrives.
  static bool _isDelivering(Map<String, dynamic> entry, DateTime now) {
    final enabled = entry['enabled'] as bool? ?? true;
    if (!enabled) return false;
    final mutedRaw = entry['muted_until'];
    if (mutedRaw is! String || mutedRaw.isEmpty) return true;
    final mutedUntil = DateTime.tryParse(mutedRaw)?.toUtc();
    return mutedUntil == null || !mutedUntil.isAfter(now);
  }

  /// Body for the PATCH request. Only the toggles the caller passes are sent,
  /// and each expands to every type behind it, so one toggle never clobbers
  /// the other from a stale value. Turning a toggle on also clears any
  /// snooze on those types (an explicit `null` lifts it, an absent key does
  /// not), so the switch and delivery agree afterwards.
  static Map<String, dynamic> toRequestJson({bool? chat, bool? content}) {
    Map<String, dynamic> entry(String type, bool enabled) => {
      'notification_type': type,
      'enabled': enabled,
      if (enabled) 'muted_until': null,
    };
    return {
      'preferences': [
        if (chat != null)
          for (final type in GroupNotificationTypes.chat) entry(type, chat),
        if (content != null)
          for (final type in GroupNotificationTypes.content)
            entry(type, content),
      ],
    };
  }

  GroupNotificationPreferences toEntity() {
    return GroupNotificationPreferences(chat: chat, content: content);
  }
}
