/// Central feature flags for the application.
class AppFeatureFlags {
  AppFeatureFlags._();

  /// When true, the app shows only the Coming Soon page.
  /// Set to false to restore normal app behavior.
  static const bool kComingSoonMode = false;

  /// Firestore signals drive live refreshes; off leaves REST + push only.
  static const bool kRealtimeSignals = true;
}
