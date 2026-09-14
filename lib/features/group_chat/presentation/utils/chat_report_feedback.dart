import 'package:flutter_pecha/core/error/failures.dart';

/// What to tell the member once a report request has settled.
enum ChatReportFeedback {
  /// On file. A message this member had already reported counts too: the
  /// data layer folds the server's 409 into success.
  sent,

  /// The request never left, and a live probe agrees the device is offline.
  offline,

  /// A failure a second attempt may well get past.
  failed,

  /// The server refused the report and would refuse it again — it is the
  /// member's own message, the message is gone, or they are not a member of
  /// the room. Offering Retry here would offer something that cannot work.
  rejected,
}

/// Picks the snackbar for a settled report.
///
/// `NetworkFailure` is too broad to mean "offline" on its own: the error
/// interceptor also raises it for timeouts, cancelled requests, bad
/// certificates and anything Dio files as unknown, all of which happen with a
/// working connection. Only call the failure offline when a live probe
/// agrees; otherwise keep the Retry action, since a second attempt may well
/// go through.
///
/// [isOnline] must be a fresh check, not a cached flag. The request itself
/// never refreshes connectivity state, so a flag that went stale while the
/// app was backgrounded would file every network failure as offline and hide
/// Retry. The probe is only run when a `NetworkFailure` makes it relevant.
///
/// A probe that throws (a missing platform plugin, a lookup that blows up)
/// counts as online: the failure keeps the Retry path instead of being
/// mislabeled, and the caller never has to guard the probe itself.
///
/// Refusals are told apart from failures by type. A 400, 403 or 404 is the
/// server's answer to this exact request, and sending it again gets the same
/// answer; a 5xx, a rate limit or an unknown error is the server's state at
/// that moment, and may have changed by the time Retry is tapped.
Future<ChatReportFeedback> chatReportFeedbackFor(
  Failure? failure, {
  required Future<bool> Function() isOnline,
}) async {
  if (failure == null) return ChatReportFeedback.sent;
  if (failure is NetworkFailure) {
    return await _probe(isOnline)
        ? ChatReportFeedback.failed
        : ChatReportFeedback.offline;
  }
  if (failure is ValidationFailure ||
      failure is NotFoundFailure ||
      failure is AuthorizationFailure ||
      failure is AuthenticationFailure) {
    return ChatReportFeedback.rejected;
  }
  return ChatReportFeedback.failed;
}

Future<bool> _probe(Future<bool> Function() isOnline) async {
  try {
    return await isOnline();
  } catch (_) {
    return true;
  }
}
