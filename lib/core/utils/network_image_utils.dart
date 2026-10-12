/// Strips the query string and fragment so presigned URLs (e.g. S3 with
/// rotating signatures) resolve to the same logical asset.
String stableNetworkImageCacheKey(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  return uri.replace(query: '', fragment: '').toString();
}

bool isSameNetworkImage(String? a, String? b) {
  if (a == null || b == null) return a == b;
  return stableNetworkImageCacheKey(a) == stableNetworkImageCacheKey(b);
}

/// An image error listener for places where the UI already has a fallback,
/// such as a [CircleAvatar]'s background color or a precache whose widget
/// shows its own error state.
///
/// Registering any listener marks the failure as handled. With none, Flutter
/// reports it as an unhandled framework error.
void ignoreImageLoadError(Object error, StackTrace? stackTrace) {}
