import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_accumulation_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which accumulation the beads count into, carried as `mode`.
enum MalaMode { personal, group }

/// How the beads were advanced during a session, carried as `input`.
enum MalaInput { tap, swipe, mixed }

/// What switched the mantra, carried on `mala_mantra_switched` as `via`.
enum MalaSwitchVia { carousel, catalogue }

extension MalaSelectionAnalytics on MalaAccumulationSelection {
  MalaMode get analyticsMode => isPersonal ? MalaMode.personal : MalaMode.group;
}

/// The group's own id for a selected group accumulation, so `group_id` joins
/// with the group chat and event analytics. Null until the joined groups have
/// loaded, or when [groupAccumulatorId] is not among them.
String? malaGroupIdFor(
  List<AccumulatorGroup> groups,
  String? groupAccumulatorId,
) {
  if (groupAccumulatorId == null) return null;
  for (final group in groups) {
    if (group.groupAccumulatorId == groupAccumulatorId) return group.groupId;
  }
  return null;
}

/// Product analytics for the mala: one method per tracked action, so the
/// event names and their property keys live in one place. Every call fires
/// and forgets; callers fire after the count or change really happened, never
/// per bead tap and never optimistically.
class MalaAnalytics {
  const MalaAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// Once per screen open, after the persisted selection has loaded so
  /// [mode] is the one the user will count into.
  void screenOpened({
    required String presetId,
    required String mantraName,
    required MalaMode mode,
    String? groupId,
    String? source,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.malaScreenOpened, {
      AnalyticsProperties.presetId: presetId,
      AnalyticsProperties.mantraName: mantraName,
      AnalyticsProperties.mode: mode.name,
      if (groupId != null) AnalyticsProperties.groupId: groupId,
      if (source != null) AnalyticsProperties.source: source,
    });
  }

  /// [startingTotal] is the accumulation's total before the first bead.
  void sessionStarted({
    required String presetId,
    required MalaMode mode,
    String? groupId,
    required int startingTotal,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.malaSessionStarted, {
      AnalyticsProperties.presetId: presetId,
      AnalyticsProperties.mode: mode.name,
      if (groupId != null) AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.startingTotal: startingTotal,
    });
  }

  /// [rounds] counts rounds in this session; [secondsSinceLastRound] is null
  /// for the first round of a session.
  void roundCompleted({
    required String presetId,
    required String mantraName,
    required int rounds,
    required MalaMode mode,
    String? groupId,
    int? secondsSinceLastRound,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.malaRoundCompleted, {
      AnalyticsProperties.presetId: presetId,
      AnalyticsProperties.mantraName: mantraName,
      AnalyticsProperties.rounds: rounds,
      AnalyticsProperties.mode: mode.name,
      if (groupId != null) AnalyticsProperties.groupId: groupId,
      if (secondsSinceLastRound != null)
        AnalyticsProperties.secondsSinceLastRound: secondsSinceLastRound,
    });
  }

  /// [durationSeconds] runs from the first counted bead to the last.
  void sessionEnded({
    required String presetId,
    required MalaMode mode,
    String? groupId,
    required int durationSeconds,
    required int beadsCounted,
    required int roundsCompleted,
    required MalaInput input,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.malaSessionEnded, {
      AnalyticsProperties.presetId: presetId,
      AnalyticsProperties.mode: mode.name,
      if (groupId != null) AnalyticsProperties.groupId: groupId,
      AnalyticsProperties.durationSeconds: durationSeconds,
      AnalyticsProperties.beadsCounted: beadsCounted,
      AnalyticsProperties.roundsCompleted: roundsCompleted,
      AnalyticsProperties.input: input.name,
    });
  }

  void mantraSwitched({
    required String fromPresetId,
    required String toPresetId,
    required MalaSwitchVia via,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.malaMantraSwitched, {
      AnalyticsProperties.fromPresetId: fromPresetId,
      AnalyticsProperties.toPresetId: toPresetId,
      AnalyticsProperties.via: via.name,
    });
  }

  /// [groupId] is the group entered, or the one left when going personal.
  void modeChanged({
    required MalaMode from,
    required MalaMode to,
    String? groupId,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.malaModeChanged, {
      AnalyticsProperties.from: from.name,
      AnalyticsProperties.to: to.name,
      if (groupId != null) AnalyticsProperties.groupId: groupId,
    });
  }

  /// The "add rounds" dialog was confirmed and the rounds were counted.
  void offlineRoundsAdded({required String presetId, required int rounds}) {
    _analytics.trackInBackground(AnalyticsEvents.malaOfflineRoundsAdded, {
      AnalyticsProperties.presetId: presetId,
      AnalyticsProperties.rounds: rounds,
    });
  }

  /// [reason] is the sync trigger that failed; [pendingDelta] the beads still
  /// unsynced afterwards.
  void syncFailed({required String reason, required int pendingDelta}) {
    _analytics.trackInBackground(AnalyticsEvents.malaSyncFailed, {
      AnalyticsProperties.reason: reason,
      AnalyticsProperties.pendingDelta: pendingDelta,
    });
  }
}

/// Groups counted beads into sessions for `mala_session_started`,
/// `mala_round_completed` and `mala_session_ended`.
///
/// A session starts on the first counted bead and ends when the screen closes
/// ([dispose]), the app leaves the foreground, no bead lands for
/// [idleTimeout], or the next bead belongs to another mantra or accumulation.
/// Its duration runs from the first bead to the last, so idle time is never
/// counted as practice.
class MalaSessionTracker with WidgetsBindingObserver {
  MalaSessionTracker(
    this._analytics, {
    DateTime Function()? clock,
    this.idleTimeout = const Duration(minutes: 5),
  }) : _clock = clock ?? DateTime.now;

  final MalaAnalytics _analytics;
  final DateTime Function() _clock;
  final Duration idleTimeout;

  _MalaSession? _session;
  Timer? _idle;

  void start() => WidgetsBinding.instance.addObserver(this);

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    end();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      end();
    }
  }

  /// One counted bead; [total] is the accumulation's total after it landed.
  void onBead({
    required String presetId,
    required String mantraName,
    required MalaMode mode,
    required String? groupId,
    required int total,
    required bool roundComplete,
    required MalaInput input,
  }) {
    final now = _clock();
    var session = _session;
    if (session != null && !session.matches(presetId, mode, groupId)) {
      end();
      session = null;
    }
    if (session == null) {
      session = _MalaSession(
        presetId: presetId,
        mode: mode,
        groupId: groupId,
        startedAt: now,
        input: input,
      );
      _session = session;
      _analytics.sessionStarted(
        presetId: presetId,
        mode: mode,
        groupId: groupId,
        startingTotal: total - 1,
      );
    }
    session.beads++;
    session.lastBeadAt = now;
    if (session.input != input) session.input = MalaInput.mixed;
    if (roundComplete) {
      final last = session.lastRoundAt;
      session.rounds++;
      session.lastRoundAt = now;
      _analytics.roundCompleted(
        presetId: presetId,
        mantraName: mantraName,
        rounds: session.rounds,
        mode: mode,
        groupId: groupId,
        secondsSinceLastRound:
            last == null ? null : now.difference(last).inSeconds,
      );
    }
    _idle?.cancel();
    _idle = Timer(idleTimeout, end);
  }

  /// Ends the open session, if any. Safe to call repeatedly.
  void end() {
    _idle?.cancel();
    _idle = null;
    final session = _session;
    if (session == null) return;
    _session = null;
    _analytics.sessionEnded(
      presetId: session.presetId,
      mode: session.mode,
      groupId: session.groupId,
      durationSeconds:
          session.lastBeadAt.difference(session.startedAt).inSeconds,
      beadsCounted: session.beads,
      roundsCompleted: session.rounds,
      input: session.input,
    );
  }
}

class _MalaSession {
  _MalaSession({
    required this.presetId,
    required this.mode,
    required this.groupId,
    required this.startedAt,
    required this.input,
  }) : lastBeadAt = startedAt;

  final String presetId;
  final MalaMode mode;
  final String? groupId;
  final DateTime startedAt;
  DateTime lastBeadAt;
  DateTime? lastRoundAt;
  MalaInput input;
  int beads = 0;
  int rounds = 0;

  bool matches(String presetId, MalaMode mode, String? groupId) =>
      this.presetId == presetId && this.mode == mode && this.groupId == groupId;
}

final malaAnalyticsProvider = Provider<MalaAnalytics>((ref) {
  return MalaAnalytics(ref.watch(analyticsServiceProvider));
});
