import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/error/crash_reporting/error_classifier.dart';

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
/// Registering a listener keeps Flutter from treating the failure as
/// unhandled. The failure is still passed to `FlutterError.reportError`,
/// tagged as an image-stream error and marked silent, so the crash reporter
/// records it as a rate-limited non-fatal instead of dropping it. Failed
/// downloads and expired image URLs therefore stay visible in Crashlytics.
void reportImageLoadError(Object error, StackTrace? stackTrace) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: ErrorClassifier.imageLibrary,
      context: ErrorDescription('while loading an image that has a fallback'),
      silent: true,
    ),
  );
}
