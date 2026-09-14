import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Collection row was persisted, but adding items failed.
///
/// Callers should retry item addition with [collectionId] instead of creating
/// another collection.
class PartialCollectionCreateFailure extends Failure {
  final String collectionId;

  const PartialCollectionCreateFailure(
    super.message, {
    required this.collectionId,
  });

  @override
  List<Object> get props => [message, collectionId];
}

/// Some parts of a post edit were persisted before a later request failed.
class PartialPostUpdateFailure extends Failure {
  final bool captionSaved;
  final bool mediaSaved;
  final bool linksSaved;

  const PartialPostUpdateFailure(
    super.message, {
    required this.captionSaved,
    required this.mediaSaved,
    required this.linksSaved,
  });

  @override
  List<Object> get props => [message, captionSaved, mediaSaved, linksSaved];
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ValidationFailure extends Failure {
  final String? code;

  const ValidationFailure(super.message, {this.code});

  @override
  List<Object> get props => [message, code ?? ''];
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}

class AuthorizationFailure extends Failure {
  const AuthorizationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class PairingFailure extends Failure {
  const PairingFailure(super.message);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
