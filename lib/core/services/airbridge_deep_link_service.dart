import 'package:flutter_pecha/core/analytics/entry_analytics.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_router.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:go_router/go_router.dart';

class AirbridgeDeepLinkService {
  AirbridgeDeepLinkService._();

  static final _logger = AppLogger('AirbridgeDeepLinkService');
  static GoRouter? _router;
  static Uri? _pendingUri;
  static EntryAnalytics? _analytics;

  static void setRouter(GoRouter router) {
    _router = router;
    final pending = _pendingUri;
    if (pending == null) return;

    _pendingUri = null;
    _dispatch(pending);
  }

  static void setAnalytics(EntryAnalytics analytics) {
    _analytics = analytics;
  }

  static void storePendingDeepLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _logger.warning('Ignoring invalid Airbridge deep link: $url');
      return;
    }

    if (_router == null) {
      _pendingUri = uri;
      _logger.info('Router not ready, stored Airbridge deep link: $uri');
      return;
    }

    _dispatch(uri);
  }

  static void _dispatch(Uri uri) {
    final router = _router;
    if (router == null) return;

    if (!DeepLinkRouter.isAirbridgeLink(uri)) {
      _logger.debug('Ignoring non-Airbridge deep link callback: $uri');
      return;
    }

    DeepLinkRouter.route(
      uri,
      router,
      source: 'airbridge',
      analytics: _analytics,
    );
  }
}
