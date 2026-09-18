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
import 'package:flutter_pecha/features/timer/presentation/services/timer_keep_alive.dart';
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
        scheduleResult: TimerBellScheduleResult.inexact,
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
        scheduleResult: TimerBellScheduleResult.none,
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

      notifier.completeNextSchedule(TimerBellScheduleResult.exact);
      await tester.pump();
      await tester.pump();

      expect(notifier.cancelCompletionCount, 1);
      expect(notifier.scheduleRequests, hasLength(2));
      expect(notifier.pendingSchedules, hasLength(1));

      notifier.completeNextSchedule(TimerBellScheduleResult.exact);
      await tester.pump();

      clock.advance(_timerDuration + const Duration(milliseconds: 1));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(soundPlayer.playCount, 1);
      expect(notifier.cancelCompletionCount, 2);
    },
  );

  testWidgets('a failed completion schedule is retried on the next event', (
    tester,
  ) async {
    final clock = _FakeClock();
    final notifier = _FakeTimerSessionNotifications(
      scheduleResult: TimerBellScheduleResult.none,
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
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(notifier.scheduleRequests, hasLength(2));
  });

  group('keep-alive', () {
    testWidgets('is held for the session and released when it completes', (
      tester,
    ) async {
      final clock = _FakeClock();
      final keepAlive = _FakeTimerKeepAlive();
      final soundPlayer = _FakeTimerBellPlayer();

      await _pumpScreen(
        tester,
        clock: clock,
        notifier: _FakeTimerSessionNotifications(),
        soundPlayer: soundPlayer,
        keepAlive: keepAlive,
      );

      expect(keepAlive.isHolding, isTrue);

      await _advanceThroughCountdown(tester, clock);
      expect(keepAlive.isHolding, isTrue);

      await _advanceBy(tester, clock, _timerDuration);
      expect(keepAlive.isHolding, isFalse);
    });

    testWidgets('is released while paused and retaken on resume', (
      tester,
    ) async {
      final clock = _FakeClock();
      final keepAlive = _FakeTimerKeepAlive();

      await _pumpScreen(
        tester,
        clock: clock,
        notifier: _FakeTimerSessionNotifications(),
        soundPlayer: _FakeTimerBellPlayer(),
        keepAlive: keepAlive,
      );
      await _advanceThroughCountdown(tester, clock);

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(keepAlive.isHolding, isFalse);

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(keepAlive.isHolding, isTrue);
    });
  });

  testWidgets('the keep-alive is held until the completion bell has rung', (
    tester,
  ) async {
    final clock = _FakeClock();
    final keepAlive = _FakeTimerKeepAlive();
    final soundPlayer = _FakeTimerBellPlayer(holdsUntilFinished: true);

    await _pumpScreen(
      tester,
      clock: clock,
      notifier: _FakeTimerSessionNotifications(),
      soundPlayer: soundPlayer,
      keepAlive: keepAlive,
    );
    await _advanceThroughCountdown(tester, clock);
    await _advanceBy(tester, clock, _timerDuration);

    // The bell is still ringing: releasing the audio session now would cut it
    // off on a locked screen.
    expect(soundPlayer.playCount, 2);
    expect(keepAlive.isHolding, isTrue);

    soundPlayer.finishPlayback();
    await tester.pump();

    expect(keepAlive.isHolding, isFalse);
  });

  testWidgets('a bell the OS drops is treated as unscheduled', (tester) async {
    final clock = _FakeClock();
    final notifier = _FakeTimerSessionNotifications(
      scheduleResult: TimerBellScheduleResult.none,
    );
    final soundPlayer = _FakeTimerBellPlayer();

    await _pumpScreen(
      tester,
      clock: clock,
      notifier: notifier,
      soundPlayer: soundPlayer,
    );
    await _lockScreen(tester);
    clock.advance(const Duration(seconds: 8));
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // Nothing rang while locked, so the start bell is rung on the way back in.
    expect(soundPlayer.playCount, 1);
  });

  group('screen locked during the pre-roll countdown', () {
    testWidgets('arms both the start and the completion bell', (tester) async {
      final clock = _FakeClock();
      final notifier = _FakeTimerSessionNotifications();

      await _pumpScreen(
        tester,
        clock: clock,
        notifier: notifier,
        soundPlayer: _FakeTimerBellPlayer(),
      );
      final startsAt = clock.now().add(const Duration(seconds: 5));

      await _lockScreen(tester);

      expect(notifier.startRequests, [startsAt]);
      expect(notifier.scheduleRequests, [startsAt.add(_timerDuration)]);
    });

    testWidgets(
      'the app rings both bells itself while it keeps running, disarming the '
      'alarms first',
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

        await _lockScreen(tester);
        await _advanceThroughCountdown(tester, clock);

        expect(soundPlayer.playCount, 1);
        expect(notifier.cancelStartCount, 1);

        await _advanceBy(tester, clock, _timerDuration);

        expect(soundPlayer.playCount, 2);
        expect(notifier.cancelCompletionCount, 1);
      },
    );

    testWidgets(
      'resuming after an exact start bell does not replay it and counts the '
      'locked time',
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

        await _lockScreen(tester);
        // Suspended iOS app: the clock moves, but no timer callbacks fire.
        clock.advance(const Duration(seconds: 8));
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        expect(soundPlayer.playCount, 0);
        expect(find.text('00 : 07'), findsOneWidget);
        expect(notifier.cancelCompletionCount, 1);

        await _advanceBy(tester, clock, const Duration(seconds: 7));
        expect(soundPlayer.playCount, 1);
      },
    );

    testWidgets('resuming after an inexact start bell rings it in-app', (
      tester,
    ) async {
      final clock = _FakeClock();
      final soundPlayer = _FakeTimerBellPlayer();

      await _pumpScreen(
        tester,
        clock: clock,
        notifier: _FakeTimerSessionNotifications(
          scheduleResult: TimerBellScheduleResult.inexact,
        ),
        soundPlayer: soundPlayer,
      );

      await _lockScreen(tester);
      clock.advance(const Duration(seconds: 8));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(soundPlayer.playCount, 1);
      expect(find.text('00 : 07'), findsOneWidget);
    });

    testWidgets(
      'resuming after the whole session ended with exact bells stays silent',
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

        await _lockScreen(tester);
        clock.advance(const Duration(seconds: 30));
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        expect(soundPlayer.playCount, 0);
        expect(find.text('00 : 00'), findsOneWidget);
        expect(notifier.cancelAllCount, 1);
      },
    );

    testWidgets('resuming after the session ended with no alarms rings once', (
      tester,
    ) async {
      final clock = _FakeClock();
      final soundPlayer = _FakeTimerBellPlayer();

      await _pumpScreen(
        tester,
        clock: clock,
        notifier: _FakeTimerSessionNotifications(
          scheduleResult: TimerBellScheduleResult.none,
        ),
        soundPlayer: soundPlayer,
      );

      await _lockScreen(tester);
      clock.advance(const Duration(seconds: 30));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(soundPlayer.playCount, 1);
    });
  });
}

Future<void> _lockScreen(WidgetTester tester) async {
  final binding = TestWidgetsFlutterBinding.instance;
  binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  await tester.pump();
  binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await tester.pump();
}

Future<void> _advanceBy(
  WidgetTester tester,
  _FakeClock clock,
  Duration duration,
) async {
  for (var i = 0; i < duration.inSeconds; i++) {
    clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pump();
}

const _timerDuration = Duration(seconds: 10);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeClock clock,
  required _FakeTimerSessionNotifications notifier,
  required _FakeTimerBellPlayer soundPlayer,
  _FakeTimerKeepAlive? keepAlive,
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
          keepAlive: keepAlive ?? _FakeTimerKeepAlive(),
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
  _FakeTimerBellPlayer({this.holdsUntilFinished = false});

  /// Mirrors just_audio: `play()` only completes when playback does.
  final bool holdsUntilFinished;
  final List<Completer<void>> _playing = [];
  int playCount = 0;
  int disposeCount = 0;

  void finishPlayback() {
    for (final completer in _playing) {
      if (!completer.isCompleted) completer.complete();
    }
    _playing.clear();
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> play() {
    playCount++;
    if (!holdsUntilFinished) return Future<void>.value();
    final completer = Completer<void>();
    _playing.add(completer);
    return completer.future;
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
      _scheduleCompleters = Queue<Completer<TimerBellScheduleResult>>();

  final TimerBellScheduleResult? scheduleResult;
  final Queue<Completer<TimerBellScheduleResult>>? _scheduleCompleters;
  final List<DateTime> scheduleRequests = [];
  final List<DateTime> startRequests = [];
  int cancelStartCount = 0;
  final List<DateTime> runningNotifications = [];
  int cancelCompletionCount = 0;
  int cancelAllCount = 0;

  List<Completer<TimerBellScheduleResult>> get pendingSchedules =>
      List.unmodifiable(_scheduleCompleters ?? const []);

  void completeNextSchedule(TimerBellScheduleResult value) {
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
  Future<TimerBellScheduleResult> scheduleCompletion({
    required DateTime endsAt,
    required String title,
    required String body,
  }) async {
    scheduleRequests.add(endsAt);
    if (_scheduleCompleters != null) {
      final completer = Completer<TimerBellScheduleResult>();
      _scheduleCompleters.add(completer);
      return completer.future;
    }
    return scheduleResult ?? TimerBellScheduleResult.exact;
  }

  @override
  Future<TimerBellScheduleResult> scheduleStart({
    required DateTime startsAt,
    required String title,
    required String body,
  }) async {
    startRequests.add(startsAt);
    return scheduleResult ?? TimerBellScheduleResult.exact;
  }

  @override
  Future<void> cancelStart() async {
    cancelStartCount++;
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

class _FakeTimerKeepAlive implements TimerKeepAlive {
  int startCount = 0;
  int stopCount = 0;
  int disposeCount = 0;
  bool get isHolding => startCount > stopCount;

  @override
  Future<void> start() async {
    startCount++;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
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
