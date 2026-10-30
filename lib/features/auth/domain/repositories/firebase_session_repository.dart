import 'package:flutter_pecha/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

/// A custom token minted by the backend for its own user id.
class FirebaseCustomToken {
  const FirebaseCustomToken({required this.token, required this.uid});

  final String token;
  final String uid;
}

/// The backend has Firebase switched off (503): no live updates there.
class FirebaseDisabledFailure extends Failure {
  const FirebaseDisabledFailure(super.message);
}

abstract class FirebaseSessionRepository {
  Future<Either<Failure, FirebaseCustomToken>> fetchCustomToken();
}
