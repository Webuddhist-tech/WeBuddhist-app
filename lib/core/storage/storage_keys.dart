/// Storage keys - Single source of truth for all storage keys.
///
/// This class consolidates all storage keys used throughout the app.
/// All SharedPreferences and SecureStorage keys should be defined here.
///
/// Note: This replaces the old AppStorageKeys class which was in
/// lib/core/constants/app_storage_keys.dart
class StorageKeys {
  StorageKeys._();

  // ========== AUTHENTICATION ==========
  /// User data JSON
  static const String userData = 'user_data';
  /// Guest mode flag
  static const String isGuestMode = 'is_guest_mode';

  // ========== AUTH TOKENS (Secure Storage) ==========
  /// Access token for API calls
  static const String accessToken = 'access_token';
  /// Refresh token for getting new access tokens
  static const String refreshToken = 'refresh_token';
  /// ID token from Auth0
  static const String idToken = 'id_token';
  /// User ID
  static const String userId = 'user_id';

  // ========== ONBOARDING ==========
  /// Onboarding preferences JSON
  static const String onboardingPreferences = 'onboarding_preferences';
  /// ID of the currently logged-in user, written before the router fires
  /// so feature code can resolve the active account.
  static const String currentUserId = 'current_user_id';
  /// Current onboarding step
  static const String onboardingStep = 'onboarding_step';
  /// Onboarding data JSON
  static const String onboardingData = 'onboarding_data';

  // ========== USER PREFERENCES ==========
  /// Theme mode preference (light/dark/system)
  static const String themeMode = 'theme_mode';
  /// App UI language/locale preference (bounded to bundled ARB translations)
  static const String preferredLanguage = 'locale';
  /// Content language code sent to backend APIs. May be a language the app has
  /// no UI translation for; the UI then falls back to English.
  static const String contentLanguage = 'content_language';
  /// Chant list language picked on the all-recitations screen. Independent of
  /// [contentLanguage] and kept across restarts.
  static const String chantListLanguage = 'chant_list_language';
  /// Font size preference
  static const String fontSize = 'font_size';
  /// First launch flag
  static const String firstLaunch = 'first_launch';

  // ========== NOTIFICATIONS ==========
  /// Daily reminder time
  static const String dailyReminderTime = 'daily_reminder_time';
  /// Daily reminder enabled flag
  static const String dailyReminderEnabled = 'daily_reminder_enabled';
  /// App-level master notification toggle. When false the app cancels all
  /// scheduled notifications without touching OS permission. Re-enabling
  /// re-schedules from the stored routine. Default: true.
  static const String notificationMasterEnabled = 'notification_master_enabled';
  /// App-level toggle for routine (plan) block notifications. Default: true.
  static const String notificationRoutineEnabled = 'notification_routine_enabled';
  /// App-level toggle for recitation block notifications. Default: true.
  static const String notificationRecitationEnabled = 'notification_recitation_enabled';
  /// App-level toggle for practice (mala / accumulator) block notifications.
  /// Default: true.
  static const String notificationPracticeEnabled = 'notification_practice_enabled';
  /// App-level toggle for timer block notifications (the "starting now"
  /// reminder). Default: true.
  static const String notificationTimerEnabled = 'notification_timer_enabled';
  /// Latest Firebase Cloud Messaging registration token for this install.
  static const String fcmToken = 'fcm_token';
  /// Stable per-install identifier sent as `device_id` when registering the
  /// push token, so token refreshes update the same backend record. Generated
  /// once (UUID) and persisted for the lifetime of the install.
  static const String pushDeviceId = 'push_device_id';
  /// The backend's id for this device's push registration (`id` in the
  /// register response). Needed to `DELETE /users/me/push-devices/{id}`
  /// when the master notification switch is turned off. Cleared after a
  /// successful unregister.
  static const String pushDeviceServerId = 'push_device_server_id';

  // ========== FEATURES ==========
  /// Profile data JSON
  static const String profileData = 'profile_data';
  /// Whether the dual-slot reader's secondary panel is enabled. Global UX
  /// preference (bool). Slot picks (language/version/script) are per-text
  /// and live in memory only — they don't survive navigating to a different
  /// text because `versionId` is text-scoped and won't resolve elsewhere.
  static const String readerSecondaryEnabled = 'reader_secondary_enabled';
  /// Bead-tap sound on the mala counter. Default: true.
  static const String malaSoundEnabled = 'mala_sound_enabled';
  /// Haptic feedback on the mala counter. Default: true.
  static const String malaVibrationEnabled = 'mala_vibration_enabled';
  /// Per-preset accumulation source: `personal` or `group:{uuid}`.
  static const String malaAccumulationSelectionPrefix =
      'mala_accumulation_selection_';

  // ========== BUSINESS LOGIC ==========
  /// Last profile update timestamp
  static const String lastProfileUpdate = 'last_profile_update';
  /// Current streak count
  static const String streakCount = 'streak_count';

  // ========== CACHE METADATA ==========
  /// Last sync timestamp
  static const String lastSyncTime = 'last_sync_time';
  /// Cache version for invalidation
  static const String cacheVersion = 'cache_version';
}
