import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_recitation_completion_service.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigation_bottom_bar.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_subtask_completion.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/my_recitation_completion_service.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/texts/data/models/text_detail.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps the reader content with horizontal-swipe gestures and the shared
/// plan navigation bottom bar.
///
/// Both prev/next gestures and bottom-bar arrows route through
/// [PlanNavigator], which picks the correct screen for the next item's
/// content type — so a SOURCE_REFERENCE → TEXT transition (or vice versa)
/// happens transparently mid-sequence.
class SwipeNavigationWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final ReaderParams params;
  final TextDetail textDetail;
  final bool isAppBarVisible;

  const SwipeNavigationWrapper({
    super.key,
    required this.child,
    required this.params,
    required this.textDetail,
    required this.isAppBarVisible,
  });

  @override
  ConsumerState<SwipeNavigationWrapper> createState() =>
      _SwipeNavigationWrapperState();
}

class _SwipeNavigationWrapperState
    extends ConsumerState<SwipeNavigationWrapper> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerNotifierProvider(widget.params));
    final navigationContext = state.navigationContext;
    final hideBottomNav = state.hasSelection && !state.isCommentaryOpen;
    final isGroupChant =
        navigationContext?.source == NavigationSource.groupAccumulatorChant;
    final showBottomBar =
        !hideBottomNav && !state.isCommentaryOpen && !isGroupChant;

    final canSwipe = navigationContext != null && navigationContext.canSwipe;

    return GestureDetector(
      onHorizontalDragEnd:
          canSwipe ? (details) => _onDragEnd(details, navigationContext) : null,
      child: Stack(
        children: [
          widget.child,
          if (showBottomBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PlanNavigationBottomBar(
                navigationContext: navigationContext,
                fallbackTitle: widget.textDetail.title,
                fallbackTitleFontFamily: getFontFamily(
                  widget.textDetail.language,
                ),
                onPreviousTap:
                    canSwipe
                        ? () => _navigate(
                          navigationContext,
                          SwipeDirection.previous,
                        )
                        : null,
                onNextTap:
                    canSwipe
                        ? () =>
                            _navigate(navigationContext, SwipeDirection.next)
                        : null,
                onFinishedTap:
                    navigationContext != null &&
                            (navigationContext.source ==
                                    NavigationSource.plan ||
                                navigationContext.source ==
                                    NavigationSource
                                        .groupRecitationCollection ||
                                navigationContext.source ==
                                    NavigationSource.myRecitationCollection)
                        ? _finishReading
                        : null,
              ),
            ),
        ],
      ),
    );
  }

  void _onDragEnd(DragEndDetails details, NavigationContext navigationContext) {
    if (_isNavigating) return;

    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < ReaderConstants.swipeVelocityThreshold) return;

    final direction =
        velocity > 0 ? SwipeDirection.previous : SwipeDirection.next;
    _navigate(navigationContext, direction);
  }

  void _navigate(NavigationContext currentContext, SwipeDirection direction) {
    if (_isNavigating) return;

    if (direction == SwipeDirection.next) {
      // Complete the current item based on its source
      if (currentContext.source == NavigationSource.plan) {
        ref.read(planSubtaskCompletionProvider).completeCurrent(currentContext);
      } else if (currentContext.source ==
          NavigationSource.groupRecitationCollection) {
        ref
            .read(groupRecitationCompletionProvider)
            .completeCurrent(currentContext);
      } else if (currentContext.source ==
          NavigationSource.myRecitationCollection) {
        ref
            .read(myRecitationCompletionProvider)
            .completeCurrent(currentContext);
      }
    }

    // Clear UI state before navigation for clean transition
    final notifier = ref.read(readerNotifierProvider(widget.params).notifier);
    notifier.selectSegment(null);
    notifier.closeCommentary();
    notifier.closeTranslation();

    final didNavigate = PlanNavigator.navigateAdjacent(
      context,
      currentContext,
      direction,
    );
    if (!didNavigate) {
      // A forward swipe past the last task exits the sequence.
      if (direction == SwipeDirection.next) _finishReading();
      return;
    }

    _isNavigating = true;
  }

  void _finishReading() async {
    if (_isNavigating) return;
    _isNavigating = true;

    final navContext = widget.params.navigationContext;
    // Complete the current item based on its source
    if (navContext?.source == NavigationSource.plan) {
      await ref.read(planSubtaskCompletionProvider).completeCurrent(navContext);
    } else if (navContext?.source ==
        NavigationSource.groupRecitationCollection) {
      await ref
          .read(groupRecitationCompletionProvider)
          .completeCurrent(navContext);
    } else if (navContext?.source == NavigationSource.myRecitationCollection) {
      await ref
          .read(myRecitationCompletionProvider)
          .completeCurrent(navContext);
    }

    if (!mounted) return;
    PlanNavigator.pop(context);
  }
}
