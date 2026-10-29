import 'dart:async';

import 'package:flutter_pecha/core/realtime/realtime_signals.dart';
import 'package:flutter_pecha/core/realtime/signal_field_diff.dart';

/// Listens to a changing set of documents for the same fields. A document
/// that refuses the read is dropped quietly: there is nothing to hear there.
class SignalSet {
  SignalSet({
    required RealtimeSignals signals,
    required Set<String> fields,
    required void Function(SignalChange change) onChange,
    this.maxDocuments = 100,
  }) : _signals = signals,
       _fields = fields,
       _onChange = onChange;

  final RealtimeSignals _signals;
  final Set<String> _fields;
  final void Function(SignalChange change) _onChange;
  final int maxDocuments;
  final _subscriptions = <String, StreamSubscription<SignalChange>>{};

  int get size => _subscriptions.length;

  /// Follows [paths]: new ones are listened to, missing ones dropped.
  void sync(Iterable<String> paths) {
    final wanted = paths.take(maxDocuments).toSet();
    for (final path in _subscriptions.keys.toList()) {
      if (!wanted.contains(path)) _subscriptions.remove(path)?.cancel();
    }
    for (final path in wanted) {
      if (_subscriptions.containsKey(path)) continue;
      _subscriptions[path] = watchFieldChanges(_signals, path, _fields).listen(
        _onChange,
        onError: (Object _) => _subscriptions.remove(path)?.cancel(),
      );
    }
  }

  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}
