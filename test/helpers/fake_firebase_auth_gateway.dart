import 'dart:async';

import 'package:flutter_pecha/core/realtime/firebase_auth_gateway.dart';

class FakeFirebaseAuthGateway implements FirebaseAuthGateway {
  String? uid;
  final signedInTokens = <String>[];
  int signOutCalls = 0;

  /// Thrown by the next sign-in, then cleared.
  Object? signInError;

  /// Uid the next sign-in reports; defaults to the token's `uid:` suffix.
  String? uidToReturn;

  final _changes = StreamController<String?>.broadcast();

  @override
  String? get currentUid => uid;

  @override
  Stream<String?> authStateChanges() => _changes.stream;

  /// Simulates the SDK dropping or restoring the user.
  void setUser(String? newUid) {
    uid = newUid;
    _changes.add(newUid);
  }

  @override
  Future<String> signInWithCustomToken(String token) async {
    signedInTokens.add(token);
    final error = signInError;
    signInError = null;
    if (error != null) throw error;
    uid = uidToReturn ?? token.replaceFirst('token-for-', '');
    _changes.add(uid);
    return uid!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    uid = null;
    _changes.add(null);
  }
}
