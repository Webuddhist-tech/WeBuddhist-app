import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_embedded_host.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/domain/services/navigation_service.dart';
import 'package:go_router/go_router.dart';

/// Centralised navigation between plan subtask screens.
///
/// A plan day's subtask list is a flat sequence of mixed content types
/// (SOURCE_REFERENCE → ReaderScreen, TEXT/IMAGE → PlanTextScreen). When the
/// user taps prev/next or swipes, the next item may live on a *different*
/// screen than the current one. This helper picks the right route and replaces
/// the current screen, so the user perceives a seamless "1/N → 2/N" sequence.
///
/// Inside a [PlanEmbeddedScope] the screens are shown in place instead.
class PlanNavigator {
  PlanNavigator._();

  /// Push the screen for [item], scrolling to its first segment (if any),
  /// using the supplied [navigationContext].
  ///
  /// Use [push] for the initial entry from the activity list. For mid-sequence
  /// transitions where the user shouldn't be able to back-stack to every prior
  /// item, use [replace] instead.
  static Future<T?> push<T>(
    BuildContext context,
    PlanTextItem item,
    NavigationContext navigationContext,
  ) {
    final embedded = PlanEmbeddedScope.maybeOf(context);
    if (embedded != null) return embedded.open<T>(item, navigationContext);
    return context.push<T>(_routeFor(item), extra: navigationContext);
  }

  /// Same as [push] but replaces the current screen, used by the bottom
  /// bar's prev/next arrows and by horizontal swipes.
  static void replace(
    BuildContext context,
    PlanTextItem item,
    NavigationContext navigationContext,
  ) {
    final embedded = PlanEmbeddedScope.maybeOf(context);
    if (embedded != null) {
      embedded.replace(item, navigationContext);
      return;
    }
    context.pushReplacement(_routeFor(item), extra: navigationContext);
  }

  /// Leaves the sequence: closes the embedded host, else pops the route.
  static void pop(BuildContext context, [Object? result]) {
    final embedded = PlanEmbeddedScope.maybeOf(context);
    if (embedded != null) {
      embedded.close(result);
      return;
    }
    context.pop(result);
  }

  /// Move to the adjacent item in [direction]. Returns true if it navigated,
  /// false if there is no neighbour in that direction.
  /// Pass [autoPlay] to begin audio playback immediately in the next screen.
  static bool navigateAdjacent(
    BuildContext context,
    NavigationContext currentContext,
    SwipeDirection direction, {
    bool autoPlay = false,
  }) {
    const service = NavigationService();
    final newContext = service.createNavigationContextForAdjacent(
      currentContext,
      direction,
      autoPlay: autoPlay,
    );
    final adjacent = service.getAdjacentText(currentContext, direction);
    if (newContext == null || adjacent == null) return false;

    replace(context, adjacent, newContext);
    return true;
  }

  static String _routeFor(PlanTextItem item) {
    switch (item.contentType) {
      case PlanItemContentType.sourceReference:
        return '${AppRoutes.reader}/${item.textId}';
      case PlanItemContentType.inlineText:
      case PlanItemContentType.inlineImage:
        return _planTextRouteFor(item);
    }
  }

  static String _planTextRouteFor(PlanTextItem item) {
    // Subtask id is required for plan-text routes; fall back to a stable
    // synthetic id only if the item came from preview (no subtaskId).
    // Item identity is irrelevant to PlanTextScreen — it reads content
    // from navigationContext.currentItem.
    final id = item.subtaskId ?? 'preview';
    return '${AppRoutes.planText}/$id';
  }
}
