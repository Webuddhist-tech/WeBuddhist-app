import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_pecha/core/config/app_feature_flags.dart';
import 'package:flutter_pecha/core/realtime/firebase_auth_gateway.dart';
import 'package:flutter_pecha/core/realtime/firestore_realtime_signals.dart';
import 'package:flutter_pecha/core/realtime/realtime_signals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Named Firestore database the backend writes signals to (not `(default)`).
const _signalsDatabaseId = 'app-backend';

/// Null when Firebase did not start or signals are switched off.
final realtimeSignalsProvider = Provider<RealtimeSignals?>((ref) {
  if (!AppFeatureFlags.kRealtimeSignals || Firebase.apps.isEmpty) return null;
  return FirestoreRealtimeSignals(
    FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: _signalsDatabaseId,
    ),
  );
});

final firebaseAuthGatewayProvider = Provider<FirebaseAuthGateway?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  return FirebaseAuthGatewayImpl(FirebaseAuth.instance);
});

/// True while Firebase Auth holds the backend user's session. Driven by the
/// Firebase session notifier; tests override it directly.
final firebaseSignedInProvider = StateProvider<bool>((ref) => false);

/// Signals only while signed in: Firestore refuses every read before that.
final liveSignalsProvider = Provider<RealtimeSignals?>((ref) {
  if (!ref.watch(firebaseSignedInProvider)) return null;
  return ref.watch(realtimeSignalsProvider);
});
