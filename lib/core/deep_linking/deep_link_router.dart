import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/entry_analytics.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:go_router/go_router.dart';

class DeepLinkRouter {
  DeepLinkRouter._();

  static final _logger = AppLogger('DeepLinkRouter');

  static bool route(
    Uri uri,
    GoRouter router, {
    required String source,
    EntryAnalytics? analytics,
    String? baseLocation,
    void Function(int tabIndex)? tabSetter,
    void Function(String planId, int? dayNumber, String? planLanguage)?
        planNavigator,
  }) {
    try {
      final destination = _resolveRoute(uri);
      if (destination == null) {
        _logger.warning('Unhandled deep link from $source: $uri');
        return false;
      }

      // Plan links can't be expressed as a plain location: opening a specific
      // plan requires resolving the plan model from its id, which the injected
      // [planNavigator] handles (mirroring the PLAN push-notification path).
      // When no navigator is wired (e.g. the Airbridge path), fall through to
      // the destination's fallback location instead.
      final planId = destination.planId;
      if (planId != null && planNavigator != null) {
        _logger.info(
          'Deep link from $source -> plan $planId day ${destination.dayNumber} lang ${destination.planLanguage} ($uri)',
        );
        planNavigator(planId, destination.dayNumber, destination.planLanguage);
        _trackOpened(analytics, source, destination);
        return true;
      }

      _logger.info('Deep link from $source -> ${destination.location} ($uri)');
      if (destination.opensOnTop && baseLocation != null) {
        router.go(baseLocation);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pushWithParent(router, destination);
        });
      } else if (destination.opensOnTop) {
        _pushWithParent(router, destination);
      } else {
        router.go(destination.location, extra: destination.extra);
      }

      final tabIndex = destination.tabIndex;
      if (tabIndex != null && tabSetter != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          tabSetter(tabIndex);
        });
      }

      _trackOpened(analytics, source, destination);
      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Error routing deep link from $source: $uri',
        e,
        stackTrace,
      );
      return false;
    }
  }

  static void _trackOpened(
    EntryAnalytics? analytics,
    String source,
    _DeepLinkDestination destination,
  ) {
    analytics?.deepLinkOpened(
      source: source,
      routeKind: destination.routeKind,
      targetId: destination.targetId,
    );
  }

  /// Pushes [destination.location], first pushing [destination.parentLocation]
  /// (when set) so the back button unwinds through the parent screen.
  static void _pushWithParent(
    GoRouter router,
    _DeepLinkDestination destination,
  ) {
    final parentLocation = destination.parentLocation;
    if (parentLocation != null) {
      router.push(parentLocation);
    }
    router.push(destination.location, extra: destination.extra);
  }

  static bool isFirstPartyAppLink(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'https' || scheme == 'http') &&
        uri.host.toLowerCase() == 'webuddhist.com' &&
        (uri.path == '/open' || uri.path.startsWith('/open/'));
  }

  static bool isAirbridgeLink(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();

    return scheme == 'webuddhist' ||
        host == 'join.webuddhist.com' ||
        host.endsWith('.airbridge.io') ||
        host.endsWith('.abr.ge');
  }

  static _DeepLinkDestination? _resolveRoute(Uri uri) {
    if (isFirstPartyAppLink(uri)) {
      return _resolveFirstPartyAppLink(uri);
    }

    if (uri.scheme.toLowerCase() == 'webuddhist') {
      return _resolveWebuddhistSchemeLink(uri.host.toLowerCase());
    }

    if (isAirbridgeLink(uri)) {
      return const _DeepLinkDestination(AppRoutes.home);
    }

    return null;
  }

  static _DeepLinkDestination _resolveFirstPartyAppLink(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length >= 3 &&
        segments[0] == 'open' &&
        segments[1] == 'series') {
      final seriesId = segments[2];
      return _DeepLinkDestination(
        '/home/series/${Uri.encodeComponent(seriesId)}',
        routeKind: 'series',
        targetId: seriesId,
        opensOnTop: true,
      );
    }

    if (segments.length >= 3 &&
        segments[0] == 'open' &&
        segments[1] == 'reader') {
      final textId = segments[2];
      final segmentId =
          uri.queryParameters['segment'] ?? uri.queryParameters['segmentId'];

      return _DeepLinkDestination(
        '/reader/${Uri.encodeComponent(textId)}',
        extra: NavigationContext(
          source: NavigationSource.deepLink,
          targetSegmentId: segmentId,
        ),
        routeKind: 'reader',
        targetId: textId,
        opensOnTop: true,
      );
    }

    if (segments.length >= 2 &&
        segments[0] == 'open' &&
        segments[1] == 'reader') {
      final textId = uri.queryParameters['textId'];
      final segmentId =
          uri.queryParameters['segment'] ?? uri.queryParameters['segmentId'];

      if (textId != null && textId.isNotEmpty) {
        return _DeepLinkDestination(
          '/reader/${Uri.encodeComponent(textId)}',
          extra: NavigationContext(
            source: NavigationSource.deepLink,
            targetSegmentId: segmentId,
          ),
          routeKind: 'reader',
          targetId: textId,
          opensOnTop: true,
        );
      }
    }

    if (segments.length >= 2 &&
        segments[0] == 'open' &&
        segments[1] == 'more') {
      return const _DeepLinkDestination(
        AppRoutes.home,
        routeKind: 'more',
        tabIndex: _meTabIndex,
      );
    }

    if (segments.length >= 3 &&
        segments[0] == 'open' &&
        segments[1] == 'plan') {
      final planId = segments[2];
      // /open/plan/{planId}/day/{dayNumber}?lang={language}  — specific day deep link
      int? dayNumber;
      if (segments.length >= 5 && segments[3] == 'day') {
        dayNumber = int.tryParse(segments[4]);
      }
      // lang carries the content language the plan was enrolled in, so the
      // recipient's app can find the enrollment even across locale differences.
      final planLanguage = uri.queryParameters['lang'];
      // Fallback location (My Practices) is used only when no planNavigator is
      // wired; otherwise the navigator resolves and opens the specific plan.
      return _DeepLinkDestination(
        AppRoutes.practiceMyPractices,
        routeKind: 'plan',
        targetId: planId,
        planId: planId,
        dayNumber: dayNumber,
        planLanguage: planLanguage,
        opensOnTop: true,
      );
    }

    if (segments.length >= 5 &&
        segments[0] == 'open' &&
        segments[1] == 'group' &&
        segments[3] == 'recitation-collections') {
      final groupId = segments[2];
      final collectionId = segments[4];
      return _DeepLinkDestination(
        '/home/group/${Uri.encodeComponent(groupId)}/recitation-collections/${Uri.encodeComponent(collectionId)}',
        parentLocation: '/home/group/${Uri.encodeComponent(groupId)}',
        routeKind: 'group_collection',
        targetId: collectionId,
        opensOnTop: true,
      );
    }

    if (segments.length >= 3 &&
        segments[0] == 'open' &&
        segments[1] == 'group') {
      final groupId = segments[2];
      return _DeepLinkDestination(
        '/home/group/$groupId',
        routeKind: 'group',
        targetId: groupId,
        opensOnTop: true,
      );
    }

    if (segments.length >= 3 &&
        segments[0] == 'open' &&
        segments[1] == 'events') {
      final eventId = segments[2];
      return _DeepLinkDestination(
        '/home/events/${Uri.encodeComponent(eventId)}',
        routeKind: 'event',
        targetId: eventId,
        opensOnTop: true,
      );
    }

    if (segments.length >= 3 &&
        segments[0] == 'open' &&
        segments[1] == 'group-accumulator') {
      final accumulatorId = segments[2];
      final groupId = uri.queryParameters['group'];
      return _DeepLinkDestination(
        '/home/group-accumulator/${Uri.encodeComponent(accumulatorId)}',
        parentLocation: groupId != null && groupId.isNotEmpty
            ? '/home/group/${Uri.encodeComponent(groupId)}'
            : null,
        routeKind: 'group_accumulator',
        targetId: accumulatorId,
        opensOnTop: true,
        tabIndex: _connectTabIndex,
      );
    }

    if (segments.length >= 3 &&
        segments[0] == 'open' &&
        segments[1] == 'mala') {
      final presetId = segments[2];
      return _DeepLinkDestination(
        AppRoutes.mala,
        extra: {'presetId': presetId},
        routeKind: 'mala',
        targetId: presetId,
        opensOnTop: true,
      );
    }

    if (segments.length >= 3 &&
        segments[0] == 'open' &&
        segments[1] == 'timer') {
      return const _DeepLinkDestination(
        '/home/timers',
        routeKind: 'timer',
        opensOnTop: true,
      );
    }

    if (segments.length >= 3 &&
        segments[0] == 'open' &&
        segments[1] == 'poem') {
      final poemId = segments[2];
      return _DeepLinkDestination(
        '/home/poems',
        extra: {'initialPoemId': poemId},
        routeKind: 'poem',
        targetId: poemId,
        opensOnTop: true,
      );
    }

    return const _DeepLinkDestination(AppRoutes.home);
  }

  static _DeepLinkDestination _resolveWebuddhistSchemeLink(String host) {
    switch (host) {
      case 'open':
      case 'home':
        return const _DeepLinkDestination(AppRoutes.home);
      case 'practice':
        return const _DeepLinkDestination(
          AppRoutes.practice,
          routeKind: 'practice',
        );
      case 'more':
        return const _DeepLinkDestination(
          AppRoutes.home,
          routeKind: 'more',
          tabIndex: _meTabIndex,
        );
      case 'profile':
        return const _DeepLinkDestination(
          AppRoutes.profile,
          routeKind: 'profile',
        );
      case 'notifications':
        return const _DeepLinkDestination(
          AppRoutes.notifications,
          routeKind: 'notifications',
        );
      default:
        _logger.warning('Unknown webuddhist deep link host: $host');
        return const _DeepLinkDestination(AppRoutes.home);
    }
  }
}

/// Bottom nav tab index for the Me screen (matches MainTab.me.index == 3).
const int _meTabIndex = 3;

/// Bottom nav tab index for the Connect screen (matches MainTab.connect.index == 2).
const int _connectTabIndex = 2;

class _DeepLinkDestination {
  final String location;
  final Object? extra;
  final bool opensOnTop;

  /// When non-null, this location is pushed beneath [location] so the back
  /// button returns to the parent screen (e.g. group page beneath a group
  /// accumulation) instead of straight to the base location.
  final String? parentLocation;

  /// When non-null, the deep-link handler should switch the bottom nav bar to
  /// this tab index after navigating. Used for tab-based screens that share
  /// the `/home` route (e.g. the Me tab).
  final int? tabIndex;

  /// When non-null, this destination targets a specific plan that must be
  /// resolved from its id by the injected `planNavigator`. [location] then
  /// acts only as a fallback for callers without a navigator.
  final String? planId;

  /// When non-null, the plan navigator should open this specific day instead
  /// of computing today's day from the plan start date.
  final int? dayNumber;

  /// Content language of the shared plan (e.g. 'en', 'bo'). Passed to the
  /// plan navigator so it can find the enrollment across locale differences.
  final String? planLanguage;

  /// `route_kind` and `target_id` carried on `deep_link_opened`.
  final String routeKind;
  final String? targetId;

  const _DeepLinkDestination(
    this.location, {
    this.extra,
    this.opensOnTop = false,
    this.parentLocation,
    this.tabIndex,
    this.planId,
    this.dayNumber,
    this.planLanguage,
    this.routeKind = 'home',
    this.targetId,
  });
}
