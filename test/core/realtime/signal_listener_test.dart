import 'package:flutter_pecha/core/realtime/realtime_providers.dart';
import 'package:flutter_pecha/core/realtime/realtime_signals.dart';
import 'package:flutter_pecha/core/realtime/signal_listener.dart';
import 'package:flutter_pecha/core/realtime/signal_set.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_realtime_signals.dart';

void main() {
  final t1 = DateTime.utc(2026, 1, 1);
  final t2 = DateTime.utc(2026, 1, 2);
  final t3 = DateTime.utc(2026, 1, 3);

  ProviderContainer build(FakeRealtimeSignals signals, {bool signedIn = true}) {
    final container = ProviderContainer(
      overrides: [
        realtimeSignalsProvider.overrideWithValue(signals),
        firebaseSignedInProvider.overrideWith((ref) => signedIn),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('listenSignal', () {
    test('does nothing until Firebase is signed in', () async {
      final signals = FakeRealtimeSignals();
      final container = build(signals, signedIn: false);
      final provider = Provider.autoDispose<void>((ref) {
        listenSignal(ref, path: 'p', fields: {'a'}, onChange: (_) {});
      });
      container.listen(provider, (_, _) {});
      await pumpEventQueue();

      expect(signals.listeners('p'), 0);

      container.read(firebaseSignedInProvider.notifier).state = true;
      await pumpEventQueue();
      expect(signals.listeners('p'), 1);
    });

    test('runs the callback on each moved field', () async {
      final signals = FakeRealtimeSignals();
      final container = build(signals);
      final seen = <SignalChange>[];
      final provider = Provider.autoDispose<void>((ref) {
        listenSignal(ref, path: 'p', fields: {'a', 'b'}, onChange: seen.add);
      });
      container.listen(provider, (_, _) {});
      await pumpEventQueue();

      signals.emit('p', {'a': t1, 'b': t1});
      signals.emit('p', {'a': t2, 'b': t1});
      signals.emit('p', {'a': t2, 'b': t2});
      await pumpEventQueue();

      expect(seen.map((c) => c.field), ['a', 'b']);
    });

    test('coalesces a burst into one call per field', () async {
      final signals = FakeRealtimeSignals();
      final container = build(signals);
      final seen = <SignalChange>[];
      final provider = Provider.autoDispose<void>((ref) {
        listenSignal(
          ref,
          path: 'p',
          fields: {'a'},
          coalesce: const Duration(milliseconds: 20),
          onChange: seen.add,
        );
      });
      container.listen(provider, (_, _) {});
      await pumpEventQueue();

      signals.emit('p', {'a': t1});
      signals.emit('p', {'a': t2});
      signals.emit('p', {'a': t3});
      await pumpEventQueue();
      expect(seen, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(seen, hasLength(1));
      expect(seen.single.current, t3);
    });

    test('a refusal with no retries is silent and stops', () async {
      final signals = FakeRealtimeSignals()..permissionDeniedUntil('p', 1);
      final container = build(signals);
      var calls = 0;
      final provider = Provider.autoDispose<void>((ref) {
        listenSignal(ref, path: 'p', fields: {'a'}, onChange: (_) => calls++);
      });
      container.listen(provider, (_, _) {});
      await pumpEventQueue();

      expect(signals.listeners('p'), 0);
      expect(calls, 0);
    });

    test('the listener is cancelled with its provider', () async {
      final signals = FakeRealtimeSignals();
      final container = build(signals);
      final provider = Provider.autoDispose<void>((ref) {
        listenSignal(ref, path: 'p', fields: {'a'}, onChange: (_) {});
      });
      final sub = container.listen(provider, (_, _) {});
      await pumpEventQueue();
      expect(signals.listeners('p'), 1);

      sub.close();
      await pumpEventQueue();
      expect(signals.listeners('p'), 0);
    });
  });

  group('SignalSet', () {
    test('follows the set of paths and drops refused ones', () async {
      final signals = FakeRealtimeSignals()..permissionDeniedUntil('c', 1);
      final seen = <String>[];
      final set = SignalSet(
        signals: signals,
        fields: {'a'},
        onChange: (c) => seen.add(c.path),
      );
      set.sync(['x', 'y', 'c']);
      await pumpEventQueue();
      expect(signals.listeners('x'), 1);
      expect(signals.listeners('y'), 1);
      expect(signals.listeners('c'), 0);
      expect(set.size, 2);

      set.sync(['y', 'z']);
      await pumpEventQueue();
      expect(signals.listeners('x'), 0);
      expect(signals.listeners('z'), 1);

      signals.emit('z', {'a': t1});
      signals.emit('z', {'a': t2});
      await pumpEventQueue();
      expect(seen, ['z']);

      set.dispose();
      await pumpEventQueue();
      expect(signals.totalListeners, 0);
    });

    test('caps the number of documents', () {
      final set = SignalSet(
        signals: FakeRealtimeSignals(),
        fields: {'a'},
        onChange: (_) {},
        maxDocuments: 2,
      );
      set.sync(['a', 'b', 'c']);
      expect(set.size, 2);
      set.dispose();
    });
  });
}
