import 'dart:async';

import 'package:flutter_pecha/core/realtime/realtime_signals.dart';

/// Reopens [open] after a [SignalPermissionDenied], up to [attempts] times,
/// [delay] apart. A chat room's reader document is written after the join
/// commits, so a listener started straight after opening the room can be
/// refused for a moment. Other errors, and the last refusal, reach the
/// subscriber. Cancelling stops any pending retry.
Stream<T> retryPermissionDenied<T>(
  Stream<T> Function() open, {
  int attempts = 5,
  Duration delay = const Duration(seconds: 2),
}) {
  late StreamController<T> controller;
  StreamSubscription<T>? sub;
  Timer? timer;
  var remaining = attempts;

  void connect() {
    sub = open().listen(
      controller.add,
      onError: (Object error, StackTrace stack) {
        if (error is SignalPermissionDenied && remaining > 0) {
          remaining--;
          sub?.cancel();
          sub = null;
          timer = Timer(delay, connect);
          return;
        }
        controller.addError(error, stack);
      },
      onDone: controller.close,
    );
  }

  controller = StreamController<T>(
    onListen: connect,
    onCancel: () async {
      timer?.cancel();
      await sub?.cancel();
    },
  );
  return controller.stream;
}
