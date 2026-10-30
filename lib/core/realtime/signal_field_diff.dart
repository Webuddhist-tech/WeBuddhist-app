import 'dart:async';

import 'package:flutter_pecha/core/realtime/realtime_signals.dart';

/// Turns a stream of snapshots into the watched fields that moved. The first
/// snapshot is the current state, not a change, so it only sets the baseline.
class SignalFieldDiff {
  SignalFieldDiff(this.fields);

  final Set<String> fields;
  Map<String, Object?>? _baseline;

  bool get hasBaseline => _baseline != null;

  List<SignalChange> update(String path, SignalSnapshot snapshot) {
    final current = {for (final f in fields) f: snapshot[f]};
    final previous = _baseline;
    _baseline = current;
    if (previous == null) return const [];
    return [
      for (final f in fields)
        if (previous[f] != current[f])
          SignalChange(
            path: path,
            field: f,
            previous: previous[f],
            current: current[f],
          ),
    ];
  }
}

/// Watches [path] and emits one [SignalChange] per watched field that moved.
/// Errors pass through untouched.
Stream<SignalChange> watchFieldChanges(
  RealtimeSignals signals,
  String path,
  Set<String> fields,
) {
  final diff = SignalFieldDiff(fields);
  return signals
      .watchDoc(path)
      .expand((snapshot) => diff.update(path, snapshot));
}
