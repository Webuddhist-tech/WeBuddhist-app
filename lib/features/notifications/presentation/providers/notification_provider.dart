import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/presentation/utils/notification_settings_analytics.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';

final _logger = AppLogger('NotificationProvider');

enum NotificationToggleResult { success, permissionDenied, error }

/// Five app-level flags (master / routine / recitation / practice / timer) are
/// stored in SharedPreferences and never touch OS permission. OS-level checks
/// (system permission, exact alarms, battery) are read-only live reads.
class NotificationState {
  final bool isLoading;
  final bool appMasterEnabled;
  final bool appRoutineEnabled;
  final bool appRecitationEnabled;
  final bool appPracticeEnabled;
  final bool appTimerEnabled;
  final bool hasSystemPermission;
  final bool canScheduleExactAlarms;
  final bool isBatteryOptimizationExempt;

  const NotificationState({
    this.isLoading = false,
    this.appMasterEnabled = true,
    this.appRoutineEnabled = true,
    this.appRecitationEnabled = true,
    this.appPracticeEnabled = true,
    this.appTimerEnabled = true,
    this.hasSystemPermission = false,
    this.canScheduleExactAlarms = true,
    this.isBatteryOptimizationExempt = true,
  });

  NotificationState copyWith({
    bool? isLoading,
    bool? appMasterEnabled,
    bool? appRoutineEnabled,
    bool? appRecitationEnabled,
    bool? appPracticeEnabled,
    bool? appTimerEnabled,
    bool? hasSystemPermission,
    bool? canScheduleExactAlarms,
    bool? isBatteryOptimizationExempt,
  }) =>
      NotificationState(
        isLoading: isLoading ?? this.isLoading,
        appMasterEnabled: appMasterEnabled ?? this.appMasterEnabled,
        appRoutineEnabled: appRoutineEnabled ?? this.appRoutineEnabled,
        appRecitationEnabled: appRecitationEnabled ?? this.appRecitationEnabled,
        appPracticeEnabled: appPracticeEnabled ?? this.appPracticeEnabled,
        appTimerEnabled: appTimerEnabled ?? this.appTimerEnabled,
        hasSystemPermission: hasSystemPermission ?? this.hasSystemPermission,
        canScheduleExactAlarms:
            canScheduleExactAlarms ?? this.canScheduleExactAlarms,
        isBatteryOptimizationExempt:
            isBatteryOptimizationExempt ?? this.isBatteryOptimizationExempt,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;
  final Ref _ref;

  NotificationNotifier(this._service, this._ref)
      : super(const NotificationState()) {
    refreshStatus(initial: true);
  }

  /// Re-reads OS-level permissions and SharedPreferences flags in parallel.
  /// Called on init and on app resume from a Settings page.
  Future<void> refreshStatus({bool initial = false}) async {
    if (initial) state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait<bool>([
        _service.areNotificationsEnabled(),
        _service.canScheduleExactNotifications(),
        _service.isBatteryOptimizationExempt(),
        _loadBool(StorageKeys.notificationMasterEnabled, defaultValue: true),
        _loadBool(StorageKeys.notificationRoutineEnabled, defaultValue: true),
        _loadBool(StorageKeys.notificationRecitationEnabled, defaultValue: true),
        _loadBool(StorageKeys.notificationPracticeEnabled, defaultValue: true),
        _loadBool(StorageKeys.notificationTimerEnabled, defaultValue: true),
      ]);
      state = state.copyWith(
        hasSystemPermission: results[0],
        canScheduleExactAlarms: results[1],
        isBatteryOptimizationExempt: results[2],
        appMasterEnabled: results[3],
        appRoutineEnabled: results[4],
        appRecitationEnabled: results[5],
        appPracticeEnabled: results[6],
        appTimerEnabled: results[7],
        isLoading: false,
      );
    } catch (_) {
      if (initial) state = state.copyWith(isLoading: false);
    }
  }

  // ── Master toggle ───────────────────────────────────────────────────────────

  /// Toggles the master in-app notification switch.
  ///
  /// Optimistic update: UI reflects the new value instantly. On failure the
  /// previous state is restored and [NotificationToggleResult.error] is
  /// returned so the caller can show a localised error snack.
  ///
  /// ON  → requests OS permission if missing, then syncs notifications
  ///        respecting each sub-toggle's current saved state.
  /// OFF → cancels every scheduled local notification (recitation + mala +
  ///        timer daily-repeats). Sub-toggle states are preserved in
  ///        SharedPreferences so re-enabling restores them. As the global
  ///        kill-switch it also disables plan/series *push*: the FCM device is
  ///        re-registered with the plan/series gate (`master && routine`) OFF
  ///        (see `pushNotificationBootstrapProvider`).
  Future<NotificationToggleResult> toggleMaster(bool enable) async {
    _logger.info('[TOGGLE] master → $enable '
        '(routine=${state.appRoutineEnabled} recitation=${state.appRecitationEnabled} '
        'osPermission=${state.hasSystemPermission})');
    final previous = state;
    state = state.copyWith(appMasterEnabled: enable);

    try {
      final prefs = await SharedPreferences.getInstance();

      if (enable) {
        if (!state.hasSystemPermission) {
          _logger.info('[TOGGLE] master ON — OS permission missing, requesting…');
          final granted = await _service.requestPermission();
          if (!granted) {
            _logger.warning('[TOGGLE] master ON — OS permission denied, reverting');
            state = previous.copyWith(appMasterEnabled: false);
            await prefs.setBool(StorageKeys.notificationMasterEnabled, false);
            return NotificationToggleResult.permissionDenied;
          }
          _logger.info('[TOGGLE] master ON — OS permission granted');
          state = state.copyWith(hasSystemPermission: true);
        }
        await prefs.setBool(StorageKeys.notificationMasterEnabled, true);
      } else {
        await prefs.setBool(StorageKeys.notificationMasterEnabled, false);
      }

      await _ref
          .read(notificationSyncEngineProvider)
          .sync(trigger: SyncTrigger.masterToggle);

      _ref.read(notificationSettingsAnalyticsProvider).settingChanged(
        setting: NotificationSetting.master,
        enabled: enable,
      );
      _logger.info('[TOGGLE] master → $enable COMPLETE');
      return NotificationToggleResult.success;
    } catch (e, st) {
      _logger.error('[TOGGLE] master → $enable FAILED — reverting', e, st);
      state = previous;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
            StorageKeys.notificationMasterEnabled, previous.appMasterEnabled);
      } catch (_) {}
      return NotificationToggleResult.error;
    }
  }

  // ── Sub-toggles ─────────────────────────────────────────────────────────────

  /// Toggles routine (plan/series) notifications independently.
  ///
  /// Plan/series reminders are delivered via server push (FCM) now, so this no
  /// longer schedules anything locally — the sync pass reconciles only
  /// recitation/mala/timer. The saved flag is sent with the FCM device
  /// registration (see `pushNotificationBootstrapProvider`) so the backend
  /// suppresses plan/series push when this is OFF.
  Future<NotificationToggleResult> toggleRoutine(bool enable) async {
    _logger.info('[TOGGLE] routine → $enable');
    final previous = state;
    state = state.copyWith(appRoutineEnabled: enable);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.notificationRoutineEnabled, enable);

      await _ref
          .read(notificationSyncEngineProvider)
          .sync(trigger: SyncTrigger.routineToggle);

      _ref.read(notificationSettingsAnalyticsProvider).settingChanged(
        setting: NotificationSetting.routine,
        enabled: enable,
      );
      _logger.info('[TOGGLE] routine → $enable COMPLETE');
      return NotificationToggleResult.success;
    } catch (e, st) {
      _logger.error('[TOGGLE] routine → $enable FAILED — reverting', e, st);
      state = previous;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
            StorageKeys.notificationRoutineEnabled, previous.appRoutineEnabled);
      } catch (_) {}
      return NotificationToggleResult.error;
    }
  }

  /// Toggles recitation block notifications independently.
  ///
  /// ON  → re-schedules only recitation blocks.
  /// OFF → cancels only recitation blocks. Plan blocks are NOT affected.
  Future<NotificationToggleResult> toggleRecitation(bool enable) async {
    _logger.info('[TOGGLE] recitation → $enable');
    final previous = state;
    state = state.copyWith(appRecitationEnabled: enable);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.notificationRecitationEnabled, enable);

      await _ref
          .read(notificationSyncEngineProvider)
          .sync(trigger: SyncTrigger.recitationToggle);

      _ref.read(notificationSettingsAnalyticsProvider).settingChanged(
        setting: NotificationSetting.recitation,
        enabled: enable,
      );
      _logger.info('[TOGGLE] recitation → $enable COMPLETE');
      return NotificationToggleResult.success;
    } catch (e, st) {
      _logger.error('[TOGGLE] recitation → $enable FAILED — reverting', e, st);
      state = previous;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(StorageKeys.notificationRecitationEnabled,
            previous.appRecitationEnabled);
      } catch (_) {}
      return NotificationToggleResult.error;
    }
  }

  /// Toggles practice (mala / accumulator) block notifications independently.
  ///
  /// ON  → re-schedules only mala blocks.
  /// OFF → cancels only mala blocks. Plan and recitation blocks are NOT affected.
  Future<NotificationToggleResult> togglePractice(bool enable) async {
    _logger.info('[TOGGLE] practice → $enable');
    final previous = state;
    state = state.copyWith(appPracticeEnabled: enable);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.notificationPracticeEnabled, enable);

      await _ref
          .read(notificationSyncEngineProvider)
          .sync(trigger: SyncTrigger.practiceToggle);

      _ref.read(notificationSettingsAnalyticsProvider).settingChanged(
        setting: NotificationSetting.practice,
        enabled: enable,
      );
      _logger.info('[TOGGLE] practice → $enable COMPLETE');
      return NotificationToggleResult.success;
    } catch (e, st) {
      _logger.error('[TOGGLE] practice → $enable FAILED — reverting', e, st);
      state = previous;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(StorageKeys.notificationPracticeEnabled,
            previous.appPracticeEnabled);
      } catch (_) {}
      return NotificationToggleResult.error;
    }
  }

  /// Toggles timer block notifications independently.
  ///
  /// ON  → re-schedules only timer blocks (start + "timer up" reminders).
  /// OFF → cancels only timer blocks. Plan, recitation and mala blocks are
  ///        NOT affected.
  Future<NotificationToggleResult> toggleTimer(bool enable) async {
    _logger.info('[TOGGLE] timer → $enable');
    final previous = state;
    state = state.copyWith(appTimerEnabled: enable);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.notificationTimerEnabled, enable);

      await _ref
          .read(notificationSyncEngineProvider)
          .sync(trigger: SyncTrigger.timerToggle);

      _ref.read(notificationSettingsAnalyticsProvider).settingChanged(
        setting: NotificationSetting.timer,
        enabled: enable,
      );
      _logger.info('[TOGGLE] timer → $enable COMPLETE');
      return NotificationToggleResult.success;
    } catch (e, st) {
      _logger.error('[TOGGLE] timer → $enable FAILED — reverting', e, st);
      state = previous;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
            StorageKeys.notificationTimerEnabled, previous.appTimerEnabled);
      } catch (_) {}
      return NotificationToggleResult.error;
    }
  }

  // ── Resume sync ─────────────────────────────────────────────────────────────

  /// Called when the app resumes from system settings. Always delegates to
  /// the sync engine; the engine itself short-circuits when master is OFF
  /// or OS permission is missing.
  Future<void> resyncRoutineNotifications(List<RoutineBlock> blocks) async {
    await _ref
        .read(notificationSyncEngineProvider)
        .sync(trigger: SyncTrigger.appResume);
  }

  Future<bool> _loadBool(String key, {required bool defaultValue}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(NotificationService(), ref);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
