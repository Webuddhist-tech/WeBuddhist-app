import 'package:flutter_pecha/core/realtime/realtime_signals.dart';
import 'package:flutter_pecha/core/realtime/signal_field_diff.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_realtime_signals.dart';

void main() {
  final t1 = DateTime.utc(2026, 1, 1);
  final t2 = DateTime.utc(2026, 1, 2);

  group('SignalFieldDiff', () {
    test('the first snapshot only sets the baseline', () {
      final diff = SignalFieldDiff({'a'});
      expect(diff.hasBaseline, isFalse);
      expect(
        diff.update('p', SignalSnapshot(exists: true, fields: {'a': t1})),
        isEmpty,
      );
      expect(diff.hasBaseline, isTrue);
    });

    test('a moved field is reported with both values', () {
      final diff = SignalFieldDiff({'a', 'b'});
      diff.update(
        'p',
        SignalSnapshot(exists: true, fields: {'a': t1, 'b': t1}),
      );
      final changes = diff.update(
        'p',
        SignalSnapshot(exists: true, fields: {'a': t2, 'b': t1}),
      );
      expect(changes, hasLength(1));
      expect(changes.single.field, 'a');
      expect(changes.single.previous, t1);
      expect(changes.single.current, t2);
      expect(changes.single.path, 'p');
    });

    test('an unchanged snapshot reports nothing', () {
      final diff = SignalFieldDiff({'a'});
      diff.update('p', SignalSnapshot(exists: true, fields: {'a': t1}));
      expect(
        diff.update('p', SignalSnapshot(exists: true, fields: {'a': t1})),
        isEmpty,
      );
    });

    test('a field appearing on a document that did not exist counts', () {
      final diff = SignalFieldDiff({'a'});
      diff.update('p', const SignalSnapshot(exists: false));
      final changes = diff.update(
        'p',
        SignalSnapshot(exists: true, fields: {'a': t1}),
      );
      expect(changes.single.previous, isNull);
      expect(changes.single.current, t1);
    });

    test('unwatched fields are ignored', () {
      final diff = SignalFieldDiff({'a'});
      diff.update(
        'p',
        SignalSnapshot(exists: true, fields: {'a': t1, 'z': t1}),
      );
      expect(
        diff.update(
          'p',
          SignalSnapshot(exists: true, fields: {'a': t1, 'z': t2}),
        ),
        isEmpty,
      );
    });
  });

  group('watchFieldChanges', () {
    test(
      'emits one change per moved field and passes errors through',
      () async {
        final signals = FakeRealtimeSignals();
        final seen = <String>[];
        final errors = <Object>[];
        final sub = watchFieldChanges(signals, 'p', {
          'a',
          'b',
        }).listen((c) => seen.add(c.field), onError: errors.add);
        await pumpEventQueue();

        signals.emit('p', {'a': t1, 'b': t1});
        signals.emit('p', {'a': t2, 'b': t2});
        signals.fail('p', const SignalFailure('p', 'unavailable'));
        await pumpEventQueue();

        expect(seen, ['a', 'b']);
        expect(errors, hasLength(1));
        await sub.cancel();
      },
    );
  });
}
