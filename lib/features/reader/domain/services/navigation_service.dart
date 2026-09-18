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

    // Handle recitation collection navigation.
    if (currentContext.source == NavigationSource.groupRecitationCollection ||
        currentContext.source == NavigationSource.myRecitationCollection) {
      return NavigationContext(
        source: currentContext.source,
        targetSegmentId: adjacentText.firstSegmentId,
        planTextItems: currentContext.planTextItems,
        currentTextIndex: newIndex,
        navigationDirection: direction,
        groupId: currentContext.groupId,
        collectionId: currentContext.collectionId,
        language: adjacentText.language,
      );
    }

    // Handle plan navigation
    return NavigationContext(
      source: NavigationSource.plan,
      planId: currentContext.planId,
      dayNumber: currentContext.dayNumber,
      targetSegmentId: adjacentText.firstSegmentId,
      planTextItems: currentContext.planTextItems,
      currentTextIndex: newIndex,
      navigationDirection: direction,
      dayAudioUrl: currentContext.dayAudioUrl,
      autoPlay: autoPlay,
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
