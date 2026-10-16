/// A single feedback submission plus the context needed to triage it. The
/// sender is not part of it: the backend takes them from the auth token.
class FeedbackReport {
  const FeedbackReport({
    required this.message,
    required this.imagePaths,
    required this.appVersion,
    required this.platform,
  });

  final String message;
  final List<String> imagePaths;

  /// e.g. `2.5.5 (120)`.
  final String appVersion;

  /// e.g. `ios Version 17.2 (Build 21C62)`.
  final String platform;
}
