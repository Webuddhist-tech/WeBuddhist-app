import 'package:flutter_pecha/core/error/failures.dart';

/// The bulk delete route is not deployed on this backend.
///
/// Raised by the datasource on a `404` or `405` for the bulk call — the two
/// answers a server gives for a route it does not have — and mapped by the
/// repository to [ChatBulkDeleteUnsupportedFailure], so the thread can fall
/// back to deleting one message at a time rather than reporting a failure.
class ChatBulkDeleteUnsupportedException implements Exception {
  const ChatBulkDeleteUnsupportedException();

  @override
  String toString() => 'Bulk delete is not available on this server';
}

class ChatBulkDeleteUnsupportedFailure extends Failure {
  const ChatBulkDeleteUnsupportedFailure()
    : super('Bulk delete is not available on this server');
}
