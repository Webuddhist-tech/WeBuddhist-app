import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_preferences.dart';

extension ConnectNotificationToggleWire on ConnectNotificationToggle {
  /// The backend `notification_type` behind this switch.
  String get notificationType => switch (this) {
    ConnectNotificationToggle.groupPosts => 'GROUP_POST',
    ConnectNotificationToggle.groupChats => 'CHAT_MESSAGE',
    ConnectNotificationToggle.prayerReceived => 'PRAYER_RECEIVED',
    ConnectNotificationToggle.prayerRequest => 'PRAYER_REQUEST',
  };
}

/// Wire shape of `GET` / `PATCH /users/me/notification-preferences`:
///
/// ```json
/// {
///   "channel": "PUSH",
///   "preferences": [
///     { "notification_type": "GROUP_POST", "enabled": true,
///       "muted_until": null, "source": "DEFAULT" },
///     …
///   ],
///   "group_overrides": [ … ]
/// }
/// ```
///
/// Only the four types behind [ConnectNotificationToggle] are read; the other
/// types and `group_overrides` are not shown anywhere yet. A switch reads on
/// only when its type is enabled and not currently muted. A type the backend
/// does not list, or lists without `enabled`, falls back to
/// [NotificationPreferences.defaults], which mirrors the backend default.
class NotificationPreferencesModel extends Equatable {
  final bool groupPosts;
  final bool groupChats;
  final bool prayerReceived;
  final bool prayerRequest;

  const NotificationPreferencesModel({
    required this.groupPosts,
    required this.groupChats,
    required this.prayerReceived,
    required this.prayerRequest,
  });

  factory NotificationPreferencesModel.fromJson(
    Map<String, dynamic> json, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now().toUtc();
    final byType = <String, Map<String, dynamic>>{};
    final entries = json['preferences'];
    if (entries is List) {
      for (final entry in entries.whereType<Map<String, dynamic>>()) {
        final type = entry['notification_type'] as String?;
        if (type == null) continue;
        byType[type] = entry;
      }
    }
    bool read(ConnectNotificationToggle toggle) {
      final fallback = NotificationPreferences.defaults.of(toggle);
      final entry = byType[toggle.notificationType];
      return entry == null
          ? fallback
          : _isDelivering(entry, clock, fallback: fallback);
    }

    return NotificationPreferencesModel(
      groupPosts: read(ConnectNotificationToggle.groupPosts),
      groupChats: read(ConnectNotificationToggle.groupChats),
      prayerReceived: read(ConnectNotificationToggle.prayerReceived),
      prayerRequest: read(ConnectNotificationToggle.prayerRequest),
    );
  }

  /// Enabled and not under an active `muted_until`. A snooze set elsewhere
  /// would otherwise read as on while nothing arrives.
  static bool _isDelivering(
    Map<String, dynamic> entry,
    DateTime now, {
    required bool fallback,
  }) {
    final enabled = entry['enabled'] as bool? ?? fallback;
    if (!enabled) return false;
    final mutedRaw = entry['muted_until'];
    if (mutedRaw is! String || mutedRaw.isEmpty) return true;
    final mutedUntil = DateTime.tryParse(mutedRaw)?.toUtc();
    return mutedUntil == null || !mutedUntil.isAfter(now);
  }

  /// Body for the PATCH request. Only the switches in [changes] are sent, so
  /// one switch never overwrites another from a stale value. Turning a switch
  /// on also clears any snooze on its type (an explicit `null` lifts it, an
  /// absent key does not), so the switch and delivery agree afterwards.
  static Map<String, dynamic> toRequestJson(
    Map<ConnectNotificationToggle, bool> changes,
  ) {
    return {
      'preferences': [
        for (final MapEntry(key: toggle, value: enabled) in changes.entries)
          {
            'notification_type': toggle.notificationType,
            'enabled': enabled,
            if (enabled) 'muted_until': null,
          },
      ],
    };
  }

  NotificationPreferences toEntity() {
    return NotificationPreferences(
      groupPosts: groupPosts,
      groupChats: groupChats,
      prayerReceived: prayerReceived,
      prayerRequest: prayerRequest,
    );
  }

  @override
  List<Object?> get props => [
    groupPosts,
    groupChats,
    prayerReceived,
    prayerRequest,
  ];
}
