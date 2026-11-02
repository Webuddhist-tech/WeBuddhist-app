import 'dart:async';

import 'package:flutter_pecha/core/realtime/realtime_signals.dart';

/// In-memory stand-in for Firestore signal documents.
class FakeRealtimeSignals implements RealtimeSignals {
  final _controllers = <String, StreamController<SignalSnapshot>>{};
  final _listenerCounts = <String, int>{};
  final _denyRemaining = <String, int>{};

  /// Every subscription to [path] after this one, and the next [n] in total,
  /// fail with [SignalPermissionDenied].
  void permissionDeniedUntil(String path, int n) => _denyRemaining[path] = n;

  int listeners(String path) => _listenerCounts[path] ?? 0;

  int get totalListeners => _listenerCounts.values.fold(0, (sum, n) => sum + n);

  void emit(String path, Map<String, Object?> fields, {bool exists = true}) {
    _controllers[path]?.add(SignalSnapshot(exists: exists, fields: fields));
  }

  void fail(String path, Object error) {
    _controllers[path]?.addError(error);
  }

  @override
  Stream<SignalSnapshot> watchDoc(String path) {
    final remaining = _denyRemaining[path] ?? 0;
    if (remaining > 0) {
      _denyRemaining[path] = remaining - 1;
      return Stream.error(SignalPermissionDenied(path));
    }
    final controller = _controllers.putIfAbsent(
      path,
      () => StreamController<SignalSnapshot>.broadcast(),
    );
    late StreamSubscription<SignalSnapshot> sub;
    late StreamController<SignalSnapshot> out;
    out = StreamController<SignalSnapshot>(
      onListen: () {
        _listenerCounts[path] = listeners(path) + 1;
        sub = controller.stream.listen(out.add, onError: out.addError);
      },
      onCancel: () async {
        _listenerCounts[path] = listeners(path) - 1;
        await sub.cancel();
      },
    );
    return out.stream;
  }

  Future<void> close() async {
    for (final c in _controllers.values) {
      await c.close();
    }
  }
}
