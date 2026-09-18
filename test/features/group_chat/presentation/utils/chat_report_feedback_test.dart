import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_report_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

/// A connectivity probe that records whether it was asked.
class _Probe {
  _Probe(this.online);

  final bool online;
  int calls = 0;

  Future<bool> call() async {
    calls++;
    return online;
  }
}

void main() {
  group('chatReportFeedbackFor', () {
    test('no failure means the report was sent without probing', () async {
      for (final online in const [true, false]) {
        final probe = _Probe(online);
        expect(
          await chatReportFeedbackFor(null, isOnline: probe.call),
          ChatReportFeedback.sent,
        );
        expect(probe.calls, 0);
      }
    });

    test('a network failure is only offline when a live probe says so',
        () async {
      final probe = _Probe(false);
      expect(
        await chatReportFeedbackFor(
          const NetworkFailure('reportMessage: No internet connection'),
          isOnline: probe.call,
        ),
        ChatReportFeedback.offline,
      );
      expect(probe.calls, 1);
    });

    test('a network failure while online keeps the retry path', () async {
      // The interceptor files timeouts, cancels, bad certificates and unknown
      // errors under NetworkFailure too; none of those mean the user is
      // offline.
      for (final message in const [
        'reportMessage: Connection timeout',
        'reportMessage: Request cancelled',
        'reportMessage: Invalid SSL certificate',
        'reportMessage: Unknown error: something',
      ]) {
        final probe = _Probe(true);
        expect(
          await chatReportFeedbackFor(
            NetworkFailure(message),
            isOnline: probe.call,
          ),
          ChatReportFeedback.failed,
          reason: message,
        );
        expect(probe.calls, 1, reason: message);
      }
    });

    test('a probe that throws keeps the retry path', () async {
      // The platform channel can be missing, and the lookup itself can blow
      // up; neither says anything about the report, so it must not be filed
      // as offline nor escape to the caller.
      Future<bool> throwingProbe() async => throw StateError('no plugin');
      expect(
        await chatReportFeedbackFor(
          const NetworkFailure('reportMessage: No internet connection'),
          isOnline: throwingProbe,
        ),
        ChatReportFeedback.failed,
      );
    });

    test('a failure the server may not repeat keeps the retry path without '
        'probing', () async {
      for (final failure in const <Failure>[
        ServerFailure('reportMessage: 500'),
        RateLimitFailure('reportMessage: 429'),
        UnknownFailure('reportMessage: boom'),
      ]) {
        for (final online in const [true, false]) {
          final probe = _Probe(online);
          expect(
            await chatReportFeedbackFor(failure, isOnline: probe.call),
            ChatReportFeedback.failed,
            reason: failure.toString(),
          );
          expect(probe.calls, 0);
        }
      }
    });

    test('a refusal the server would repeat is rejected, not retried',
        () async {
      // Own message, message gone, not a member, signed out: each is the
      // answer to this exact request, and sending it again gets the same one.
      for (final failure in const <Failure>[
        ValidationFailure('reportMessage: CANNOT_REPORT_OWN_MESSAGE'),
        NotFoundFailure('reportMessage: message not found'),
        AuthorizationFailure('reportMessage: Forbidden'),
        AuthenticationFailure('reportMessage: Unauthorized'),
      ]) {
        final probe = _Probe(false);
        expect(
          await chatReportFeedbackFor(failure, isOnline: probe.call),
          ChatReportFeedback.rejected,
          reason: failure.toString(),
        );
        expect(probe.calls, 0);
      }
    });
  });
}
