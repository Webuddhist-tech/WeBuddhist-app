import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Central registry for all app notification channels.
///
/// To add a new channel (e.g. reminders, announcements):
///   1. Add static const ID/name/description fields
///   2. Add a static final AndroidNotificationChannel
///   3. Add a static NotificationDetails factory method
/// No other file should define channel constants.
class NotificationChannels {
  NotificationChannels._();

  // ── Routine Block Reminder ──────────────────────────────────────────────────
  static const String routineBlockId = 'routine_block_reminder';
  static const String routineBlockName = 'Routine Block Reminder';
  static const String routineBlockDescription =
      'Daily notifications for routine practice blocks';

  /// Android raw resource sound — references android/app/src/main/res/raw/routine.ogg
  /// Specified WITHOUT file extension, as required by Android.
  static const RawResourceAndroidNotificationSound routineAndroidSound =
      RawResourceAndroidNotificationSound('routine');

  /// iOS sound file — routine.caf must be included in the Runner app bundle
  /// (Runner target → Build Phases → Copy Bundle Resources).
  static const String routineIosSoundFile = 'routine.caf';

  /// Android notification channel for routine blocks.
  /// Sound is baked in at channel creation time — Android does not allow
  /// changing it after the channel is registered on device.
  static const AndroidNotificationChannel routineBlockChannel =
      AndroidNotificationChannel(
        routineBlockId,
        routineBlockName,
        description: routineBlockDescription,
        importance: Importance.high,
        playSound: true,
        sound: routineAndroidSound,
        enableVibration: true,
      );

  // ── Push (Firebase Cloud Messaging) ─────────────────────────────────────────
  //
  // Channel id is versioned (`_v2`) because an Android channel's sound is baked
  // in at creation time and cannot be changed afterwards — bumping the id lets
  // the custom sound take effect on installs that already created the original
  // (soundless) `push_default` channel. Keep this value in sync with
  // `default_notification_channel_id` in AndroidManifest.xml.
  static const String pushDefaultId = 'push_default_v2';
  static const String pushDefaultName = 'General Notifications';
  static const String pushDefaultDescription =
      'Announcements and updates from WeBuddhist';

  /// Android channel for remote (FCM) notifications. Referenced from
  /// AndroidManifest as `default_notification_channel_id` so background /
  /// terminated FCM messages land here, and reused for foreground display.
  ///
  /// Shares the routine reminder sound so push and local notifications feel
  /// like one product. The sound is bound to the channel (Android 8+ ignores
  /// per-notification sound), so it must live here to apply in every state.
  static const AndroidNotificationChannel pushDefaultChannel =
      AndroidNotificationChannel(
        pushDefaultId,
        pushDefaultName,
        description: pushDefaultDescription,
        importance: Importance.high,
        playSound: true,
        sound: routineAndroidSound,
        enableVibration: true,
      );

  /// Platform details used when displaying a foreground FCM message via
  /// flutter_local_notifications (Android suppresses FCM auto-display while the
  /// app is foregrounded). Mirrors the routine reminder styling — app
  /// notification icon + custom sound — so foreground pushes match the rest of
  /// the app.
  static const NotificationDetails pushDefaultDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      pushDefaultId,
      pushDefaultName,
      channelDescription: pushDefaultDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      playSound: true,
      sound: routineAndroidSound,
      enableVibration: true,
    ),
    iOS: DarwinNotificationDetails(
      sound: routineIosSoundFile,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ── Meditation Timer Session ────────────────────────────────────────────────
  static const String timerSessionId = 'timer_session';
  static const String timerSessionName = 'Meditation Timer';
  static const String timerSessionDescription =
      'Shows the remaining time while a meditation timer is running';

  // Versioned because Android binds sound to a channel the first time it is
  // created. Older installs may already have a silent `timer_complete` channel,
  // so a new id is required for the bell sound to take effect after upgrade.
  static const String timerCompleteId = 'timer_complete_v2';
  static const String timerCompleteName = 'Meditation Timer Finished';
  static const String timerCompleteDescription =
      'Rings the bell when a meditation timer finishes';

  /// Silent, low-importance channel for the ongoing "session in progress"
  /// notification. Low importance keeps it out of the heads-up lane — it is a
  /// status readout, not an alert — while still showing on the lock screen.
  static const AndroidNotificationChannel timerSessionChannel =
      AndroidNotificationChannel(
        timerSessionId,
        timerSessionName,
        description: timerSessionDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );

  /// The completion bell. Shares the routine reminder sound so the app has one
  /// notification voice; Android 8+ binds sound to the channel, so it must be
  /// declared here rather than per-notification.
  static const AndroidNotificationChannel timerCompleteChannel =
      AndroidNotificationChannel(
        timerCompleteId,
        timerCompleteName,
        description: timerCompleteDescription,
        importance: Importance.high,
        playSound: true,
        sound: routineAndroidSound,
        enableVibration: true,
      );

  /// Ongoing "meditation in progress" notification.
  ///
  /// While running, Android renders the countdown itself: `usesChronometer` +
  /// `chronometerCountDown` with `when` set to the session's end time makes
  /// SystemUI tick the remaining time down every second with no updates from
  /// Dart — and it keeps ticking even if the app process is killed. When paused
  /// there is no end time to count towards, so the chronometer is dropped and
  /// the frozen remaining time is rendered into the body text instead.
  static NotificationDetails timerSessionDetails({
    required int whenMs,
    required bool paused,
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      timerSessionId,
      timerSessionName,
      channelDescription: timerSessionDescription,
      importance: Importance.low,
      priority: Priority.low,
      icon: 'ic_notification',
      ongoing: !paused,
      autoCancel: false,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      showWhen: !paused,
      when: paused ? null : whenMs,
      usesChronometer: !paused,
      chronometerCountDown: !paused,
    ),
  );

  /// Completion bell, scheduled for the session's end time so it rings on time
  /// even while the app is suspended.
  static const NotificationDetails timerCompleteDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      timerCompleteId,
      timerCompleteName,
      channelDescription: timerCompleteDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      playSound: true,
      sound: routineAndroidSound,
      enableVibration: true,
    ),
    iOS: DarwinNotificationDetails(
      sound: routineIosSoundFile,
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    ),
  );

  /// Action ID used for the Android action button on special-plan day-N
  /// notifications. The tap handler treats this the same as a body tap.
  static const String specialPlanActionId = 'special_plan_action';

  /// Full platform-specific NotificationDetails for routine block notifications.
  ///
  /// [androidActionButtonText] adds a single Android action button (e.g.
  /// "START", "READ ON"). When `null`, no action button is rendered. iOS does
  /// not render this label per product decision — body tap on iOS routes to
  /// the same destination, preserving functionality.
  static NotificationDetails routineBlockDetails({
    String icon = 'ic_notification',
    StyleInformation? styleInformation,
    FilePathAndroidBitmap? largeIcon,
    DarwinNotificationDetails? iOSDetails,
    String? androidActionButtonText,
  }) =>
      NotificationDetails(
    android: AndroidNotificationDetails(
      routineBlockId,
      routineBlockName,
      channelDescription: routineBlockDescription,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: styleInformation,
      icon: icon,
      largeIcon: largeIcon,
      enableVibration: true,
      playSound: true,
      sound: routineAndroidSound,
          actions: androidActionButtonText == null
              ? null
              : <AndroidNotificationAction>[
                AndroidNotificationAction(
                  specialPlanActionId,
                  androidActionButtonText,
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
              ],
    ),
        iOS: iOSDetails ?? DarwinNotificationDetails(
          sound: routineIosSoundFile,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
  );
}
