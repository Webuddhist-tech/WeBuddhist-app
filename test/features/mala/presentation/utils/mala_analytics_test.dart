import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/presentation/utils/mala_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingAnalyticsService service;
  late MalaAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = MalaAnalytics(service);
  });

  group('MalaAnalytics', () {
    test('screenOpened names the preset, mantra, mode and source', () {
      analytics.screenOpened(
        presetId: 'chenrezig',
        mantraName: 'Chenrezig',
        mode: MalaMode.group,
        groupId: 'g1',
        source: 'practice',
      );

      expect(service.eventNames, [AnalyticsEvents.malaScreenOpened]);
      expect(service.events.single.properties, {
        'preset_id': 'chenrezig',
        'mantra_name': 'Chenrezig',
        'mode': 'group',
        'group_id': 'g1',
        'source': 'practice',
      });
    });

    test('personal events carry no group id', () {
      analytics.screenOpened(
        presetId: 'chenrezig',
        mantraName: 'Chenrezig',
        mode: MalaMode.personal,
      );

      expect(service.events.single.properties, {
        'preset_id': 'chenrezig',
        'mantra_name': 'Chenrezig',
        'mode': 'personal',
      });
    });

    test('mantraSwitched keys both sides by preset id', () {
      analytics.mantraSwitched(
        fromPresetId: 'a',
        toPresetId: 'b',
        via: MalaSwitchVia.carousel,
      );

      expect(service.eventNames, [AnalyticsEvents.malaMantraSwitched]);
      expect(service.events.single.properties, {
        'from_preset_id': 'a',
        'to_preset_id': 'b',
        'via': 'carousel',
      });
    });

    test('mode change, offline rounds and sync failure', () {
      analytics.modeChanged(
        from: MalaMode.personal,
        to: MalaMode.group,
        groupId: 'g1',
      );
      analytics.offlineRoundsAdded(presetId: 'chenrezig', rounds: 3);
      analytics.syncFailed(reason: 'debounce', pendingDelta: 12);

      expect(service.eventNames, [
        AnalyticsEvents.malaModeChanged,
        AnalyticsEvents.malaOfflineRoundsAdded,
        AnalyticsEvents.malaSyncFailed,
      ]);
      expect(service.events[0].properties, {
        'from': 'personal',
        'to': 'group',
        'group_id': 'g1',
      });
      expect(service.events[1].properties, {
        'preset_id': 'chenrezig',
        'rounds': 3,
      });
      expect(service.events[2].properties, {
        'reason': 'debounce',
        'pending_delta': 12,
      });
    });
  });

  group('MalaSessionTracker', () {
    late _Clock clock;
    late MalaSessionTracker tracker;

    setUp(() {
      clock = _Clock();
      tracker = MalaSessionTracker(
        analytics,
        clock: clock.now,
        idleTimeout: const Duration(milliseconds: 30),
      );
    });

    tearDown(() => tracker.dispose());

    void bead({
      required int total,
      bool roundComplete = false,
      MalaInput input = MalaInput.tap,
      MalaMode mode = MalaMode.personal,
      String? groupId,
    }) {
      tracker.onBead(
        presetId: 'chenrezig',
        mantraName: 'Chenrezig',
        mode: mode,
        groupId: groupId,
        total: total,
        roundComplete: roundComplete,
        input: input,
      );
    }

    test('the first bead starts a session with the total before it', () {
      bead(total: 41);
      bead(total: 42);

      expect(service.eventNames, [AnalyticsEvents.malaSessionStarted]);
      expect(service.events.single.properties, {
        'preset_id': 'chenrezig',
        'mode': 'personal',
        'starting_total': 40,
      });
    });

    test('a completed round counts rounds and seconds within the session', () {
      bead(total: 107);
      clock.advance(const Duration(seconds: 90));
      bead(total: 108, roundComplete: true);
      clock.advance(const Duration(seconds: 100));
      bead(total: 216, roundComplete: true);

      expect(service.eventNames, [
        AnalyticsEvents.malaSessionStarted,
        AnalyticsEvents.malaRoundCompleted,
        AnalyticsEvents.malaRoundCompleted,
      ]);
      expect(service.events[1].properties, {
        'preset_id': 'chenrezig',
        'mantra_name': 'Chenrezig',
        'rounds': 1,
        'mode': 'personal',
      });
      expect(service.events[2].properties, {
        'preset_id': 'chenrezig',
        'mantra_name': 'Chenrezig',
        'rounds': 2,
        'mode': 'personal',
        'seconds_since_last_round': 100,
      });
    });

    test('end reports first bead to last, once, with mixed input', () {
      bead(total: 1);
      clock.advance(const Duration(seconds: 30));
      bead(total: 2, input: MalaInput.swipe);
      tracker.end();
      tracker.end();

      expect(service.eventNames, [
        AnalyticsEvents.malaSessionStarted,
        AnalyticsEvents.malaSessionEnded,
      ]);
      expect(service.events.last.properties, {
        'preset_id': 'chenrezig',
        'mode': 'personal',
        'duration_s': 30,
        'beads_counted': 2,
        'rounds_completed': 0,
        'input': 'mixed',
      });
    });

    test('a bead into another accumulation ends the session first', () {
      bead(total: 1);
      bead(total: 5, mode: MalaMode.group, groupId: 'g1');

      expect(service.eventNames, [
        AnalyticsEvents.malaSessionStarted,
        AnalyticsEvents.malaSessionEnded,
        AnalyticsEvents.malaSessionStarted,
      ]);
      expect(service.events.last.properties, {
        'preset_id': 'chenrezig',
        'mode': 'group',
        'group_id': 'g1',
        'starting_total': 4,
      });
    });

    test('idle for the timeout ends the session', () async {
      bead(total: 1);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(service.eventNames, [
        AnalyticsEvents.malaSessionStarted,
        AnalyticsEvents.malaSessionEnded,
      ]);
    });

    test('leaving the foreground ends the session', () {
      tracker.start();
      bead(total: 1);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      expect(service.eventNames, [
        AnalyticsEvents.malaSessionStarted,
        AnalyticsEvents.malaSessionEnded,
      ]);
    });

    test('dispose ends the session', () {
      tracker.start();
      bead(total: 1);
      tracker.dispose();

      expect(service.eventNames, [
        AnalyticsEvents.malaSessionStarted,
        AnalyticsEvents.malaSessionEnded,
      ]);
    });
  });

  test('malaGroupIdFor maps the accumulation to its group', () {
    const groups = [
      AccumulatorGroup(
        groupAccumulatorId: 'ga1',
        groupId: 'g1',
        userTotalCount: 0,
        isJoined: true,
      ),
    ];

    expect(malaGroupIdFor(groups, 'ga1'), 'g1');
    expect(malaGroupIdFor(groups, 'ga2'), isNull);
    expect(malaGroupIdFor(groups, null), isNull);
  });
}

class _Clock {
  DateTime _now = DateTime(2026, 1, 1, 10);

  DateTime now() => _now;

  void advance(Duration duration) => _now = _now.add(duration);
}
