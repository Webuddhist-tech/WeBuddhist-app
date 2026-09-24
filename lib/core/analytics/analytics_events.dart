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
  static const String planPreviewed = 'plan_previewed';
  static const String planAddedToPractices = 'plan_added_to_practices';
  static const String planUnenrolled = 'plan_unenrolled';
  static const String planSearched = 'plan_searched';

  // Series
  static const String seriesViewed = 'series_viewed';
  static const String seriesBookmarked = 'series_bookmarked';
  static const String seriesAddedToPractices = 'series_added_to_practices';
  static const String seriesSearched = 'series_searched';

  // Group events
  static const String groupEventViewed = 'group_event_viewed';
  static const String groupEventAttended = 'group_event_attended';
  static const String groupEventLeft = 'group_event_left';
  static const String groupEventParticipationChanged =
      'group_event_participation_changed';
  static const String groupEventLiveEntered = 'group_event_live_entered';
  static const String groupEventLinkOpened = 'group_event_link_opened';

  // Entry points (plan §5.1)
  static const String deepLinkOpened = 'deep_link_opened';
  static const String pushNotificationOpened = 'push_notification_opened';
  static const String localNotificationOpened = 'local_notification_opened';
  static const String notificationPermissionPrompted =
      'notification_permission_prompted';
  static const String notificationPermissionGranted =
      'notification_permission_granted';
  static const String notificationPermissionDenied =
      'notification_permission_denied';

  // Onboarding (§5.2)
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingStepViewed = 'onboarding_step_viewed';
  static const String onboardingLanguageSelected =
      'onboarding_language_selected';
  static const String onboardingEventPlanSelected =
      'onboarding_event_plan_selected';

  // Auth and guest conversion (§5.3)
  static const String authLoginStarted = 'auth_login_started';
  static const String loginPromptShown = 'login_prompt_shown';
  static const String loginPromptDismissed = 'login_prompt_dismissed';

  // Home (§5.4)
  static const String homeViewed = 'home_viewed';
  static const String seriesEnrolled = 'series_enrolled';
  static const String seriesUnenrolled = 'series_unenrolled';

  // Sharing, cross-cutting (§5.15): one event, `surface` says what was shared
  static const String contentShared = 'content_shared';

  // Practice tab and routine (§5.5)
  static const String routineItemOpened = 'routine_item_opened';

  // Plans, day level (§5.6)
  static const String planDayViewed = 'plan_day_viewed';
  static const String planTaskCompleted = 'plan_task_completed';
  static const String planTaskUncompleted = 'plan_task_uncompleted';
  static const String planCompleted = 'plan_completed';

  // Reader (§5.7)
  static const String readerOpened = 'reader_opened';
  static const String readerPageLoaded = 'reader_page_loaded';
  static const String readerSessionEnded = 'reader_session_ended';
  static const String readerActionTapped = 'reader_action_tapped';

  // Mala sessions (§5.9)
  static const String malaSessionStarted = 'mala_session_started';
  static const String malaSessionEnded = 'mala_session_ended';
  static const String malaModeChanged = 'mala_mode_changed';
  static const String malaOfflineRoundsAdded = 'mala_offline_rounds_added';
  static const String malaSyncFailed = 'mala_sync_failed';

  // Timer (§5.10)
  static const String timerStarted = 'timer_started';
  static const String timerCompleted = 'timer_completed';
  static const String timerDiscarded = 'timer_discarded';

  // Settings (§5.13)
  static const String contentLanguageChanged = 'content_language_changed';
  static const String notificationSettingChanged =
      'notification_setting_changed';

  // Practice / Routine
  static const String routineSaved = 'routine_saved';

  // Mala
  static const String malaScreenOpened = 'mala_screen_opened';
  static const String malaRoundCompleted = 'mala_round_completed';
  static const String malaMantraSwitched = 'mala_mantra_switched';

  // Group chat
  static const String groupChatOpened = 'group_chat_opened';
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

  // Series
  static const String seriesId = 'series_id';
  static const String seriesTitle = 'series_title';
  static const String planCount = 'plan_count';
  static const String bookmarked = 'bookmarked';

  // Group events
  static const String eventId = 'event_id';
  static const String eventTitle = 'event_title';
  static const String eventFormat = 'event_format';
  static const String isRecurring = 'is_recurring';
  static const String participation = 'participation';
  static const String target = 'target';
  static const String linkType = 'link_type';

  // Search
  static const String queryLength = 'query_length';
  static const String resultCount = 'result_count';

  // Entry points
  static const String routeKind = 'route_kind';
  static const String targetId = 'target_id';
  static const String sessionType = 'session_type';
  static const String sourceId = 'source_id';
  static const String appState = 'app_state';
  static const String type = 'type';
  static const String minutesAfterScheduled = 'minutes_after_scheduled';
  static const String os = 'os';

  // Onboarding
  static const String step = 'step';
  static const String stepIndex = 'step_index';
  static const String uiLanguage = 'ui_language';
  static const String durationMs = 'duration_ms';
  static const String traditionsCount = 'traditions_count';
  static const String eventPlanSelected = 'event_plan_selected';

  // Auth
  static const String isNewUser = 'is_new_user';
  static const String feature = 'feature';

  // Home / sharing
  static const String hasRoutine = 'has_routine';
  static const String streakCurrent = 'streak_current';
  static const String surface = 'surface';
  static const String format = 'format';

  // Routine
  static const String itemType = 'item_type';
  static const String itemId = 'item_id';
  static const String blockIndex = 'block_index';
  static const String minutesFromBlockTime = 'minutes_from_block_time';
  static const String sessionTypes = 'session_types';
  static const String reminderEnabled = 'reminder_enabled';
  static const String earliestBlockHour = 'earliest_block_hour';

  // Plans, day level
  static const String isEnrolled = 'is_enrolled';
  static const String isToday = 'is_today';
  static const String isMissed = 'is_missed';
  static const String taskId = 'task_id';
  static const String taskType = 'task_type';
  static const String isOnTime = 'is_on_time';
  static const String daysElapsed = 'days_elapsed';
  static const String daysCompleted = 'days_completed';
  static const String daysSinceEnrolled = 'days_since_enrolled';

  // Reader
  static const String textId = 'text_id';
  static const String textTitle = 'text_title';
  static const String language = 'language';
  static const String versionId = 'version_id';
  static const String script = 'script';
  static const String layout = 'layout';
  static const String entrySegment = 'entry_segment';
  static const String pageNumber = 'page_number';
  static const String segmentCount = 'segment_count';
  static const String loadMs = 'load_ms';
  static const String durationSeconds = 'duration_s';
  static const String pagesLoaded = 'pages_loaded';
  static const String maxSegmentNumber = 'max_segment_number';
  static const String segmentsTotal = 'segments_total';
  static const String pctReached = 'pct_reached';

  // Mala
  static const String presetId = 'preset_id';
  static const String mantraName = 'mantra_name';
  static const String mode = 'mode';
  static const String startingTotal = 'starting_total';
  static const String rounds = 'rounds';
  static const String secondsSinceLastRound = 'seconds_since_last_round';
  static const String beadsCounted = 'beads_counted';
  static const String roundsCompleted = 'rounds_completed';
  static const String input = 'input';
  static const String from = 'from';
  static const String to = 'to';
  static const String fromPresetId = 'from_preset_id';
  static const String toPresetId = 'to_preset_id';
  static const String via = 'via';
  static const String pendingDelta = 'pending_delta';

  // Timer
  static const String wasBackgrounded = 'was_backgrounded';
  static const String pauseCount = 'pause_count';
  static const String elapsedSeconds = 'elapsed_s';
  static const String pctComplete = 'pct_complete';

  // Settings
  static const String setting = 'setting';
  static const String enabled = 'enabled';
}
