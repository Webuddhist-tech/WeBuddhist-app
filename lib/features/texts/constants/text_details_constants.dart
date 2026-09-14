/// Shared defaults for the `/texts/{id}/details` request.
class TextDetailsConstants {
  TextDetailsConstants._(); // Private constructor to prevent instantiation

  /// Segments returned per page when the caller doesn't ask for a specific
  /// window. Mirrors the API's own default. The reader's pagination and the
  /// plan-window threshold both key off this value, so keep it the single
  /// source of truth.
  static const int defaultPageSize = 20;
}
