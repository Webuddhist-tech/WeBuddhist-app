import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/analytics/entry_analytics.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/notifications/data/models/notification_nav.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Top-level background notification tap handler.
/// Must be a top-level function annotated with @pragma so it survives AOT
/// tree-shaking and is callable from a separate background isolate (Android).
@pragma('vm:entry-point')
void onNotificationTapBackground(NotificationResponse notificationResponse) {
  // Background isolate — cannot access Riverpod state or UI.
  // The tap will be handled when the app comes to foreground.
}

final _logger = AppLogger('NotificationService');

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Static reference for navigation
  static GoRouter? _router;
  static ProviderContainer? _container;

  /// Delegate for push (FCM) payloads. Foreground push notifications are shown
  /// through this same shared plugin, so their taps land in [_onNotificationTapped].
  /// Push-shaped payloads (and any non-routine payload, including verse of the
  /// day) are forwarded here instead of the routine deep-link logic.
  static void Function(Map<String, dynamic> data)? _pushTapHandler;

  // Method to set the router reference
  static void setRouter(GoRouter router) {
    _router = router;
  }

  // Method to set the provider container
  static void setContainer(ProviderContainer container) {
    _container = container;
  }

  /// Registers the handler for foreground push-notification taps. Set by the
  /// push-notification bootstrap so FCM payloads route via PushMessageNavigator.
  static void setPushTapHandler(void Function(Map<String, dynamic> data) handler) {
    _pushTapHandler = handler;
  }

  bool get isInitialized => _isInitialized;

  /// Map legacy timezone IDs (e.g. from Android) to IANA names used by the timezone package.
  /// Default timezone data (latest.dart) may not include all legacy names.
  static const Map<String, String> _legacyTimezoneToIana = {
    'Asia/Calcutta': 'Asia/Kolkata',
    'US/Eastern': 'America/New_York',
    'US/Central': 'America/Chicago',
    'US/Mountain': 'America/Denver',
    'US/Pacific': 'America/Los_Angeles',
    'GMT': 'UTC',
  };

  /// Initialize without requesting permissions (for early app initialization)
  Future<void> initializeWithoutPermissions() async {
    _logger.info('[NOTIF-INIT] initializeWithoutPermissions called, already initialized=$_isInitialized');
    if (_isInitialized) return; // prevent re-initialization

    // Initialize timezone: use device local time so scheduled notifications
    // (e.g. "7:10 AM") are in the user's local time, not UTC.
    tz.initializeTimeZones();
    final currentTimezone = await FlutterTimezone.getLocalTimezone();
    _logger.info('[NOTIF-INIT] device timezone=$currentTimezone');
    bool localSet = false;
    try {
      tz.setLocalLocation(tz.getLocation(currentTimezone));
      localSet = true;
    } catch (_) {
      final ianaName = _legacyTimezoneToIana[currentTimezone];
      if (ianaName != null) {
        try {
          tz.setLocalLocation(tz.getLocation(ianaName));
          _logger.info(
            'Mapped legacy timezone "$currentTimezone" to "$ianaName"',
          );
          localSet = true;
        } catch (_) {
          // fall through to UTC fallback
        }
      }
      if (!localSet) {
        _logger.warning(
          'Unknown timezone "$currentTimezone", falling back to UTC',
        );
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    // Android initialization - do NOT request permissions
    // Use drawable resource for notification icon (not mipmap)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');

    // iOS initialization - do NOT request permissions
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        );

    // macOS initialization - same as iOS
    const DarwinInitializationSettings macOSSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        );

    // initialization settings
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSSettings,
    );

    // initialize the plugin
    await notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: onNotificationTapBackground,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    _isInitialized = true;
    _logger.info('[NOTIF-INIT] initialization complete, isInitialized=$_isInitialized');

    // Log diagnostics that affect terminated-state reliability.
    if (Platform.isAndroid) {
      await _logAndroidDiagnostics();
    }

    // Check if the app was launched by tapping a notification (terminated state).
    // Store the details so they can be consumed after the router is ready.
    final launchDetails = await notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _launchNotificationResponse = launchDetails!.notificationResponse;
      _logger.info('App launched from notification ID=${_launchNotificationResponse?.id}');
    }
  }

  NotificationResponse? _launchNotificationResponse;

  /// Call this once the router is ready to consume any pending launch navigation.
  void consumeLaunchNotification() {
    final response = _launchNotificationResponse;
    if (response == null) return;
    _launchNotificationResponse = null;
    _onNotificationTapped(response);
  }

  /// Logs key Android diagnostics that affect whether notifications fire
  /// when the app is in the background or terminated state.
  Future<void> _logAndroidDiagnostics() async {
    try {
      final androidImpl = notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final canExact = await androidImpl?.canScheduleExactNotifications() ?? false;
      final batteryExempt =
          await Permission.ignoreBatteryOptimizations.isGranted;

      _logger.info(
        '[NOTIF-DIAG] canScheduleExactNotifications=$canExact  '
        'batteryOptimizationExempt=$batteryExempt',
      );

      if (!canExact) {
        _logger.warning(
          '[NOTIF-DIAG] ⚠️ Exact alarms NOT allowed — '
          'notifications may fire late or not at all when app is terminated.',
        );
      }
      if (!batteryExempt) {
        _logger.warning(
          '[NOTIF-DIAG] ⚠️ Battery optimization is ACTIVE — '
          'on some Android devices this kills alarms when the app is terminated. '
          'User should go to Settings > Apps > WeBuddhist > Battery > Unrestricted.',
        );
      }
    } catch (e) {
      _logger.warning('[NOTIF-DIAG] Could not read diagnostics: $e');
    }
  }

  /// Returns true if this app is exempt from battery optimisation.
  Future<bool> isBatteryOptimizationExempt() async {
    if (!Platform.isAndroid) return true;
    return Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// Opens the system dialog that lets the user exempt this app from
  /// battery optimisation. Only needed on OEM devices (Samsung, Xiaomi, OnePlus).
  Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.request();
    _logger.info('[NOTIF] Battery optimization exemption request result: $status');
    return status.isGranted;
  }

  /// Returns true if exact alarms are permitted (Android 12+).
  /// Always true on iOS/macOS and Android < 12.
  Future<bool> canScheduleExactNotifications() async {
    if (!Platform.isAndroid) return true;
    final androidImpl = notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await androidImpl?.canScheduleExactNotifications() ?? false;
  }

  /// Opens the Alarms & Reminders settings page for this app (Android 12+).
  Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    final androidImpl = notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestExactAlarmsPermission();
  }

  /// Reads the live system state of a notification channel.
  /// Returns false if the user has muted the channel (importance = none) or
  /// the channel doesn't exist. iOS/macOS have no channels — returns the
  /// app-level permission instead.
  Future<bool> isChannelEnabled(String channelId) async {
    if (!Platform.isAndroid) return areNotificationsEnabled();
    final androidImpl = notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final channels = await androidImpl?.getNotificationChannels() ?? [];
    final channel = channels.where((c) => c.id == channelId).firstOrNull;
    if (channel == null) return false;
    return channel.importance != Importance.none;
  }

  /// Opens the OS notification settings for a specific channel (Android 8+).
  /// Falls back to opening the app-level notification settings on older devices.
  Future<void> openChannelSettings(String channelId) async {
    if (!Platform.isAndroid) return;
    const platform = MethodChannel('org.pecha.app/notifications');
    try {
      await platform.invokeMethod('openChannelSettings', {
        'channelId': channelId,
      });
    } catch (e) {
      _logger.warning('openChannelSettings failed: $e');
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        NotificationChannels.routineBlockChannel,
      );
      await androidImplementation.createNotificationChannel(
        NotificationChannels.timerSessionChannel,
      );
      await androidImplementation.createNotificationChannel(
        NotificationChannels.timerBellChannel,
      );
      for (final id in NotificationChannels.legacyTimerBellIds) {
        await androidImplementation.deleteNotificationChannel(id);
      }
      _logger.info('Android notification channels created');
    }
  }

  /// Initialize and immediately request notification permissions.
  /// Use [initializeWithoutPermissions] + [requestPermission] separately
  /// when you need finer control over the permission prompt timing.
  Future<void> initialize() async {
    await initializeWithoutPermissions();
    await requestPermission();
  }

  // Request permission for notifications
  Future<bool> requestPermission() async {
    final analytics = _container?.read(entryAnalyticsProvider);
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // Request notification permission
      analytics?.notificationPermissionPrompted(os: NotificationOs.android);
      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();
      analytics?.notificationPermissionAnswered(
        granted: granted ?? false,
        os: NotificationOs.android,
      );

      // For Android 12+, also request exact alarm permission
      if (granted == true) {
        await androidImplementation?.requestExactAlarmsPermission();
      }

      return granted ?? false;
    } else if (Platform.isIOS || Platform.isMacOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          notificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      // iOS asks once; a request after a refusal returns with no dialog.
      final prompting =
          !Platform.isIOS || !await Permission.notification.isPermanentlyDenied;
      if (prompting) {
        analytics?.notificationPermissionPrompted(os: NotificationOs.ios);
      }
      final bool? granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (prompting) {
        analytics?.notificationPermissionAnswered(
          granted: granted ?? false,
          os: NotificationOs.ios,
        );
      }
      return granted ?? false;
    }
    return false;
  }

  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? granted =
          await androidImplementation?.areNotificationsEnabled();
      return granted ?? false;
    } else if (Platform.isIOS || Platform.isMacOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          notificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      final NotificationsEnabledOptions? granted =
          await iosImplementation?.checkPermissions();
      return granted?.isEnabled ?? false;
    }
    return false;
  }

  void _onNotificationTapped(NotificationResponse response) {
    _logger.info(
      'Notification tapped - ID: ${response.id}, '
      'actionId: ${response.actionId}, Payload: ${response.payload}',
    );

    // Action button taps (e.g. special-plan day-N button) intentionally
    // route the same as a body tap. The action button shares the
    // notification's payload, so the existing parse-and-route logic below
    // handles both cases without branching.

    if (_router == null || _container == null) {
      _logger.warning('Router/container not initialized, cannot navigate');
      return;
    }

    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;

        // Meditation timer notifications carry no destination — the timer
        // screen is already the top route, so tapping should just bring the app
        // forward. Without this guard the tap falls through to the routine
        // branch below and yanks the user to My Practices mid-session.
        if (data['type'] == NotificationChannels.timerSessionId) {
          _logger.info('Timer session notification tapped — no navigation');
          _container!.read(entryAnalyticsProvider).localNotificationOpened(
            type: NotificationChannels.timerSessionId,
          );
          return;
        }

        final itemId = data['itemId'] as String?;
        final itemTypeStr = data['itemType'] as String?;
        final isLocalRoutine =
            itemId != null &&
            itemTypeStr != null &&
            !data.containsKey('session_type');

        if (!isLocalRoutine) {
          // Foreground FCM (verse of the day, plan, series, unknown). Route
          // through the push navigator so it matches background/terminated taps.
          _logger.info('Forwarding non-routine payload to push tap handler');
          if (_pushTapHandler != null) {
            _pushTapHandler!(data);
          } else {
            _openHomeTab();
          }
          return;
        }

        final planId = data['planId'] as String?;
        final durationMs = (data['durationMs'] as num?)?.toInt();
        _logger.info(
          'Storing pending notification nav: $itemTypeStr $itemId '
          'planId=$planId durationMs=$durationMs',
        );
        _container!.read(pendingNotificationNavProvider.notifier).state =
            NotificationNav(
              itemId: itemId,
              itemType: itemTypeStr,
              planId: planId,
              durationMs: durationMs,
            );
        _openMyPractices();
        // `scheduledMinute` is the block time the sync engine stamped on it.
        final scheduledMinute = (data['scheduledMinute'] as num?)?.toInt();
        _container!.read(entryAnalyticsProvider).localNotificationOpened(
          type: itemTypeStr,
          minutesAfterScheduled: scheduledMinute == null
              ? null
              : minutesSinceScheduled(scheduledMinute, DateTime.now()),
        );
        return;
      } catch (e) {
        _logger.warning('Failed to parse notification payload: $e');
      }
    }

    // Empty / unparseable payload (typical of verse-of-day notification-only
    // FCM). Land on Home rather than My Practices.
    _openHomeTab();
  }

  void _openMyPractices() {
    // RoutineFilledState — which consumes the pending nav and pushes the
    // chant / mala / plan detail — only mounts on /practice/my-practices; the
    // Practice tab itself shows the explore screen and consumes nothing.
    _container!.read(mainNavigationIndexProvider.notifier).state =
        MainTab.practice.index;
    _router!.go('/home');
    _router!.push('/practice/my-practices');
  }

  void _openHomeTab() {
    _container!.read(mainNavigationIndexProvider.notifier).state =
        MainTab.home.index;
    _router!.go('/home');
  }
}

