/// Who sent a piece of feedback. Absent for guests.
class FeedbackReporter {
  const FeedbackReporter({this.email});

  final String? email;
}

/// A single feedback submission plus the context needed to triage it.
class FeedbackReport {
  const FeedbackReport({
    required this.message,
    required this.imagePaths,
    required this.appVersion,
    required this.platform,
    this.reporter,
  });

  final String message;
  final List<String> imagePaths;
  final FeedbackReporter? reporter;

  /// e.g. `2.5.5 (120)`.
  final String appVersion;

  /// e.g. `ios Version 17.2 (Build 21C62)`.
  final String platform;
}
