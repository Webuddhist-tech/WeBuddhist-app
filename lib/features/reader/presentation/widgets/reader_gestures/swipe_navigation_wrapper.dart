import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_recitation_completion_service.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigation_bottom_bar.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_subtask_completion.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/my_recitation_completion_service.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_toc_titles.dart';
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

  /// Focus mode: the bottom bar slides down out of view with the header.
  /// [aboveBottomBar] stays, so audio can still be paused.
  final bool isAppBarVisible;

  /// Drawn directly above the navigation strip, with no gap. The reader uses
  /// this for the play button and audio bar so they share the strip's layout.
  final Widget? aboveBottomBar;

  /// Reports the height of the navigation strip, including [aboveBottomBar],
  /// as laid out with the strip in view. Focus mode does not change it, so
  /// the reader's bottom padding stays put while the strip animates.
  final ValueChanged<double>? onBottomBarHeight;

  const SwipeNavigationWrapper({
    super.key,
    required this.child,
    required this.params,
    required this.textDetail,
    required this.isAppBarVisible,
    this.aboveBottomBar,
    this.onBottomBarHeight,
  });

  /// Whether the navigation strip is on screen for [state]. It makes way for
  /// a verse's sheet, a commentary, and a group accumulation chant.
  static bool showsBottomBar(ReaderState state) {
    final isGroupChant =
        state.navigationContext?.source ==
        NavigationSource.groupAccumulatorChant;
    return !state.hasSelection && !state.isCommentaryOpen && !isGroupChant;
  }

  @override
  ConsumerState<SwipeNavigationWrapper> createState() =>
      _SwipeNavigationWrapperState();
}

class _SwipeNavigationWrapperState
    extends ConsumerState<SwipeNavigationWrapper> {
  bool _isNavigating = false;

  /// Measured on the parts themselves, which keep their size while the strip
  /// collapses in focus mode.
  double _aboveHeight = 0;
  double _barHeight = 0;

  @override
  void didUpdateWidget(covariant SwipeNavigationWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.aboveBottomBar == null && _aboveHeight != 0) {
      _aboveHeight = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reportHeight();
      });
    }
  }

  void _onAboveHeight(double height) {
    _aboveHeight = height;
    _reportHeight();
  }

  void _onBarHeight(double height) {
    _barHeight = height;
    _reportHeight();
  }

  void _reportHeight() {
    widget.onBottomBarHeight?.call(_aboveHeight + _barHeight);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerNotifierProvider(widget.params));
    final navigationContext = state.navigationContext;
    final showBottomBar = SwipeNavigationWrapper.showsBottomBar(state);

    final canSwipe = navigationContext != null && navigationContext.canSwipe;

    // The text's title as the page shows it: the translation's when one is
    // shown, else the original's in the script it is shown in.
    final language = widget.textDetail.language;
    final scope = widget.params.settingsScope;
    final scriptId = ref.watch(
      readerOriginalScriptProvider(
        ReaderScriptScope(scope: scope, language: language),
      ),
    );
    final dualSettings = ref.watch(readerDualSettingsProvider(scope));
    final translation = dualSettings.secondary;
    final translationShown =
        dualSettings.secondaryEnabled && translation.versionId != null;
    final (:title, language: titleLanguage) = readerTextTitle(
      ref.watch(transliterationServiceProvider),
      title: widget.textDetail.title,
      language: language,
      scriptId: scriptId,
      translationTitle: translationShown ? translation.versionLabel : null,
      translationLanguage: translationShown ? translation.languageCode : null,
    );

    final above = widget.aboveBottomBar;
    final stripInView = widget.isAppBarVisible;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (above != null)
                    _ReportHeight(onChange: _onAboveHeight, child: above),
                  // Focus mode: the strip slides down out of view and gives
                  // up its room, so the controls above it settle on the
                  // bottom edge. Clipped, or the hidden strip would show
                  // under the system's navigation buttons.
                  _Collapsible(
                    open: stripInView,
                    child: _ReportHeight(
                      onChange: _onBarHeight,
                      child: PlanNavigationBottomBar(
                        navigationContext: navigationContext,
                        fallbackTitle: title,
                        fallbackTitleFontFamily: getFontFamily(titleLanguage),
                        showTopBorder: above == null,
                        onPreviousTap:
                            canSwipe
                                ? () => _navigate(
                                  navigationContext,
                                  SwipeDirection.previous,
                                )
                                : null,
                        onNextTap:
                            canSwipe
                                ? () => _navigate(
                                  navigationContext,
                                  SwipeDirection.next,
                                )
                                : null,
                        onFinishedTap:
                            navigationContext != null &&
                                    (navigationContext.source ==
                                            NavigationSource.plan ||
                                        navigationContext.source ==
                                            NavigationSource
                                                .groupRecitationCollection ||
                                        navigationContext.source ==
                                            NavigationSource
                                                .myRecitationCollection)
                                ? _finishReading
                                : null,
                      ),
                    ),
                  ),
                  // The strip carried the home indicator's inset. Once it is
                  // gone, the controls above it take that inset over.
                  if (above != null && bottomInset > 0)
                    _Collapsible(
                      open: !stripInView,
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: SizedBox(height: bottomInset),
                      ),
                    ),
                ],
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

/// Shows [child] at its full height when [open], and folds it away from the
/// bottom when not, over the focus-mode animation. The child keeps its own
/// layout either way, so its measured size is the size it has when open.
class _Collapsible extends StatelessWidget {
  const _Collapsible({required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        heightFactor: open ? 1 : 0,
        duration: ReaderConstants.focusModeDuration,
        curve: ReaderConstants.focusModeCurve,
        child: IgnorePointer(ignoring: !open, child: child),
      ),
    );
  }
}

/// Tells [onChange] whenever [child] is laid out at a new height: after the
/// first frame, and again whenever its size changes, such as when the text
/// scale or the recording title changes.
class _ReportHeight extends StatefulWidget {
  const _ReportHeight({required this.onChange, required this.child});

  final ValueChanged<double> onChange;
  final Widget child;

  @override
  State<_ReportHeight> createState() => _ReportHeightState();
}

class _ReportHeightState extends State<_ReportHeight> {
  double? _height;

  @override
  void initState() {
    super.initState();
    _scheduleNotify();
  }

  @override
  void didUpdateWidget(covariant _ReportHeight oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleNotify();
  }

  void _scheduleNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  void _notify() {
    if (!mounted) return;
    final height = context.size?.height;
    if (height == null || height == _height) return;
    _height = height;
    widget.onChange(height);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        // Sent during layout, so the new size is read once the frame is out.
        _scheduleNotify();
        return true;
      },
      child: SizeChangedLayoutNotifier(child: widget.child),
    );
  }
}
