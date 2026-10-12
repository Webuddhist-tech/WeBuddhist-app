import 'package:equatable/equatable.dart';

/// The server-backed switches in the Connect section of the notification
/// settings screen. The prayer pair is also offered from the prayer requests
/// sheet.
enum ConnectNotificationToggle {
  groupPosts,
  groupChats,
  prayerReceived,
  prayerRequest,
}

/// A user's account-wide push choices behind [ConnectNotificationToggle].
///
/// A choice made in a space's own notification sheet wins over these for
/// that space; these are what every space the user never customised follows.
class NotificationPreferences extends Equatable {
  /// New posts in the user's spaces.
  final bool groupPosts;

  /// Chat messages, in spaces and in direct messages alike.
  final bool groupChats;

  /// Someone prayed for one of the user's own prayer requests.
  final bool prayerReceived;

  /// Someone else posted a prayer request in an event the user attends.
  final bool prayerRequest;

  const NotificationPreferences({
    required this.groupPosts,
    required this.groupChats,
    required this.prayerReceived,
    required this.prayerRequest,
  });

  /// What the backend resolves for a user who never touched a switch: chat
  /// and other people's prayer requests are opt-in, the rest are on.
  static const NotificationPreferences defaults = NotificationPreferences(
    groupPosts: true,
    groupChats: false,
    prayerReceived: true,
    prayerRequest: false,
  );

  bool of(ConnectNotificationToggle toggle) => switch (toggle) {
    ConnectNotificationToggle.groupPosts => groupPosts,
    ConnectNotificationToggle.groupChats => groupChats,
    ConnectNotificationToggle.prayerReceived => prayerReceived,
    ConnectNotificationToggle.prayerRequest => prayerRequest,
  };

  NotificationPreferences withValue(
    ConnectNotificationToggle toggle,
    bool enabled,
  ) => switch (toggle) {
    ConnectNotificationToggle.groupPosts => copyWith(groupPosts: enabled),
    ConnectNotificationToggle.groupChats => copyWith(groupChats: enabled),
    ConnectNotificationToggle.prayerReceived => copyWith(
      prayerReceived: enabled,
    ),
    ConnectNotificationToggle.prayerRequest => copyWith(
      prayerRequest: enabled,
    ),
  };

  NotificationPreferences copyWith({
    bool? groupPosts,
    bool? groupChats,
    bool? prayerReceived,
    bool? prayerRequest,
  }) {
    return NotificationPreferences(
      groupPosts: groupPosts ?? this.groupPosts,
      groupChats: groupChats ?? this.groupChats,
      prayerReceived: prayerReceived ?? this.prayerReceived,
      prayerRequest: prayerRequest ?? this.prayerRequest,
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
