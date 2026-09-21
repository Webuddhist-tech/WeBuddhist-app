import 'dart:async';

import 'package:flutter_pecha/features/timer/presentation/services/timer_keep_alive.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the keep-alive asks of the platform, and lets a test hold any
/// one of those calls open to interleave the next one behind it — which is what
/// the timer screen does by firing start() and stop() without awaiting them.
class _RecordingKeepAlive extends TimerAudioKeepAlive {
  final List<String> calls = [];
  final Map<String, Completer<void>> _gates = {};

  @override
  bool get isSupported => true;

  /// Makes the next [name] call block until [release] is called for it.
  void gate(String name) => _gates[name] = Completer<void>();

  void release(String name) {
    final gate = _gates.remove(name);
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  Future<void> _record(String name) async {
    calls.add(name);
    final gate = _gates[name];
    if (gate != null) await gate.future;
  }

  @override
  Future<void> activateSession() => _record('activate');

  @override
  Future<void> restoreSession() => _record('restore');

  @override
  Future<void> startSilentLoop() => _record('play');

  @override
  Future<void> stopSilentLoop() => _record('stop');
}

void main() {
  test('holds the session for a session that wants it', () async {
    final keepAlive = _RecordingKeepAlive();

    await keepAlive.start();

    expect(keepAlive.calls, ['activate', 'play']);
  });

  test('a repeated start does not restart the silent track', () async {
    final keepAlive = _RecordingKeepAlive();

    await keepAlive.start();
    await keepAlive.start();

    expect(keepAlive.calls, ['activate', 'play']);
  });

  test('releases the session on stop', () async {
    final keepAlive = _RecordingKeepAlive();

    await keepAlive.start();
    await keepAlive.stop();

    expect(keepAlive.calls, ['activate', 'play', 'stop', 'restore']);
  });

  test('resuming during an in-flight stop leaves the session held', () async {
    final keepAlive = _RecordingKeepAlive();
    await keepAlive.start();
    keepAlive.calls.clear();

    // Pause: the release blocks partway through, as a platform call would.
    keepAlive.gate('stop');
    unawaited(keepAlive.stop());
    await pumpEventQueue();
    expect(keepAlive.calls, ['stop']);

    // Resume before that release finishes — neither call is awaited by the
    // timer screen, so the hold queues up behind the release.
    unawaited(keepAlive.start());
    keepAlive.release('stop');
    await pumpEventQueue();

    // The release must not have restored the app's configuration on top of the
    // hold that replaced it, and the session must be playing again.
    expect(keepAlive.calls, ['stop', 'activate', 'play']);
    expect(keepAlive.calls, isNot(contains('restore')));
  });

  test(
    'pausing during an in-flight start still releases the session',
    () async {
      final keepAlive = _RecordingKeepAlive();

      keepAlive.gate('activate');
      unawaited(keepAlive.start());
      await pumpEventQueue();
      expect(keepAlive.calls, ['activate']);

      unawaited(keepAlive.stop());
      keepAlive.release('activate');
      await pumpEventQueue();

      // The hold bails out once it sees the stop, and the release still runs.
      expect(keepAlive.calls, ['activate', 'stop', 'restore']);
      expect(keepAlive.calls, isNot(contains('play')));
    },
  );

  test('dispose releases a held session', () async {
    final keepAlive = _RecordingKeepAlive();
    await keepAlive.start();

    await keepAlive.dispose();

    expect(keepAlive.calls, ['activate', 'play', 'stop', 'restore']);
  });

  test('start after dispose does nothing', () async {
    final keepAlive = _RecordingKeepAlive();
    await keepAlive.dispose();
    keepAlive.calls.clear();

    await keepAlive.start();

    expect(keepAlive.calls, isEmpty);
  });
}
