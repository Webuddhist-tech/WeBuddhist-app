import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_analytics.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_report_feedback.dart';

/// One report, with everything needed to send it and to say how it went.
///
/// Self-contained on purpose: the Retry on its snackbar sends this same
/// object again, and by then the thread that built it may be gone.
class ChatReportRequest {
  const ChatReportRequest({
    required this.repository,
    required this.analytics,
    required this.isOnline,
    required this.messenger,
    required this.l10n,
    required this.roomId,
    required this.messageId,
    required this.reason,
    required this.description,
  });

  final GroupChatRepository repository;
  final GroupChatAnalytics analytics;

  /// A live reachability probe, run only when a failure makes it relevant.
  final Future<bool> Function() isOnline;
  final ScaffoldMessengerState messenger;
  final AppLocalizations l10n;
  final String roomId;
  final String messageId;
  final String reason;
  final String? description;

  Future<void> send() async {
    final result = await repository.reportMessage(
      roomId,
      messageId: messageId,
      reason: reason,
      description: description,
    );
    final failure = result.getLeft().toNullable();

    // "Offline" is more honest than "something went wrong" when the request
    // never left. The failure type alone cannot tell us that, and the cached
    // flag may be stale (it is only refreshed on connectivity events), so
    // probe live. The probe only runs when the failure makes it relevant.
    final feedback = await chatReportFeedbackFor(failure, isOnline: isOnline);

    switch (feedback) {
      case ChatReportFeedback.sent:
        // A repeat report folds into `sent` too (the data layer treats the
        // server's 409 as success), so a member re-reporting the same
        // message fires this again. That is the tap that happened.
        analytics.messageReported(
          roomId: roomId,
          messageId: messageId,
          reason: reason,
        );
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.group_chat_report_thanks)),
        );
      case ChatReportFeedback.rejected:
        // The server would answer the same way again, so no Retry.
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.group_chat_report_failed)),
        );
      case ChatReportFeedback.offline:
      case ChatReportFeedback.failed:
        // Retry is offered for both. The probe is a DNS lookup that can fail
        // on a network where the API is still reachable (a filtered resolver,
        // a slow one), so "offline" only changes the wording; it must never
        // cost the member the one action that gets the report through.
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              feedback == ChatReportFeedback.offline
                  ? l10n.group_chat_report_offline
                  : l10n.group_chat_report_failed,
            ),
            action: SnackBarAction(
              label: l10n.group_chat_report_retry,
              onPressed: send,
            ),
          ),
        );
    }
  }
}
