import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/l10n/tolgee/tolgee_localizations_delegate.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/data/notification_id_scheme.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_item_display.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart'
    show routineNotificationServiceProvider;
import 'package:flutter_pecha/features/practice/presentation/providers/routine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

final _logger = AppLogger('NotificationSyncEngine');

/// Every notification scheduling decision flows through one of these triggers.
/// Used only for logging — the engine does the same work regardless.
///
/// Plan/series reminders are delivered via server push (FCM) now, so the
/// engine only schedules local recitation, mala (accumulator) and timer
/// daily-repeats. `routineToggle` is retained because the settings screen
/// still owns the "Routine" switch (it gates plan/series *push* server-side).
enum SyncTrigger {
  coldStart,
  appResume,
  appLaunch,
  routineSaved,
  blockDeleted,
  masterToggle,
  routineToggle,
  recitationToggle,
  practiceToggle,
  timerToggle,
  permissionChanged,
  loggedIn,
  loggedOut,
}

/// A single notification the engine has decided should exist.
@immutable
class DesiredNotification {
  /// Stable notification ID. See [NotificationIdScheme].
  final int id;

  /// When this should fire. Every current notification is a daily-repeat, so
  /// this is the next occurrence of the block time.
  final tz.TZDateTime? fireAt;

  final String title;
  final String body;
  final String? payload;

  /// Source routine item — used to load images for the big-picture style and
  /// iOS attachment.
  final RoutineItem? sourceItem;

  /// True for recitation/mala/timer: schedule with `matchDateTimeComponents.time`
  /// so it repeats daily forever until cancelled.
  final bool isDailyRepeat;

  /// Case marker for the verification matrix (e.g. "4 daily-repeat").
  final String debugCase;

  const DesiredNotification({
    required this.id,
    required this.fireAt,
    required this.title,
    required this.body,
    required this.payload,
    required this.sourceItem,
    required this.debugCase,
    this.isDailyRepeat = false,
  });
}

/// Diagnostic result returned by [NotificationSyncEngine.sync].
class NotificationSyncReport {
  final int scheduled;
  final int cancelled;
  final int skipped;
  final int durationMs;
  final Map<String, int> perCase;

  const NotificationSyncReport({
    required this.scheduled,
    required this.cancelled,
    required this.skipped,
    required this.durationMs,
    required this.perCase,
  });

  @override
  String toString() =>
      'scheduled=$scheduled cancelled=$cancelled skipped=$skipped '
      'duration=${durationMs}ms perCase=$perCase';
}

/// Single source of truth for keeping the OS notification schedule in sync
/// with the routine + toggle state.
///
/// Every lifecycle event funnels through [sync]. The engine reads the routine
/// blocks + toggles, computes the desired schedule via the pure `_computeForX`
/// helpers, then diffs against `pendingNotificationRequests()` and reconciles
/// via the `flutter_local_notifications` plugin.
///
/// Only recitation, mala (accumulator), timer and recitation-collection
/// daily-repeats are scheduled locally; plan/series reminders are delivered
/// via server push (FCM). The cancel pass still recognises legacy plan/series
/// IDs (via [NotificationIdScheme.isOurs]) so leftover notifications scheduled
/// by older app versions are cleaned up on the first sync after upgrade.
class NotificationSyncEngine {
  final RoutineNotificationService _service;
  final NotificationService _notificationService;
  final Ref _ref;

  /// Serialises concurrent triggers so two simultaneous syncs don't race on
  /// the pending-requests diff.
  Future<void> _inFlight = Future.value();

  NotificationSyncEngine({
    required RoutineNotificationService service,
    required NotificationService notificationService,
    required Ref ref,
  })  : _service = service,
        _notificationService = notificationService,
        _ref = ref;

  FlutterLocalNotificationsPlugin get _plugin =>
      _notificationService.notificationsPlugin;

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// The queued-but-not-yet-started sync, if any. A sync that has not
  /// started observes every state change made before `sync()` was called,
  /// so additional triggers can share its result instead of queueing
  /// another full pass: N back-to-back triggers collapse into the running
  /// pass plus exactly one trailing pass.
  Future<NotificationSyncReport>? _queued;

  Future<NotificationSyncReport> sync({required SyncTrigger trigger}) {
    final queued = _queued;
    if (queued != null) {
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} '
        'coalesced into already-queued sync',
      );
      return queued;
    }

    final completer = Completer<NotificationSyncReport>();
    _queued = completer.future;
    final previous = _inFlight;
    _inFlight = completer.future.then<void>((_) {}, onError: (_) {});

    unawaited(() async {
      try {
        await previous;
      } catch (_) {}
      // Starting now — triggers arriving from here on must queue a fresh
      // pass so they observe state written after this point.
      _queued = null;
      try {
        completer.complete(await _runSync(trigger));
      } catch (e, st) {
        completer.completeError(e, st);
      }
    }());

    return completer.future;
  }

  // ─── Engine core ────────────────────────────────────────────────────────────

  Future<NotificationSyncReport> _runSync(SyncTrigger trigger) async {
    final stopwatch = Stopwatch()..start();
    final perCase = <String, int>{};
    void bumpCase(String c) =>
        perCase.update(c, (v) => v + 1, ifAbsent: () => 1);

    NotificationSyncReport empty() => NotificationSyncReport(
          scheduled: 0,
          cancelled: 0,
          skipped: 0,
          durationMs: stopwatch.elapsedMilliseconds,
          perCase: perCase,
        );

    if (!_notificationService.isInitialized) {
      _logger.warning(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} skip=service-not-ready',
      );
      return empty();
    }

    // Auth gate: while auth is still restoring we know nothing — touching the
    // schedule could wipe a valid one. The bootstrap re-triggers a sync as
    // soon as auth settles, so skipping here loses nothing.
    final auth = _ref.read(authProvider);
    if (auth.isLoading) {
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} skip=auth-loading',
      );
      return empty();
    }
    // Guests cannot have routines, so for scheduling purposes a guest
    // session is signed-out: desired set stays empty and any leftover
    // pending notifications (e.g. from a previous account) get cancelled.
    final loggedIn = auth.isLoggedIn && !auth.isGuest;

    // Routine gate: a failed Hive load must read as "unknown", not "empty" —
    // otherwise the cancel pass would wipe the schedule of a user who still
    // has a routine.
    final routineNotifier = _ref.read(routineProvider.notifier);
    if (routineNotifier.loadFailed) {
      _logger.warning(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} skip=routine-load-failed',
      );
      return empty();
    }

    final togglePrefs = await SharedPreferences.getInstance();
    final masterOn = togglePrefs.getBool(StorageKeys.notificationMasterEnabled) ?? true;
    final recitationOn = togglePrefs.getBool(StorageKeys.notificationRecitationEnabled) ?? true;
    final practiceOn = togglePrefs.getBool(StorageKeys.notificationPracticeEnabled) ?? true;
    final timerOn = togglePrefs.getBool(StorageKeys.notificationTimerEnabled) ?? true;
    final osGranted = await _notificationService.areNotificationsEnabled();

    final routineBlocks = _ref.read(routineProvider).blocks;
    final now = DateTime.now();

    final pending = await _plugin.pendingNotificationRequests();
    final ownedPending =
        pending.where((p) => NotificationIdScheme.isOurs(p.id)).toList();

    final desired = <int, DesiredNotification>{};

    if (!loggedIn || !masterOn || !osGranted) {
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} loggedIn=$loggedIn '
        'masterOn=$masterOn osGranted=$osGranted -> cancel-all (empty desired)',
      );
      if (!loggedIn) bumpCase('logged-out');
      if (!masterOn) bumpCase('5a');
    } else {
      for (final block in routineBlocks) {
        if (block.items.isEmpty || !block.notificationEnabled) continue;
        // A block may in principle hold more than one kind of item — handle
        // each by its own type instead of branching on the first item only.
        final hasRecitation =
            block.items.any((i) => i.type == RoutineItemType.recitation);
        if (hasRecitation) {
          final l10n = tolgeeAppLocalizationsFor(_ref.read(localeProvider));
          final entries = computeForRecitationBlock(
            block,
            now,
            masterOn: masterOn,
            recitationOn: recitationOn,
            l10n: l10n,
          );
          for (final e in entries) {
            desired[e.id] = e;
            bumpCase(e.debugCase);
          }
        }
        final hasAccumulator =
            block.items.any((i) => i.type == RoutineItemType.accumulator);
        if (hasAccumulator) {
          final entries = computeForAccumulatorBlock(
            block,
            now,
            masterOn: masterOn,
            practiceOn: practiceOn,
          );
          for (final e in entries) {
            desired[e.id] = e;
            bumpCase(e.debugCase);
          }
        }
        final hasTimer =
            block.items.any((i) => i.type == RoutineItemType.timer);
        if (hasTimer) {
          final entries = computeForTimerBlock(
            block,
            now,
            masterOn: masterOn,
            timerOn: timerOn,
          );
          for (final e in entries) {
            desired[e.id] = e;
            bumpCase(e.debugCase);
          }
        }
        final hasGroupCollection = block.items.any(
          (i) => i.type == RoutineItemType.groupRecitationCollection,
        );
        if (hasGroupCollection) {
          final entries = computeForGroupCollectionBlock(
            block,
            now,
            masterOn: masterOn,
            recitationOn: recitationOn,
          );
          for (final e in entries) {
            desired[e.id] = e;
            bumpCase(e.debugCase);
          }
        }
        final hasMyCollection = block.items.any(
          (i) => i.type == RoutineItemType.myRecitationCollection,
        );
        if (hasMyCollection) {
          final entries = computeForMyCollectionBlock(
            block,
            now,
            masterOn: masterOn,
            recitationOn: recitationOn,
          );
          for (final e in entries) {
            desired[e.id] = e;
            bumpCase(e.debugCase);
          }
        }
        final hasGroupAccumulator = block.items.any(
          (i) => i.type == RoutineItemType.groupAccumulator,
        );
        if (hasGroupAccumulator) {
          final entries = computeForGroupAccumulatorBlock(
            block,
            now,
            masterOn: masterOn,
            practiceOn: practiceOn,
          );
          for (final e in entries) {
            desired[e.id] = e;
            bumpCase(e.debugCase);
          }
        }
      }
    }

    // ── Diff against the pending snapshot taken above ──
    var scheduled = 0;
    var cancelled = 0;
    var skipped = 0;

    // Cancel: anything owned that is no longer desired. This also reconciles
    // legacy plan/series IDs left over from app versions that scheduled them
    // locally — they are never in `desired` now, and `isOurs` still recognises
    // their ranges, so they are cleaned up on the first post-upgrade sync.
    // The diagnostic test ID is preserved (the user explicitly schedules it).
    for (final p in ownedPending) {
      if (p.id == NotificationIdScheme.kDiagnosticTestId) continue;
      if (desired.containsKey(p.id)) continue;
      try {
        await _plugin.cancel(p.id);
        cancelled++;
        _logger.info(
          '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} action=cancel id=${p.id} '
          'reason="not in desired set"',
        );
      } catch (e) {
        _logger.warning('cancel id=${p.id} failed: $e');
      }
    }

    // Schedule: every desired entry is (re-)scheduled unconditionally.
    // zonedSchedule with the same ID atomically replaces the existing request,
    // so this is idempotent — and it is the only way to pick up fire-time
    // changes (block time edits, timezone moves) and to re-register alarms
    // that Android dropped (force-stop), since the plugin's pending list
    // exposes IDs but not fire times.
    final scheduleMode = await _resolveAndroidScheduleMode();
    for (final d in desired.values) {
      final ok = await _scheduleOne(d, trigger, scheduleMode);
      if (ok) {
        scheduled++;
      } else {
        skipped++;
      }
    }

    stopwatch.stop();
    _logger.info(
      '[NOTIFICATION_NEW_FLOW] sync done trigger=${trigger.name} '
      'scheduled=$scheduled cancelled=$cancelled skipped=$skipped '
      'duration=${stopwatch.elapsedMilliseconds}ms perCase=$perCase',
    );

    return NotificationSyncReport(
      scheduled: scheduled,
      cancelled: cancelled,
      skipped: skipped,
      durationMs: stopwatch.elapsedMilliseconds,
      perCase: perCase,
    );
  }

  /// Exact when the OS permits it; otherwise degrade to inexact so the user
  /// still gets the notification (slightly late) instead of nothing at all.
  /// Always exact-capable on iOS/macOS and Android < 12.
  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    final canExact = await _notificationService.canScheduleExactNotifications();
    if (canExact) return AndroidScheduleMode.exactAllowWhileIdle;
    _logger.warning(
      '[NOTIFICATION_NEW_FLOW] exact alarms not permitted — '
      'scheduling inexact so notifications still fire',
    );
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  // ─── Pure compute (testable) ────────────────────────────────────────────────

  /// Computes the single daily-repeat [DesiredNotification] for a recitation
  /// block (case 4). Returns `[]` when toggles are off or block is empty.
  @visibleForTesting
  List<DesiredNotification> computeForRecitationBlock(
    RoutineBlock block,
    DateTime now, {
    required bool masterOn,
    required bool recitationOn,
    required AppLocalizations l10n,
  }) {
    if (!masterOn) return const [];
    if (!recitationOn) return const [];
    if (block.items.isEmpty || !block.notificationEnabled) return const [];

    // Anchor on the first recitation rather than the first item so a block that
    // also holds a non-recitation session cannot hijack the title and payload.
    final firstItem = block.items.firstWhere(
      (i) => i.type == RoutineItemType.recitation,
      orElse: () => block.items.first,
    );
    final nowTz = tz.TZDateTime.from(now, tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      nowTz.year,
      nowTz.month,
      nowTz.day,
      block.time.hour,
      block.time.minute,
    );
    if (scheduledDate.isBefore(nowTz)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final payload = jsonEncode({
      'itemId': firstItem.id,
      'itemType': firstItem.type.name,
    });

    return [
      DesiredNotification(
        id: block.notificationId,
        fireAt: scheduledDate,
        title: routineItemDisplayTitle(firstItem, l10n),
        body: _recitationBody(block, l10n),
        payload: payload,
        sourceItem: firstItem,
        isDailyRepeat: true,
        debugCase: '4 daily-repeat',
      ),
    ];
  }

  /// Computes the single daily-repeat [DesiredNotification] for a mala
  /// (accumulator) block. Mirrors [computeForRecitationBlock] but is gated by
  /// the Practice sub-toggle and uses [NotificationIdScheme.accumulatorBlockId]
  /// so it never collides with a recitation daily-repeat in the same block.
  ///
  /// The title is the mala's own name (the user's stored preset title) and the
  /// body is a consistent default. Returns `[]` when toggles are off or the
  /// block holds no accumulator items.
  @visibleForTesting
  List<DesiredNotification> computeForAccumulatorBlock(
    RoutineBlock block,
    DateTime now, {
    required bool masterOn,
    required bool practiceOn,
  }) {
    if (!masterOn) return const [];
    if (!practiceOn) return const [];
    if (block.items.isEmpty || !block.notificationEnabled) return const [];

    final accumulators =
        block.items.where((i) => i.type == RoutineItemType.accumulator).toList();
    if (accumulators.isEmpty) return const [];

    final firstItem = accumulators.first;
    final nowTz = tz.TZDateTime.from(now, tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      nowTz.year,
      nowTz.month,
      nowTz.day,
      block.time.hour,
      block.time.minute,
    );
    if (scheduledDate.isBefore(nowTz)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final payload = jsonEncode({
      'itemId': firstItem.id,
      'itemType': firstItem.type.name,
    });

    return [
      DesiredNotification(
        id: NotificationIdScheme.accumulatorBlockId(block.notificationId),
        fireAt: scheduledDate,
        title: firstItem.title,
        body: _accumulatorBody(accumulators),
        payload: payload,
        sourceItem: firstItem,
        isDailyRepeat: true,
        debugCase: '4 daily-repeat-mala',
      ),
    ];
  }

  /// Computes the daily-repeat [DesiredNotification] for a timer block:
  /// a single "started" reminder at block time ("You've set a timer for X,
  /// starting now."). Mirrors the recitation/mala daily-repeat mechanism (a
  /// plain [DesiredNotification] scheduled with `matchDateTimeComponents.time`)
  /// — there is deliberately no "timer up" reminder and no live countdown.
  /// Gated by the Timer sub-toggle. Its own [NotificationIdScheme.timerStartId]
  /// range keeps it from colliding with any recitation/mala daily-repeat in the
  /// same block.
  ///
  /// Returns `[]` when toggles are off, the block is empty, or it holds no
  /// timer item with a positive [RoutineItem.durationMs].
  @visibleForTesting
  List<DesiredNotification> computeForTimerBlock(
    RoutineBlock block,
    DateTime now, {
    required bool masterOn,
    required bool timerOn,
  }) {
    if (!masterOn) return const [];
    if (!timerOn) return const [];
    if (block.items.isEmpty || !block.notificationEnabled) return const [];

    final timers = block.items
        .where((i) =>
            i.type == RoutineItemType.timer && (i.durationMs ?? 0) > 0)
        .toList();
    if (timers.isEmpty) return const [];
    final timer = timers.first;
    final durationMs = timer.durationMs!;

    final nowTz = tz.TZDateTime.from(now, tz.local);
    final title = timer.title.isNotEmpty ? timer.title : 'Timer';
    // Tapping the reminder opens the timer screen, which runs a fresh countdown.
    // `durationMs` is embedded so the tap works without re-resolving the routine
    // item (which may have lost its durationMs on a server round-trip, or not be
    // loaded yet on a cold start).
    final payload = jsonEncode({
      'itemId': timer.id,
      'itemType': timer.type.name,
      'durationMs': durationMs,
    });

    // Next occurrence of block time (roll to tomorrow if already past).
    var startAt = tz.TZDateTime(
      tz.local,
      nowTz.year,
      nowTz.month,
      nowTz.day,
      block.time.hour,
      block.time.minute,
    );
    if (startAt.isBefore(nowTz)) {
      startAt = startAt.add(const Duration(days: 1));
    }

    return [
      DesiredNotification(
        id: NotificationIdScheme.timerStartId(block.notificationId),
        fireAt: startAt,
        title: title,
        body: _timerStartBody(durationMs),
        payload: payload,
        sourceItem: timer,
        isDailyRepeat: true,
        debugCase: '4 daily-repeat-timer-start',
      ),
    ];
  }

  /// Computes the daily-repeat [DesiredNotification] for a group-recitation-
  /// collection (chants list) block. Mirrors [computeForAccumulatorBlock] but
  /// is gated by the Recitation sub-toggle (a collection is a set of chants)
  /// and uses [NotificationIdScheme.groupCollectionId] so it never collides
  /// with a recitation/mala/timer daily-repeat the same block may also hold.
  ///
  /// The title is the collection's own name and the body reports its chant
  /// count when known. Returns `[]` when toggles are off or the block holds
  /// no group-collection item.
  @visibleForTesting
  List<DesiredNotification> computeForGroupCollectionBlock(
    RoutineBlock block,
    DateTime now, {
    required bool masterOn,
    required bool recitationOn,
  }) {
    if (!masterOn) return const [];
    if (!recitationOn) return const [];
    if (block.items.isEmpty || !block.notificationEnabled) return const [];

    final collections = block.items
        .where((i) => i.type == RoutineItemType.groupRecitationCollection)
        .toList();
    if (collections.isEmpty) return const [];

    final firstItem = collections.first;
    final nowTz = tz.TZDateTime.from(now, tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      nowTz.year,
      nowTz.month,
      nowTz.day,
      block.time.hour,
      block.time.minute,
    );
    if (scheduledDate.isBefore(nowTz)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final payload = jsonEncode({
      'itemId': firstItem.id,
      'itemType': firstItem.type.name,
    });

    return [
      DesiredNotification(
        id: NotificationIdScheme.groupCollectionId(block.notificationId),
        fireAt: scheduledDate,
        title: firstItem.title,
        body: _collectionBody(firstItem),
        payload: payload,
        sourceItem: firstItem,
        isDailyRepeat: true,
        debugCase: '4 daily-repeat-group-collection',
      ),
    ];
  }

  /// Computes the daily-repeat [DesiredNotification] for a personal
  /// recitation collection. Uses a separate ID range from group collections so
  /// both can coexist in the same routine block.
  @visibleForTesting
  List<DesiredNotification> computeForMyCollectionBlock(
    RoutineBlock block,
    DateTime now, {
    required bool masterOn,
    required bool recitationOn,
  }) {
    if (!masterOn) return const [];
    if (!recitationOn) return const [];
    if (block.items.isEmpty || !block.notificationEnabled) return const [];

    final collections =
        block.items
            .where((i) => i.type == RoutineItemType.myRecitationCollection)
            .toList();
    if (collections.isEmpty) return const [];

    final firstItem = collections.first;
    final nowTz = tz.TZDateTime.from(now, tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      nowTz.year,
      nowTz.month,
      nowTz.day,
      block.time.hour,
      block.time.minute,
    );
    if (scheduledDate.isBefore(nowTz)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final payload = jsonEncode({
      'itemId': firstItem.id,
      'itemType': firstItem.type.name,
    });

    return [
      DesiredNotification(
        id: NotificationIdScheme.myCollectionId(block.notificationId),
        fireAt: scheduledDate,
        title: firstItem.title,
        body: _collectionBody(firstItem),
        payload: payload,
        sourceItem: firstItem,
        isDailyRepeat: true,
        debugCase: '4 daily-repeat-my-collection',
      ),
    ];
  }

  /// Daily-repeat for a group accumulation block; own ID range, Practice toggle.
  @visibleForTesting
  List<DesiredNotification> computeForGroupAccumulatorBlock(
    RoutineBlock block,
    DateTime now, {
    required bool masterOn,
    required bool practiceOn,
  }) {
    if (!masterOn) return const [];
    if (!practiceOn) return const [];
    if (block.items.isEmpty || !block.notificationEnabled) return const [];

    final accumulators =
        block.items
            .where((i) => i.type == RoutineItemType.groupAccumulator)
            .toList();
    if (accumulators.isEmpty) return const [];

    final firstItem = accumulators.first;
    final nowTz = tz.TZDateTime.from(now, tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      nowTz.year,
      nowTz.month,
      nowTz.day,
      block.time.hour,
      block.time.minute,
    );
    if (scheduledDate.isBefore(nowTz)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final payload = jsonEncode({
      'itemId': firstItem.id,
      'itemType': firstItem.type.name,
    });

    return [
      DesiredNotification(
        id: NotificationIdScheme.groupAccumulatorId(block.notificationId),
        fireAt: scheduledDate,
        title: firstItem.title,
        body: _groupAccumulatorBody(accumulators),
        payload: payload,
        sourceItem: firstItem,
        isDailyRepeat: true,
        debugCase: '4 daily-repeat-group-accumulator',
      ),
    ];
  }

  // ─── Scheduling primitives ──────────────────────────────────────────────────

  Future<bool> _scheduleOne(
    DesiredNotification d,
    SyncTrigger trigger,
    AndroidScheduleMode scheduleMode,
  ) async {
    final fireAt = d.fireAt;
    if (fireAt == null) return false;
    try {
      // Build only the platform-relevant pieces — each unused style is a
      // wasted image download/disk hit per notification.
      final isApple = Platform.isIOS || Platform.isMacOS;
      final androidStyle = isApple
          ? null
          : await _service.buildBigPictureStyle(
              d.sourceItem,
              overrideTitle: d.title,
              overrideBody: d.body,
            );
      final largeIcon =
          isApple ? null : await _service.getLargeIcon(d.sourceItem);
      final iosDetails = isApple
          ? await _service.buildIOSNotificationDetails(d.sourceItem)
          : null;

      final details = NotificationChannels.routineBlockDetails(
        styleInformation: androidStyle,
        largeIcon: largeIcon,
        iOSDetails: iosDetails,
      );

      Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
            d.id,
            d.title,
            d.body,
            fireAt,
            details,
            androidScheduleMode: mode,
            matchDateTimeComponents:
                d.isDailyRepeat ? DateTimeComponents.time : null,
            payload: d.payload,
          );

      try {
        await schedule(scheduleMode);
      } on PlatformException catch (e) {
        // Permission can be revoked between the per-sync check and this call
        // (or the check itself can be unreliable on some OEMs). Degrade to
        // inexact rather than dropping the notification entirely.
        if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
          _logger.warning(
            '[NOTIFICATION_NEW_FLOW] exact schedule failed for id=${d.id} '
            '(${e.code}) — retrying inexact',
          );
          await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
        } else {
          rethrow;
        }
      }
      _logger.info(
        '[NOTIFICATION_NEW_FLOW] trigger=${trigger.name} action=schedule '
        'id=${d.id} case=${d.debugCase} fireAt=${fireAt.toIso8601String()}',
      );
      return true;
    } catch (e, st) {
      _logger.error('schedule id=${d.id} failed', e, st);
      return false;
    }
  }

  // ─── Body templates ─────────────────────────────────────────────────────────

  String _recitationBody(RoutineBlock block, AppLocalizations l10n) {
    if (block.items.isEmpty) return 'Check your daily routine';
    final firstItem = routineItemDisplayTitle(block.items.first, l10n);
    final remaining = block.items.length - 1;
    if (remaining == 1) return '$firstItem and 1 other';
    if (remaining > 1) return '$firstItem and $remaining others';
    return firstItem;
  }

  /// Consistent default body for a mala (accumulator) reminder. The title
  /// already carries the mala's name, so the body stays generic.
  String _accumulatorBody(List<RoutineItem> items) {
    final remaining = items.length - 1;
    if (remaining == 1) return 'Time for your mala practice and 1 more';
    if (remaining > 1) return 'Time for your mala practice and $remaining more';
    return 'Time for your mala practice';
  }

  String _groupAccumulatorBody(List<RoutineItem> items) {
    final remaining = items.length - 1;
    if (remaining == 1) return 'Time for your group accumulation and 1 more';
    if (remaining > 1) {
      return 'Time for your group accumulation and $remaining more';
    }
    return 'Time for your group accumulation';
  }

  /// Body for a recitation collection (chants list) reminder. Reports
  /// the chant count when known (`"12 chants"`); falls back to a generic line
  /// when [RoutineItem.itemCount] wasn't populated (e.g. stale local data).
  String _collectionBody(RoutineItem item) {
    final count = item.itemCount;
    if (count != null && count > 0) {
      return count == 1 ? '1 chant' : '$count chants';
    }
    return 'Time for your chant practice';
  }

  /// "Started now" body for a timer reminder. Formats [durationMs] as minutes,
  /// promoting to hours when ≥ 60 minutes (e.g. "30 minutes", "1 hour",
  /// "1 hour 30 minutes"). Hardcoded English, matching the other body helpers.
  String _timerStartBody(int durationMs) =>
      "You've set a timer for ${_formatTimerDuration(durationMs)}, Press here to start.";

  String _formatTimerDuration(int durationMs) {
    final totalMinutes = (durationMs / 60000).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final parts = <String>[];
    if (hours > 0) parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');
    if (minutes > 0) {
      parts.add('$minutes ${minutes == 1 ? 'minute' : 'minutes'}');
    }
    if (parts.isEmpty) return '0 minutes';
    return parts.join(' ');
  }
}

/// App-wide engine provider.
final notificationSyncEngineProvider = Provider<NotificationSyncEngine>((ref) {
  return NotificationSyncEngine(
    service: ref.watch(routineNotificationServiceProvider),
    notificationService: NotificationService(),
    ref: ref,
  );
});
