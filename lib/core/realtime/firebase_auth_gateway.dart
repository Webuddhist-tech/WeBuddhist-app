import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Auth behind a seam; the only file that imports firebase_auth.
abstract class FirebaseAuthGateway {
  String? get currentUid;

  Stream<String?> authStateChanges();

  Future<String> signInWithCustomToken(String token);

  Future<void> signOut();
}

class FirebaseAuthGatewayImpl implements FirebaseAuthGateway {
  FirebaseAuthGatewayImpl(this._auth);

  final FirebaseAuth _auth;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Stream<String?> authStateChanges() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<String> signInWithCustomToken(String token) async {
    final credential = await _auth.signInWithCustomToken(token);
    return credential.user?.uid ?? '';
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
