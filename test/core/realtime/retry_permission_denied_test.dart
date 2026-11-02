import 'dart:async';

import 'package:flutter_pecha/core/realtime/realtime_signals.dart';
import 'package:flutter_pecha/core/realtime/retry_permission_denied.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tick = Duration(milliseconds: 10);

  test('reopens after a refusal and delivers once allowed', () async {
    var opens = 0;
    final stream = retryPermissionDenied<int>(
      () {
        opens++;
        if (opens < 3) return Stream.error(const SignalPermissionDenied('p'));
        return Stream.value(42);
      },
      attempts: 5,
      delay: tick,
    );

    expect(await stream.first, 42);
    expect(opens, 3);
  });

  test('gives up after the allowed attempts', () async {
    var opens = 0;
    final stream = retryPermissionDenied<int>(
      () {
        opens++;
        return Stream.error(const SignalPermissionDenied('p'));
      },
      attempts: 2,
      delay: tick,
    );

    await expectLater(stream, emitsError(isA<SignalPermissionDenied>()));
    expect(opens, 3);
  });

  test('other errors are not retried', () async {
    var opens = 0;
    final stream = retryPermissionDenied<int>(
      () {
        opens++;
        return Stream.error(const SignalFailure('p', 'unavailable'));
      },
      attempts: 5,
      delay: tick,
    );

    await expectLater(stream, emitsError(isA<SignalFailure>()));
    expect(opens, 1);
  });

  test('cancelling stops a pending retry', () async {
    var opens = 0;
    final sub = retryPermissionDenied<int>(
      () {
        opens++;
        return Stream.error(const SignalPermissionDenied('p'));
      },
      attempts: 5,
      delay: const Duration(milliseconds: 30),
    ).listen((_) {});
    await pumpEventQueue();
    await sub.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(opens, 1);
  });

  test('zero attempts surfaces the first refusal', () async {
    final stream = retryPermissionDenied<int>(
      () => Stream.error(const SignalPermissionDenied('p')),
      attempts: 0,
      delay: tick,
    );
    await expectLater(stream, emitsError(isA<SignalPermissionDenied>()));
  });
}
