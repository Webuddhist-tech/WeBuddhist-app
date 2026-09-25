import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/services/upgrade/force_update_dialog.dart';
import 'package:flutter_pecha/core/services/upgrade/upgrade_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps the app's root child and blocks it with a non-dismissible
/// forced-update modal on Android/iOS whenever the store has a newer version.
///
/// Mount this via [MaterialApp.router]'s `builder` parameter so the modal
/// sits above the GoRouter navigator and blocks every route.
///
/// The modal is layered in this widget's own [Stack] rather than pushed with
/// `showDialog`: a pageless dialog route on the GoRouter navigator is removed
/// as soon as GoRouter rebuilds its page stack (e.g. an auth redirect right
/// after launch), which let users dismiss the update by simply waiting.
///
/// Because the modal is not a route, `PopScope` cannot guard it. Android back
/// is instead swallowed here while the modal is visible — see [didPopRoute].
class ForceUpdateGate extends ConsumerStatefulWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends ConsumerState<ForceUpdateGate>
    with WidgetsBindingObserver {
  bool _updateRequired = false;

  @override
  void initState() {
    super.initState();
    // Registered here, before the Router below builds, so this observer is
    // asked first: back events are offered to observers in registration
    // order and the first one returning true consumes the event.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Consumes system back so it can't pop the routes hidden behind the modal.
  @override
  Future<bool> didPopRoute() async => _updateRequired;

  /// Claims Android predictive-back gestures for the same reason; the
  /// progress / commit / cancel callbacks are left as no-ops.
  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) => _updateRequired;

  /// Stops the navigator reporting "nothing to pop" to the engine while
  /// blocked. With `enableOnBackInvokedCallback`, Android finishes the
  /// activity itself in that case, without ever calling [didPopRoute].
  bool _onNavigationNotification(NavigationNotification notification) {
    if (!_updateRequired) return false;
    SystemNavigator.setFrameworkHandlesBack(true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Only enforce on Android/iOS; skip macOS and other platforms.
    if (!Platform.isAndroid && !Platform.isIOS) {
      return widget.child;
    }

    final updateRequired =
        ref.watch(updateAvailableProvider).valueOrNull ?? false;
    if (updateRequired != _updateRequired) {
      _updateRequired = updateRequired;
      // While blocked, the framework must receive back so [didPopRoute] can
      // swallow it. When unblocked, true is still safe: the router pops or
      // falls back to SystemNavigator.pop(), and the next navigation
      // notification restores the accurate value.
      SystemNavigator.setFrameworkHandlesBack(true);
    }

    // Keep the tree shape stable across both states so toggling the gate
    // never remounts the navigator underneath.
    return NotificationListener<NavigationNotification>(
      onNotification: _onNavigationNotification,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeFocus(
            excluding: updateRequired,
            child: ExcludeSemantics(
              excluding: updateRequired,
              child: widget.child,
            ),
          ),
          if (updateRequired) ...[
            const ModalBarrier(dismissible: false, color: Colors.black54),
            const ForceUpdateDialog(),
          ],
        ],
      ),
    );
  }
}
