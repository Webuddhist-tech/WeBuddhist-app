import 'package:flutter_pecha/features/group_profile/presentation/providers/group_notification_preferences_provider.dart';

/// What the chat header's bell shows and does.
enum ChatBellState {
  /// Stored value still loading: plain bell, not tappable yet.
  loading,

  /// The stored value could not be read: plain bell, a tap reads it again.
  unavailable,

  /// The app's master switch is off, so nothing is delivered whatever the
  /// group setting says: slashed bell, a tap explains and offers the way on.
  appOff,

  /// Chat pushes on for this group: plain bell, a tap mutes.
  on,

  /// Chat pushes muted for this group: slashed bell, a tap unmutes.
  off,
}

/// Resolves the bell from the group's push preferences and the app's master
/// switch. The master switch wins, matching the profile sheet, which greys its
/// toggles out while master is off.
ChatBellState chatBellStateFor(
  GroupNotificationPreferencesState prefs, {
  required bool masterOn,
}) {
  if (!masterOn) return ChatBellState.appOff;
  if (prefs.loadFailure != null) return ChatBellState.unavailable;
  if (prefs.isLoading) return ChatBellState.loading;
  return prefs.preferences.chat ? ChatBellState.on : ChatBellState.off;
}
