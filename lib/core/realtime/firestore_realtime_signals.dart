import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_pecha/core/realtime/realtime_signals.dart';

/// The only file that imports cloud_firestore.
class FirestoreRealtimeSignals implements RealtimeSignals {
  FirestoreRealtimeSignals(this._firestore) {
    _configure(_firestore);
  }

  final FirebaseFirestore _firestore;
  static final _configured = <FirebaseFirestore>{};

  /// Signals are not worth disk: with persistence on, every reopen first
  /// replays a stale cached copy, which the field diff would take as a change.
  static void _configure(FirebaseFirestore firestore) {
    if (!_configured.add(firestore)) return;
    firestore.settings = const Settings(persistenceEnabled: false);
  }

  @override
  Stream<SignalSnapshot> watchDoc(String path) {
    return _firestore.doc(path).snapshots().map(_toSnapshot).handleError((
      Object error,
      StackTrace stack,
    ) {
      throw _mapError(path, error);
    });
  }

  static SignalSnapshot _toSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SignalSnapshot(
      exists: doc.exists,
      fields: {
        for (final entry in data.entries)
          entry.key:
              entry.value is Timestamp
                  ? (entry.value as Timestamp).toDate()
                  : entry.value,
      },
    );
  }

  static Object _mapError(String path, Object error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return SignalPermissionDenied(path);
      }
      return SignalFailure(path, error.code, error.message);
    }
    return SignalFailure(path, 'unknown', error.toString());
  }
}
