import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/data/notification_id_scheme.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// Lock-screen surfaces for a running meditation timer, on Android.
///
/// Two notifications, both owned end to end by the timer screen:
///  - an ongoing status notification whose countdown Android ticks itself (see
///    [NotificationChannels.timerSessionDetails]), so it stays correct even if
///    the app process is killed mid-session;
///  - the completion bell, scheduled at the session's end time so it rings on
///    time while the app is suspended. The screen schedules it only when
///    backgrounding and cancels it on resume, so it can never double up with
///    the in-app bell from `TimerSoundPlayer`.
///
/// iOS gets its lock-screen countdown from the Live Activity instead, so the
/// ongoing notification is Android-only. The completion bell is scheduled on
/// both — a Live Activity is silent.
///
/// Nothing here may throw into the timer: a session must keep running correctly
/// even with notification permission denied, so every call is best-effort.
abstract class TimerSessionNotifications {
  Future<void> showRunning({
    required DateTime endsAt,
    required String title,
    required String body,
  });

  Future<void> showPaused({required String title, required String body});

  Future<bool> scheduleCompletion({
    required DateTime endsAt,
    required String title,
    required String body,
  });

  Future<void> cancelCompletion();

  Future<void> cancelAll();
}

class TimerSessionNotifier implements TimerSessionNotifications {
  TimerSessionNotifier() : _logger = AppLogger('TimerSessionNotifier');

  final AppLogger _logger;

  /// The app-wide plugin instance — reusing it keeps initialization, the tap
  /// handler and the registered channels shared with the rest of the app.
  FlutterLocalNotificationsPlugin get _plugin =>
      NotificationService().notificationsPlugin;

  /// Marks a notification as belonging to a timer session so
  /// `NotificationService._onNotificationTapped` knows not to route it away
  /// from the timer screen.
  static final String _payload = jsonEncode({
    'type': NotificationChannels.timerSessionId,
  });

  /// Shows (or updates) the ongoing "session in progress" notification counting
  /// down to [endsAt]. Android only.
  @override
  Future<void> showRunning({
    required DateTime endsAt,
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid) return;
    await _show(
      title: title,
      body: body,
      details: NotificationChannels.timerSessionDetails(
        whenMs: endsAt.millisecondsSinceEpoch,
        paused: false,
      ),
    );
  }

  /// Replaces the ongoing notification with a frozen, paused one. Android only.
  @override
  Future<void> showPaused({required String title, required String body}) async {
    if (!Platform.isAndroid) return;
    await _show(
      title: title,
      body: body,
      details: NotificationChannels.timerSessionDetails(
        whenMs: 0,
        paused: true,
      ),
    );
  }

  Future<void> _show({
    required String title,
    required String body,
    required NotificationDetails details,
  }) async {
    try {
      await _plugin.show(
        NotificationIdScheme.timerSessionOngoingId,
        title,
        body,
        details,
        payload: _payload,
      );
    } catch (e) {
      _logger.warning('Failed to show timer session notification: $e');
    }
  }

  /// Schedules the completion bell for [endsAt].
  ///
  /// Mirrors the exact/inexact degradation used by the routine sync engine:
  /// exact-alarm permission can be revoked between the check and the call, and
  /// a late bell beats no bell.
  @override
  Future<bool> scheduleCompletion({
    required DateTime endsAt,
    required String title,
    required String body,
  }) async {
    if (!endsAt.isAfter(DateTime.now())) return false;

    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      NotificationIdScheme.timerSessionCompleteId,
      title,
      body,
      tz.TZDateTime.from(endsAt, tz.local),
      NotificationChannels.timerCompleteDetails,
      androidScheduleMode: mode,
      payload: _payload,
    );

    final canBeExact = await _canScheduleExact();
    final mode =
        canBeExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      await schedule(mode);
      return true;
    } on PlatformException catch (e) {
      if (mode == AndroidScheduleMode.exactAllowWhileIdle) {
        _logger.warning('Exact bell schedule failed (${e.code}) — inexact');
        try {
          await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
          return true;
        } catch (e) {
          _logger.warning('Failed to schedule timer completion bell: $e');
          return false;
        }
      } else {
        _logger.warning('Failed to schedule timer completion bell: $e');
        return false;
      }
    } catch (e) {
      _logger.warning('Failed to schedule timer completion bell: $e');
      return false;
    }
  }

  Future<bool> _canScheduleExact() async {
    try {
      return await NotificationService().canScheduleExactNotifications();
    } catch (e) {
      _logger.warning('canScheduleExactNotifications failed: $e');
      return false;
    }
  }

  /// Cancels the pending completion bell, leaving the ongoing notification up.
  /// Called on resume — from then on the in-app bell owns completion.
  @override
  Future<void> cancelCompletion() =>
      _cancel(NotificationIdScheme.timerSessionCompleteId, 'completion bell');

  /// Tears down both notifications. Safe to call when nothing is showing.
  @override
  Future<void> cancelAll() async {
    await _cancel(NotificationIdScheme.timerSessionOngoingId, 'ongoing');
    await cancelCompletion();
  }

  Future<void> _cancel(int id, String label) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      _logger.warning('Failed to cancel timer $label notification: $e');
    }
  }
}
