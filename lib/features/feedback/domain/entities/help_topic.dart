/// What a Help & contact message is about. The user picks at most one.
enum HelpTopic {
  reportProblem('report_problem', 'Report a problem'),
  ideaFeedback('idea_feedback', 'Idea or feedback'),
  suggestContent('suggest_content', 'Suggest content'),
  helpCollaborate('help_collaborate', 'Help or collaborate');

  const HelpTopic(this.slug, this.canonicalLabel);

  /// Sent to `POST /feedback` as `topic`.
  final String slug;

  /// The English label the backend writes into the context line of the
  /// WeBuddhist Team chat. Only matched against, never shown: the app shows
  /// its own translation.
  final String canonicalLabel;

  static HelpTopic? fromCanonicalLabel(String label) {
    final wanted = label.trim().toLowerCase();
    for (final topic in values) {
      if (topic.canonicalLabel.toLowerCase() == wanted) return topic;
    }
    return null;
  }
}
