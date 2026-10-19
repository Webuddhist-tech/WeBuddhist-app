import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/help_topic.dart';
import 'package:flutter_pecha/features/feedback/domain/help_context_line.dart';

String helpTopicLabel(AppLocalizations l10n, HelpTopic topic) {
  return switch (topic) {
    HelpTopic.reportProblem => l10n.help_topic_report_problem,
    HelpTopic.ideaFeedback => l10n.help_topic_idea_feedback,
    HelpTopic.suggestContent => l10n.help_topic_suggest_content,
    HelpTopic.helpCollaborate => l10n.help_topic_help_collaborate,
  };
}

/// The message field's placeholder, which asks the question that fits the
/// picked topic.
String helpTopicHint(AppLocalizations l10n, HelpTopic? topic) {
  return switch (topic) {
    null => l10n.help_contact_hint_default,
    HelpTopic.reportProblem => l10n.help_contact_hint_report_problem,
    HelpTopic.ideaFeedback => l10n.help_contact_hint_idea_feedback,
    HelpTopic.suggestContent => l10n.help_contact_hint_suggest_content,
    HelpTopic.helpCollaborate => l10n.help_contact_hint_help_collaborate,
  };
}

/// "Sent from Help & contact · Help or collaborate · 2 photos", in the
/// viewer's language. Digits are left as ASCII for the caller to convert.
String helpContextLabel(AppLocalizations l10n, HelpContext context) {
  final topic = context.topic;
  return [
    l10n.help_context_sent_from,
    if (topic != null) helpTopicLabel(l10n, topic),
    if (context.photoCount > 0) l10n.help_context_photos(context.photoCount),
  ].join(' · ');
}
