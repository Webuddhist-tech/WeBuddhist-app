import 'package:url_launcher/url_launcher.dart';

/// Opens web links in the in-app browser sheet; other schemes go to their app.
Future<bool> openUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) return false;
  final isWeb = uri.scheme == 'http' || uri.scheme == 'https';
  try {
    if (isWeb &&
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
      return true;
    }
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
