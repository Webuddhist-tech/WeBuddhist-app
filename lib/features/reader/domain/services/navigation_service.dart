import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// Service for handling plan-based navigation between texts
class NavigationService {
  const NavigationService();

  /// Get the adjacent text item for swipe navigation
  /// Returns null if there is no adjacent text in the given direction
  PlanTextItem? getAdjacentText(
    NavigationContext context,
    SwipeDirection direction,
  ) {
    if (!context.canSwipe) return null;

    final items = context.planTextItems!;
    final currentIndex = context.currentTextIndex;
    if (currentIndex == null) return null;

    final newIndex =
        direction == SwipeDirection.next ? currentIndex + 1 : currentIndex - 1;

    if (newIndex < 0 || newIndex >= items.length) return null;
    return items[newIndex];
  }

  /// Check if navigation in the given direction is possible
  bool canNavigate(NavigationContext context, SwipeDirection direction) {
    return getAdjacentText(context, direction) != null;
  }

  /// Create a new navigation context for the adjacent text.
  /// Pass [autoPlay] to trigger audio playback in the destination screen.
  NavigationContext? createNavigationContextForAdjacent(
    NavigationContext currentContext,
    SwipeDirection direction, {
    bool autoPlay = false,
  }) {
    final adjacentText = getAdjacentText(currentContext, direction);
    if (adjacentText == null) return null;

    final newIndex =
        direction == SwipeDirection.next
            ? currentContext.currentTextIndex! + 1
            : currentContext.currentTextIndex! - 1;
    return createNavigationContextForIndex(
      currentContext,
      newIndex,
      direction: direction,
      autoPlay: autoPlay,
    );
  }

  /// Context for jumping to any [index] of the sequence, e.g. when a live
  /// recitation moves to another text. Null when [index] is out of range or
  /// already current. [direction] defaults to the side [index] lies on.
  NavigationContext? createNavigationContextForIndex(
    NavigationContext currentContext,
    int index, {
    SwipeDirection? direction,
    bool autoPlay = false,
  }) {
    final items = currentContext.planTextItems;
    final currentIndex = currentContext.currentTextIndex;
    if (items == null ||
        currentIndex == null ||
        index < 0 ||
        index >= items.length ||
        index == currentIndex) {
      return null;
    }
    final target = items[index];
    final resolvedDirection =
        direction ??
        (index > currentIndex ? SwipeDirection.next : SwipeDirection.previous);

    // Handle recitation collection navigation.
    if (currentContext.source == NavigationSource.groupRecitationCollection ||
        currentContext.source == NavigationSource.myRecitationCollection) {
      return NavigationContext(
        source: currentContext.source,
        targetSegmentId: target.firstSegmentId,
        planTextItems: items,
        currentTextIndex: index,
        navigationDirection: resolvedDirection,
        groupId: currentContext.groupId,
        collectionId: currentContext.collectionId,
        language: target.language,
        eventId: currentContext.eventId,
      );
    }

    // Handle plan navigation
    return NavigationContext(
      source: NavigationSource.plan,
      planId: currentContext.planId,
      dayNumber: currentContext.dayNumber,
      targetSegmentId: target.firstSegmentId,
      planTextItems: items,
      currentTextIndex: index,
      navigationDirection: resolvedDirection,
      dayAudioUrl: currentContext.dayAudioUrl,
      autoPlay: autoPlay,
      eventId: currentContext.eventId,
    );
  }

  /// Get progress information for the current position in the plan
  NavigationProgress? getProgress(NavigationContext context) {
    if (!context.canSwipe) return null;

    final items = context.planTextItems!;
    final currentIndex = context.currentTextIndex;
    if (currentIndex == null) return null;

    return NavigationProgress(
      currentIndex: currentIndex,
      totalCount: items.length,
      currentTitle: items[currentIndex].title,
      hasNext: currentIndex < items.length - 1,
      hasPrevious: currentIndex > 0,
    );
  }
}

/// Progress information for plan navigation
class NavigationProgress {
  final int currentIndex;
  final int totalCount;
  final String currentTitle;
  final bool hasNext;
  final bool hasPrevious;

  const NavigationProgress({
    required this.currentIndex,
    required this.totalCount,
    required this.currentTitle,
    required this.hasNext,
    required this.hasPrevious,
  });

  /// Human-readable progress string (e.g., "2 of 5")
  String get progressText => '${currentIndex + 1} of $totalCount';
}
