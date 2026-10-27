import 'package:flutter/material.dart';

/// The last step of the Figma loading animation (WeBuddhist-App › Onboarding ›
/// "updated loading animation"): once the launch intro has played, the next
/// screen fades in over the still splash, 600 ms ease-in, instead of the
/// platform's usual page transition.
///
/// The router calls [arm] when the launch intro completes. The next
/// [SplashExitPage] route created after that fades in. Any route pushed on the
/// root navigator disarms it, through [observer], so an exit to a screen that
/// is not a [SplashExitPage] keeps its usual transition, and the fade never
/// carries over to a later navigation.
class SplashExitTransition {
  static const Duration duration = Duration(milliseconds: 600);
  static const Curve curve = Curves.easeIn;

  bool _armed = false;

  /// Makes the next [SplashExitPage] route fade in.
  void arm() => _armed = true;

  bool _take() {
    final armed = _armed;
    _armed = false;
    return armed;
  }

  /// Add to the root navigator's observers.
  late final NavigatorObserver observer = _DisarmOnPush(this);
}

class _DisarmOnPush extends NavigatorObserver {
  _DisarmOnPush(this._exit);

  final SplashExitTransition _exit;

  // A route is created before its push is reported, so a [SplashExitPage]
  // replacing the splash has already taken the fade by the time this runs.
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _exit._armed = false;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _exit._armed = false;
}

/// A page for a screen the launch splash can exit to. It fades in when it
/// replaces the launch splash (see [SplashExitTransition]) and otherwise
/// behaves exactly like a [MaterialPage], with the platform transition.
class SplashExitPage extends Page<void> {
  const SplashExitPage({
    required this.exit,
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final SplashExitTransition exit;
  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) =>
      _SplashExitRoute(page: this, fadesIn: exit._take());
}

class _SplashExitRoute extends PageRoute<void>
    with MaterialRouteTransitionMixin<void> {
  _SplashExitRoute({required SplashExitPage page, required this.fadesIn})
    : super(settings: page);

  /// Whether this route replaces the launch splash. Decided once, when the
  /// route is created, so later page updates never change its transition.
  final bool fadesIn;

  static final Animatable<double> _fade = CurveTween(
    curve: SplashExitTransition.curve,
  );

  SplashExitPage get _page => settings as SplashExitPage;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  bool get maintainState => true;

  @override
  bool get fullscreenDialog => false;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Duration get transitionDuration {
    if (!fadesIn) return super.transitionDuration;
    final reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(navigator!.context) ?? false;
    return reduceMotion ? Duration.zero : SplashExitTransition.duration;
  }

  // The splash underneath stays still while this route fades in over it:
  // it plays no outgoing transition of its own, and none is delegated to it.
  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      !fadesIn && super.canTransitionFrom(previousRoute);

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      fadesIn ? null : super.delegatedTransition;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!fadesIn) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    // Fades in on the way in. The platform transition still handles what
    // happens when another screen is pushed over this one later.
    return FadeTransition(
      opacity: animation.drive(_fade),
      child: super.buildTransitions(
        context,
        kAlwaysCompleteAnimation,
        secondaryAnimation,
        child,
      ),
    );
  }
}
