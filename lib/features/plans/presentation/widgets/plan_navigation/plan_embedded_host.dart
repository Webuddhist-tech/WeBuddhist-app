import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// Plan subtask screens shown inside a page instead of pushed as routes.
class PlanEmbeddedController extends ChangeNotifier {
  PlanTextItem? _item;
  NavigationContext? _navigationContext;
  Completer<Object?>? _completer;
  int _generation = 0;

  PlanTextItem? get item => _item;

  NavigationContext? get navigationContext => _navigationContext;

  /// Bumps on every open / replace so the hosted screen is rebuilt fresh.
  int get generation => _generation;

  bool get isOpen => _item != null;

  /// Shows [item]; completes with the result passed to [close].
  Future<T?> open<T>(PlanTextItem item, NavigationContext navigationContext) {
    final completer = _completer ??= Completer<Object?>();
    _show(item, navigationContext);
    return completer.future.then((result) => result as T?);
  }

  /// Swaps the shown item without ending the session.
  void replace(PlanTextItem item, NavigationContext navigationContext) {
    if (!isOpen) {
      open(item, navigationContext);
      return;
    }
    _show(item, navigationContext);
  }

  void close([Object? result]) {
    final completer = _completer;
    if (completer == null) return;
    _completer = null;
    _item = null;
    _navigationContext = null;
    notifyListeners();
    completer.complete(result);
  }

  void _show(PlanTextItem item, NavigationContext navigationContext) {
    _item = item;
    _navigationContext = navigationContext;
    _generation++;
    notifyListeners();
  }

  @override
  void dispose() {
    close();
    super.dispose();
  }
}

/// Lets `PlanNavigator` below open subtask screens in [controller], not routes.
class PlanEmbeddedScope extends InheritedWidget {
  final PlanEmbeddedController controller;

  const PlanEmbeddedScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static PlanEmbeddedController? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<PlanEmbeddedScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(PlanEmbeddedScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Close bar for an embedded subtask screen: X on the left, [actions] right.
class PlanEmbeddedHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onClose;
  final List<Widget> actions;

  const PlanEmbeddedHeader({
    super.key,
    required this.onClose,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.x),
            tooltip: context.l10n.close,
            onPressed: onClose,
          ),
          const Spacer(),
          ...actions,
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
