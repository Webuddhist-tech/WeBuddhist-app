/// PostHog event names using [object]_[verb] convention.
abstract final class AnalyticsEvents {
  // Auth
  static const String authLoginSucceeded = 'auth_login_succeeded';
  static const String authLoginFailed = 'auth_login_failed';
  static const String authGuestStarted = 'auth_guest_started';

  // Onboarding
  static const String onboardingCompleted = 'onboarding_completed';

  // Plans
  static const String planEnrolled = 'plan_enrolled';
  static const String planViewed = 'plan_viewed';
  static const String planDayCompleted = 'plan_day_completed';

  // Practice / Routine
  static const String routineSaved = 'routine_saved';

  // Mala
  static const String malaScreenOpened = 'mala_screen_opened';
  static const String malaRoundCompleted = 'mala_round_completed';
  static const String malaSynced = 'mala_synced';
  static const String malaMantraSwitched = 'mala_mantra_switched';

  // Group chat
  static const String groupChatJoined = 'group_chat_joined';
  static const String groupMessageSent = 'group_message_sent';
  static const String groupMessageDeleted = 'group_message_deleted';
  static const String groupMessageReacted = 'group_message_reacted';
  static const String groupMessageReplied = 'group_message_replied';
  static const String groupMessageReported = 'group_message_reported';
}

/// Shared analytics property keys.
abstract final class AnalyticsProperties {
  // Auth
  static const String method = 'method';
  static const String reason = 'reason';
  static const String isGuest = 'is_guest';

  // Plans
  static const String planId = 'plan_id';
  static const String planName = 'plan_name';
  static const String dayNumber = 'day_number';
  static const String totalDays = 'total_days';
  static const String completedDays = 'completed_days';

  // Routine
  static const String blockCount = 'block_count';
  static const String itemCount = 'item_count';

  // Group chat
  static const String groupId = 'group_id';
  static const String roomId = 'room_id';
  static const String messageId = 'message_id';
  static const String parentMessageId = 'parent_message_id';
  static const String isReply = 'is_reply';
  static const String emoji = 'emoji';
  static const String action = 'action';
  static const String source = 'source';
}
