import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/clarity_screen_tracker.dart';

/// Feeds the page routes of one navigator into a [ClarityScreenTracker].
/// Dialogs and sheets are skipped so their taps count toward the screen
/// underneath.
class ClarityScreenObserver extends NavigatorObserver {
  ClarityScreenObserver(this._tracker);

  final ClarityScreenTracker _tracker;

  static final Expando<int> _depths = Expando<int>('clarityNavigatorDepth');

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _push(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _tracker.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _tracker.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute is! PageRoute) {
      if (oldRoute is PageRoute) _tracker.remove(oldRoute);
      return;
    }
    final navigator = newRoute.navigator;
    if (oldRoute is! PageRoute || navigator == null) {
      _push(newRoute);
      return;
    }
    _tracker.replace(
      oldRoute: oldRoute,
      navigator: navigator,
      depth: _depthOf(navigator),
      route: newRoute,
      name: newRoute.settings.name,
      isHost: _isHost(newRoute),
    );
  }

  void _push(Route<dynamic> route) {
    if (route is! PageRoute) return;
    final navigator = route.navigator;
    if (navigator == null) return;
    _tracker.push(
      navigator: navigator,
      depth: _depthOf(navigator),
      route: route,
      name: route.settings.name,
      isHost: _isHost(route),
    );
  }

  // go_router names every page it builds; the only unnamed page is the shell
  // that hosts the tab navigator.
  static bool _isHost(Route<dynamic> route) =>
      route.settings is Page && route.settings.name == null;

  static int _depthOf(NavigatorState navigator) {
    final cached = _depths[navigator];
    if (cached != null) return cached;
    var depth = 0;
    var parent = navigator.context.findAncestorStateOfType<NavigatorState>();
    while (parent != null) {
      depth++;
      parent = parent.context.findAncestorStateOfType<NavigatorState>();
    }
    return _depths[navigator] = depth;
  }
}
