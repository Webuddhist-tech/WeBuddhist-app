/// A Firestore document read as a signal: fields are server timestamps that
/// say when something changed, never what. Timestamps arrive as [DateTime].
class SignalSnapshot {
  const SignalSnapshot({required this.exists, this.fields = const {}});

  final bool exists;
  final Map<String, Object?> fields;

  Object? operator [](String field) => fields[field];
}

/// One watched field that moved between two snapshots of the same document.
class SignalChange {
  const SignalChange({
    required this.path,
    required this.field,
    required this.previous,
    required this.current,
  });

  final String path;
  final String field;
  final Object? previous;
  final Object? current;

  @override
  String toString() => 'SignalChange($path.$field: $previous -> $current)';
}

/// Firestore refused the read: not a member of the room, or a group whose
/// access flag has not been written yet.
class SignalPermissionDenied implements Exception {
  const SignalPermissionDenied(this.path);

  final String path;

  @override
  String toString() => 'SignalPermissionDenied($path)';
}

class SignalFailure implements Exception {
  const SignalFailure(this.path, this.code, [this.message]);

  final String path;
  final String code;
  final String? message;

  @override
  String toString() =>
      'SignalFailure($path, $code${message == null ? '' : ': $message'})';
}

/// Live document reads, with Firestore kept behind this seam so the rest of
/// the app, and every test, never imports it.
abstract class RealtimeSignals {
  Stream<SignalSnapshot> watchDoc(String path);
}
