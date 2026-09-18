import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/data/notification_id_scheme.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// How a bell alarm ended up scheduled. The screen uses it to decide whether
/// the OS will ring on time (`exact`) or whether it must keep an in-app
/// fallback because the alarm may be late (`inexact`) or absent (`none`).
enum TimerBellScheduleResult { none, exact, inexact }

/// Lock-screen surfaces for a running meditation timer, on Android.
///
/// Three notifications, all owned end to end by the timer screen:
///  - an ongoing status notification whose countdown Android ticks itself (see
///    [NotificationChannels.timerSessionDetails]), so it stays correct even if
///    the app process is killed mid-session;
///  - the start bell, scheduled for the end of the pre-roll countdown;
///  - the completion bell, scheduled at the session's end time so it rings on
///    time if the app is suspended before it can ring the bell itself. The
///    screen arms them only when backgrounding and disarms them as soon as it
///    can ring `TimerSoundPlayer` instead, so they never double up.
///
/// iOS gets its lock-screen countdown from the Live Activity instead, so the
/// ongoing notification is Android-only. The bells are scheduled on both — a
/// Live Activity is silent.
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

  Future<TimerBellScheduleResult> scheduleCompletion({
    required DateTime endsAt,
    required String title,
    required String body,
  });

  Future<void> cancelCompletion();

  Future<TimerBellScheduleResult> scheduleStart({
    required DateTime startsAt,
    required String title,
    required String body,
  });

  Future<void> cancelStart();

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
  @override
  Future<TimerBellScheduleResult> scheduleCompletion({
    required DateTime endsAt,
    required String title,
    required String body,
  }) => _scheduleBell(
    id: NotificationIdScheme.timerSessionCompleteId,
    at: endsAt,
    title: title,
    body: body,
  );

  /// Schedules the start bell for [startsAt], the end of the pre-roll.
  @override
  Future<TimerBellScheduleResult> scheduleStart({
    required DateTime startsAt,
    required String title,
    required String body,
  }) => _scheduleBell(
    id: NotificationIdScheme.timerSessionStartId,
    at: startsAt,
    title: title,
    body: body,
  );

  /// Mirrors the exact/inexact degradation used by the routine sync engine:
  /// exact-alarm permission can be revoked between the check and the call, and
  /// a late bell beats no bell.
  Future<TimerBellScheduleResult> _scheduleBell({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    if (!at.isAfter(DateTime.now())) return TimerBellScheduleResult.none;

    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(at, tz.local),
      NotificationChannels.timerBellDetails,
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
      if (!await _isPending(id)) return TimerBellScheduleResult.none;
      return canBeExact
          ? TimerBellScheduleResult.exact
          : TimerBellScheduleResult.inexact;
    } on PlatformException catch (e) {
      if (!canBeExact) {
        _logger.warning('Failed to schedule timer bell: $e');
        return TimerBellScheduleResult.none;
      }
      _logger.warning('Exact bell schedule failed (${e.code}) — inexact');
      try {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
        if (!await _isPending(id)) return TimerBellScheduleResult.none;
        return TimerBellScheduleResult.inexact;
      } catch (e) {
        _logger.warning('Failed to schedule timer bell: $e');
        return TimerBellScheduleResult.none;
      }
    } catch (e) {
      _logger.warning('Failed to schedule timer bell: $e');
      return TimerBellScheduleResult.none;
    }
  }

  /// Confirms the OS actually holds the request we just made.
  ///
  /// iOS keeps only the 64 soonest pending notifications, so a bell scheduled
  /// for the end of a long session can be dropped on the floor when the app
  /// already has a full slate of routine reminders. Reporting that as `none`
  /// keeps the screen's own bell as the fallback instead of trusting an alarm
  /// that will never fire.
  Future<bool> _isPending(int id) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      final found = pending.any((request) => request.id == id);
      if (!found) {
        _logger.warning(
          'Timer bell $id is not pending after scheduling — the OS dropped it '
          '(${pending.length} pending)',
        );
      }
      return found;
    } catch (e) {
      _logger.warning('Could not verify the timer bell schedule: $e');
      // Unverifiable, not known-missing: trust the schedule call that succeeded.
      return true;
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
  /// Called as soon as the screen knows it can ring the bell itself.
  @override
  Future<void> cancelCompletion() =>
      _cancel(NotificationIdScheme.timerSessionCompleteId, 'completion bell');

  /// Cancels the pending start bell.
  @override
  Future<void> cancelStart() =>
      _cancel(NotificationIdScheme.timerSessionStartId, 'start bell');

  /// Tears down every timer notification. Safe to call when nothing is showing.
  @override
  Future<void> cancelAll() async {
    await _cancel(NotificationIdScheme.timerSessionOngoingId, 'ongoing');
    await cancelStart();
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
