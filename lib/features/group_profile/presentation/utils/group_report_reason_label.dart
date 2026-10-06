import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

/// What to show for the `reason` a report carries.
///
/// A chat report for harassment, hateful speech, sexual content, or spam is
/// sent with no description, so the reason is all an admin has to go on.
/// The wire values are `ChatMessageReportReason`; an unknown one is spelled
/// out as it stands rather than hidden.
String groupReportReasonLabel(AppLocalizations l10n, String reason) {
  final normalized = reason.trim().toUpperCase();
  switch (normalized) {
    case 'HARASSMENT':
      return l10n.group_chat_report_reason_harassment;
    case 'HATE_SPEECH':
      return l10n.group_chat_report_reason_hate;
    case 'INAPPROPRIATE':
      return l10n.group_chat_report_reason_sexual;
    case 'SPAM':
      return l10n.group_chat_report_reason_spam;
    case 'OTHER':
      return l10n.group_chat_report_reason_other;
    default:
      return _humanized(normalized);
  }
}

/// `INAPPROPRIATE_LANGUAGE` as `Inappropriate language`.
String _humanized(String value) {
  final words = value.split('_').where((word) => word.isNotEmpty).toList();
  if (words.isEmpty) return '';
  final sentence = words.join(' ').toLowerCase();
  return sentence[0].toUpperCase() + sentence.substring(1);
}
