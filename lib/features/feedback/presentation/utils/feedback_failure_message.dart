import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/feedback/presentation/providers/feedback_providers.dart';

/// The inline error Help & contact shows for a send that failed.
String feedbackFailureMessage(AppLocalizations l10n, FeedbackFailure failure) {
  return switch (failure) {
    FeedbackFailure.offline => l10n.feedback_error_offline,
    FeedbackFailure.rateLimited => l10n.feedback_error_rate_limited,
    FeedbackFailure.tooLarge => l10n.feedback_error_too_large,
    FeedbackFailure.unavailable => l10n.feedback_error_unavailable,
    FeedbackFailure.failed => l10n.feedback_error_failed,
  };
}
