import 'package:flutter_pecha/core/deep_linking/app_links_deep_link_service.dart';
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

/// Like [openUrl], but a first-party `webuddhist.com/open/...` link is routed
/// to its screen inside the app instead of the browser sheet. Anything the
/// deep link router does not recognise falls through to [openUrl].
Future<bool> openLink(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri != null && AppLinksDeepLinkService.instance.openInApp(uri)) {
    return true;
  }
  return openUrl(url);
}
