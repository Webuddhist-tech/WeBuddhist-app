import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:go_router/go_router.dart';

/// Runs [navigate] once [router] has left the splash, or at once when it
/// already has.
///
/// While the splash is up (auth still loading, or the launch intro holding
/// it; see `splashHoldProvider`) the route guard sends every navigation to
/// `/splash` and does not remember where it was headed. Anything that
/// navigates on its own, rather than from a tap inside the app, goes through
/// here: deep links, Airbridge links and notification taps. It then lands
/// once the splash has made way, on top of the screen the splash exits to,
/// so Back returns there instead of to the splash.
///
/// Watches the router's base location, which ignores pushed pages. Each call
/// runs [navigate] exactly once; calls made while waiting run in order.
/// Returns true when [navigate] ran at once.
bool runWhenOffSplash(GoRouter router, VoidCallback navigate) {
  final delegate = router.routerDelegate;

  bool offSplash() {
    final configuration = delegate.currentConfiguration;
    return configuration.isNotEmpty &&
        configuration.uri.path != AppRoutes.splash;
  }

  if (offSplash()) {
    navigate();
    return true;
  }

  void onRouterChanged() {
    if (!offSplash()) return;
    delegate.removeListener(onRouterChanged);
    navigate();
  }

  delegate.addListener(onRouterChanged);
  return false;
}
