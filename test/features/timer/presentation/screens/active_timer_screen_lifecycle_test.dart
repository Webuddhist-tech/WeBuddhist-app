import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/timer/data/services/timer_live_activity.dart';
import 'package:flutter_pecha/features/timer/data/services/timer_session_notifier.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/domain/usecases/stop_user_timer_usecase.dart';
import 'package:flutter_pecha/features/timer/presentation/providers/timers_providers.dart';
import 'package:flutter_pecha/features/timer/presentation/screens/active_timer_screen.dart';
import 'package:flutter_pecha/features/timer/presentation/services/timer_sound_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('schedules completion bell on inactive and cancels on resume', (
    tester,
  ) async {
    final clock = _FakeClock();
    final notifier = _FakeTimerSessionNotifications();
    final soundPlayer = _FakeTimerBellPlayer();

    await _pumpScreen(
      tester,
      clock: clock,
      notifier: notifier,
      soundPlayer: soundPlayer,
    );
    await _advanceThroughCountdown(tester, clock);

    expect(soundPlayer.playCount, 1);
    expect(notifier.scheduleRequests, isEmpty);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(notifier.scheduleRequests, hasLength(1));

    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(notifier.scheduleRequests, hasLength(1));

    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(notifier.cancelCompletionCount, 1);
    expect(soundPlayer.playCount, 1);
  });

  testWidgets(
    'resume after an armed background completion does not replay the bell',
    (tester) async {
      final clock = _FakeClock();
      final notifier = _FakeTimerSessionNotifications();
      final soundPlayer = _FakeTimerBellPlayer();

      await _pumpScreen(
        tester,
        clock: clock,
        notifier: notifier,
        soundPlayer: soundPlayer,
      );
      await _advanceThroughCountdown(tester, clock);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(notifier.scheduleRequests, hasLength(1));
      await tester.pump();
      clock.advance(_timerDuration + const Duration(milliseconds: 1));

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(soundPlayer.playCount, 1);
      expect(notifier.cancelCompletionCount, 1);
      expect(notifier.cancelAllCount, 1);
    },
  );

  testWidgets(
    'resume after an inexact background completion keeps fallback bell',
    (tester) async {
      final clock = _FakeClock();
      final notifier = _FakeTimerSessionNotifications(
        scheduleResult: TimerCompletionScheduleResult.inexact,
      );
      final soundPlayer = _FakeTimerBellPlayer();

      await _pumpScreen(
        tester,
        clock: clock,
        notifier: notifier,
        soundPlayer: soundPlayer,
      );
      await _advanceThroughCountdown(tester, clock);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(notifier.scheduleRequests, hasLength(1));
      await tester.pump();
      clock.advance(_timerDuration + const Duration(milliseconds: 1));

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(soundPlayer.playCount, 2);
      expect(notifier.cancelCompletionCount, 1);
      expect(notifier.cancelAllCount, 1);
    },
  );

  testWidgets(
    'resume after an unarmed background completion plays fallback bell',
    (tester) async {
      final clock = _FakeClock();
      final notifier = _FakeTimerSessionNotifications(
        scheduleResult: TimerCompletionScheduleResult.none,
      );
      final soundPlayer = _FakeTimerBellPlayer();

      await _pumpScreen(
        tester,
        clock: clock,
        notifier: notifier,
        soundPlayer: soundPlayer,
      );
      await _advanceThroughCountdown(tester, clock);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(notifier.scheduleRequests, hasLength(1));
      clock.advance(_timerDuration + const Duration(milliseconds: 1));

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(soundPlayer.playCount, 2);
    },
  );

  testWidgets(
    'reordered schedule and cancel futures leave newest alarm armed',
    (tester) async {
      final clock = _FakeClock();
      final notifier = _FakeTimerSessionNotifications.withControlledSchedules();
      final soundPlayer = _FakeTimerBellPlayer();

      await _pumpScreen(
        tester,
        clock: clock,
        notifier: notifier,
        soundPlayer: soundPlayer,
      );
      await _advanceThroughCountdown(tester, clock);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(notifier.scheduleRequests, hasLength(1));
      expect(notifier.pendingSchedules, hasLength(1));

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(notifier.scheduleRequests, hasLength(1));
      expect(notifier.cancelCompletionCount, 0);

      notifier.completeNextSchedule(TimerCompletionScheduleResult.exact);
      await tester.pump();
      await tester.pump();

      expect(notifier.cancelCompletionCount, 1);
      expect(notifier.scheduleRequests, hasLength(2));
      expect(notifier.pendingSchedules, hasLength(1));

      notifier.completeNextSchedule(TimerCompletionScheduleResult.exact);
      await tester.pump();

      clock.advance(_timerDuration + const Duration(milliseconds: 1));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(soundPlayer.playCount, 1);
      expect(notifier.cancelCompletionCount, 2);
    },
  );
}

const _timerDuration = Duration(seconds: 10);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeClock clock,
  required _FakeTimerSessionNotifications notifier,
  required _FakeTimerBellPlayer soundPlayer,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        stopUserTimerUseCaseProvider.overrideWithValue(
          StopUserTimerUseCase(
            ({required durationMs, required timerId}) async =>
                Right<Failure, void>(null),
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ActiveTimerScreen(
          presetTimer: PresetTimer(
            id: 'timer-1',
            name: 'Meditation',
            durationMs: _timerDuration.inMilliseconds,
          ),
          clock: clock.now,
          soundPlayer: soundPlayer,
          sessionNotifier: notifier,
          liveActivity: _FakeTimerLockScreenActivity(),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _advanceThroughCountdown(
  WidgetTester tester,
  _FakeClock clock,
) async {
  for (var i = 0; i < 5; i++) {
    clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pump();
}

class _FakeClock {
  DateTime _now = DateTime(2026, 1, 1, 10);

  DateTime now() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}

class _FakeTimerBellPlayer implements TimerBellPlayer {
  int playCount = 0;
  int disposeCount = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> play() async {
    playCount++;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}

class _FakeTimerSessionNotifications implements TimerSessionNotifications {
  _FakeTimerSessionNotifications({this.scheduleResult})
    : _scheduleCompleters = null;

  _FakeTimerSessionNotifications.withControlledSchedules()
    : scheduleResult = null,
      _scheduleCompleters = Queue<Completer<TimerCompletionScheduleResult>>();

  final TimerCompletionScheduleResult? scheduleResult;
  final Queue<Completer<TimerCompletionScheduleResult>>? _scheduleCompleters;
  final List<DateTime> scheduleRequests = [];
  final List<DateTime> runningNotifications = [];
  int cancelCompletionCount = 0;
  int cancelAllCount = 0;

  List<Completer<TimerCompletionScheduleResult>> get pendingSchedules =>
      List.unmodifiable(_scheduleCompleters ?? const []);

  void completeNextSchedule(TimerCompletionScheduleResult value) {
    _scheduleCompleters!.removeFirst().complete(value);
  }

  @override
  Future<void> showRunning({
    required DateTime endsAt,
    required String title,
    required String body,
  }) async {
    runningNotifications.add(endsAt);
  }

  @override
  Future<void> showPaused({
    required String title,
    required String body,
  }) async {}

  @override
  Future<TimerCompletionScheduleResult> scheduleCompletion({
    required DateTime endsAt,
    required String title,
    required String body,
  }) async {
    scheduleRequests.add(endsAt);
    if (_scheduleCompleters != null) {
      final completer = Completer<TimerCompletionScheduleResult>();
      _scheduleCompleters.add(completer);
      return completer.future;
    }
    return scheduleResult ?? TimerCompletionScheduleResult.exact;
  }

  @override
  Future<void> cancelCompletion() async {
    cancelCompletionCount++;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
  }
}

class _FakeTimerLockScreenActivity implements TimerLockScreenActivity {
  @override
  Future<void> start({
    required String sessionName,
    required DateTime endsAt,
    required int totalSeconds,
  }) async {}

  @override
  Future<void> update({
    required DateTime? endsAt,
    required bool isPaused,
    required int remainingSeconds,
  }) async {}

  @override
  Future<void> end() async {}
}
