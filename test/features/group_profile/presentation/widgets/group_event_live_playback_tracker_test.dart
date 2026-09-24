import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_analytics.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_live_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

/// Advances only while running, so the tracker's start/stop calls decide.
class _FakeStopwatch implements Stopwatch {
  @override
  Duration elapsed = Duration.zero;

  @override
  bool isRunning = false;

  void advance(Duration by) {
    if (isRunning) elapsed += by;
  }

  @override
  void start() => isRunning = true;

  @override
  void stop() => isRunning = false;

  @override
  void reset() => elapsed = Duration.zero;

  @override
  int get elapsedMicroseconds => elapsed.inMicroseconds;

  @override
  int get elapsedMilliseconds => elapsed.inMilliseconds;

  @override
  int get elapsedTicks => elapsed.inMicroseconds;

  @override
  int get frequency => Duration.microsecondsPerSecond;
}

void main() {
  late RecordingAnalyticsService service;
  late _FakeStopwatch clock;
  late GroupEventLivePlaybackTracker tracker;

  setUp(() {
    service = RecordingAnalyticsService();
    clock = _FakeStopwatch();
    tracker = GroupEventLivePlaybackTracker(
      analytics: GroupEventAnalytics(service),
      eventId: 'e1',
      groupId: 'g1',
      clock: clock,
    );
  });

  test('opened fires once, on the first play', () {
    tracker.onPlayerState(PlayerState.buffering);
    expect(service.events, isEmpty);

    tracker.onPlayerState(PlayerState.playing);
    tracker.onPlayerState(PlayerState.paused);
    tracker.onPlayerState(PlayerState.playing);

    expect(service.eventNames, [AnalyticsEvents.groupEventLiveOpened]);
    expect(service.events.single.properties, {
      'event_id': 'e1',
      'group_id': 'g1',
    });
  });

  test('ended on dispose reports only the whole seconds spent playing', () {
    tracker.onPlayerState(PlayerState.playing);
    clock.advance(const Duration(seconds: 5));
    tracker.onPlayerState(PlayerState.buffering);
    clock.advance(const Duration(seconds: 10));
    tracker.onPlayerState(PlayerState.playing);
    clock.advance(const Duration(milliseconds: 3500));
    tracker.end();
    tracker.end();

    expect(service.eventNames, [
      AnalyticsEvents.groupEventLiveOpened,
      AnalyticsEvents.groupEventLiveEnded,
    ]);
    expect(service.events.last.properties, {
      'event_id': 'e1',
      'group_id': 'g1',
      'duration_s': 8,
    });
  });

  test('locked-screen listening keeps counting', () {
    tracker.onPlayerState(PlayerState.playing);
    clock.advance(const Duration(seconds: 2));
    clock.advance(const Duration(seconds: 30));
    tracker.onPlayerState(PlayerState.paused);
    clock.advance(const Duration(seconds: 5));
    tracker.end();

    expect(service.events.last.properties['duration_s'], 32);
  });

  test('the stream ending reports once; dispose adds nothing', () {
    tracker.onPlayerState(PlayerState.playing);
    clock.advance(const Duration(seconds: 4));
    tracker.onPlayerState(PlayerState.ended);
    clock.advance(const Duration(seconds: 4));
    tracker.end();

    expect(service.eventNames, [
      AnalyticsEvents.groupEventLiveOpened,
      AnalyticsEvents.groupEventLiveEnded,
    ]);
    expect(service.events.last.properties['duration_s'], 4);
  });

  test('playback after the stream ended is a new session', () {
    tracker.onPlayerState(PlayerState.playing);
    clock.advance(const Duration(seconds: 4));
    tracker.onPlayerState(PlayerState.ended);
    tracker.onPlayerState(PlayerState.playing);
    clock.advance(const Duration(seconds: 6));
    tracker.end();

    expect(service.eventNames, [
      AnalyticsEvents.groupEventLiveOpened,
      AnalyticsEvents.groupEventLiveEnded,
      AnalyticsEvents.groupEventLiveOpened,
      AnalyticsEvents.groupEventLiveEnded,
    ]);
    expect(service.events.last.properties['duration_s'], 6);
  });

  test('a player that never played reports nothing', () {
    tracker.onPlayerState(PlayerState.buffering);
    tracker.end();

    expect(service.events, isEmpty);
  });
}
