import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_pecha/core/analytics/entry_analytics.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_router.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:go_router/go_router.dart';

class AppLinksDeepLinkService {
  AppLinksDeepLinkService._();

  static final AppLinksDeepLinkService instance = AppLinksDeepLinkService._();

  final _appLinks = AppLinks();
  final _logger = AppLogger('AppLinksDeepLinkService');

  StreamSubscription<Uri>? _subscription;
  GoRouter? _router;
  EntryAnalytics? _analytics;
  Uri? _pendingUri;
  Uri? _lastDispatchedUri;
  DateTime? _lastDispatchedAt;
  bool _initialized = false;
  void Function(int tabIndex)? _tabSetter;
  void Function(String planId, int? dayNumber, String? planLanguage)?
      _planNavigator;

  static const Duration _duplicateDispatchWindow = Duration(seconds: 5);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _logger.info('Cold-start app link: $initial');
        _handleLink(initial);
      }

      _subscription = _appLinks.uriLinkStream.listen(
        (uri) {
          _logger.info('Warm-start app link: $uri');
          _handleLink(uri);
        },
        onError:
            (e, stackTrace) =>
                _logger.error('App link stream error', e, stackTrace),
      );

      _logger.info('App links service initialized');
    } catch (e, stackTrace) {
      _logger.error('App links init error', e, stackTrace);
    }
  }

  void setRouter(GoRouter router) {
    _router = router;
  }

  void setAnalytics(EntryAnalytics analytics) {
    _analytics = analytics;
  }

  void setTabSetter(void Function(int tabIndex) setter) {
    _tabSetter = setter;
  }

  void setPlanNavigator(
    void Function(String planId, int? dayNumber, String? planLanguage)
        navigator,
  ) {
    _planNavigator = navigator;
  }

  bool drainPendingLink() {
    final router = _router;
    if (router == null) return false;

    final pending = _pendingUri;
    if (pending == null) return false;

    _pendingUri = null;
    // Cold start: draining is scheduled the moment auth finishes loading, but
    // the auth-driven route guard redirect (/splash -> /home) resolves
    // asynchronously and may not have completed yet. Pushing the deep-link
    // target now would leave /splash as the base of the back stack, so pressing
    // Back would show the splash loading spinner. Wait until the router has
    // actually settled off /splash before dispatching so the target is pushed
    // on top of /home and Back returns Home.
    _dispatchWhenRouterSettled(router, pending);
    return true;
  }

  /// Dispatches [uri] once the router's base location has left `/splash`.
  ///
  /// Uses `currentConfiguration.uri`, which reflects only non-imperative
  /// matches (i.e. the true base location, ignoring any pushed pages). The
  /// router delegate is a [Listenable], so we attach a one-shot listener when
  /// the base has not settled yet.
  void _dispatchWhenRouterSettled(GoRouter router, Uri uri) {
    final delegate = router.routerDelegate;

    bool isSettled() =>
        delegate.currentConfiguration.uri.path != AppRoutes.splash;

    if (isSettled()) {
      _dispatch(uri);
      return;
    }

    _logger.info('Router still on splash, deferring deep link dispatch: $uri');
    void onRouterChanged() {
      if (!isSettled()) return;
      delegate.removeListener(onRouterChanged);
      _logger.info('Router settled, dispatching deferred deep link: $uri');
      _dispatch(uri);
    }

    delegate.addListener(onRouterChanged);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }

  void _handleLink(Uri uri) {
    if (!DeepLinkRouter.isFirstPartyAppLink(uri)) {
      _logger.debug('Ignoring non-first-party app link: $uri');
      return;
    }

    if (_pendingUri == uri) {
      _logger.debug('Ignoring duplicate pending app link: $uri');
      return;
    }

    if (_wasRecentlyDispatched(uri)) {
      _logger.debug('Ignoring recently dispatched app link: $uri');
      return;
    }

    if (_router == null) {
      _pendingUri = uri;
      _logger.info('Router not ready, stored app link: $uri');
      return;
    }

    _dispatch(uri);
  }

  bool _dispatch(Uri uri, {String? baseLocation}) {
    final router = _router;
    if (router == null) return false;

    if (_wasRecentlyDispatched(uri)) {
      _logger.debug('Skipping duplicate app link dispatch: $uri');
      return false;
    }

    final routed = DeepLinkRouter.route(
      uri,
      router,
      source: 'app_links',
      analytics: _analytics,
      baseLocation: baseLocation,
      tabSetter: _tabSetter,
      planNavigator: _planNavigator,
    );
    if (routed) {
      _lastDispatchedUri = uri;
      _lastDispatchedAt = DateTime.now();
    }
    return routed;
  }

  bool _wasRecentlyDispatched(Uri uri) {
    final lastUri = _lastDispatchedUri;
    final lastAt = _lastDispatchedAt;
    if (lastUri != uri || lastAt == null) return false;

    return DateTime.now().difference(lastAt) < _duplicateDispatchWindow;
  }
}
