import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/scroll_controller_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Centered pill-style page indicator — active page is a wide capsule, inactive
/// pages are small circles, all inside a rounded track (see home poems section).
///
/// When [count] is large (e.g. after pagination), dots scroll horizontally
/// inside a width-capped track so the row cannot overflow the screen.
class PoemDotsIndicator extends StatefulWidget {
  const PoemDotsIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.activeColor,
    required this.inactiveColor,
    this.backgroundColor,
    this.borderColor,
  });

  final int count;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final Color? backgroundColor;
  final Color? borderColor;

  static const double dotSize = 6;
  static const double activeDotWidth = 18;
  static const double gap = 5;
  static const double horizontalPadding = 10;

  /// Horizontal margin reserved on each side of the screen for the track.
  static const double screenHorizontalMargin = 24;

  @override
  State<PoemDotsIndicator> createState() => _PoemDotsIndicatorState();
}

class _PoemDotsIndicatorState extends State<PoemDotsIndicator> {
  ScrollController? _scrollController;

  /// Set when a scroll to the current dot was requested before the dots
  /// scroll view had been laid out. Cleared by [_handleScrollMetrics].
  bool _pendingScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void didUpdateWidget(PoemDotsIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.count != widget.count) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  double _dotWidthAt(int index) {
    return index == widget.currentIndex
        ? PoemDotsIndicator.activeDotWidth
        : PoemDotsIndicator.dotSize;
  }

  double _offsetBeforeIndex(int index) {
    if (index <= 0) return 0;
    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      if (i > 0) offset += PoemDotsIndicator.gap;
      offset += _dotWidthAt(i);
    }
    return offset;
  }

  void _scrollToCurrent() {
    final controller = _scrollController;
    if (!mounted || controller == null || widget.count <= 1) return;
    if (!controller.hasLaidOutPosition) {
      // The dots can be built without being laid out in the same frame, for
      // example while their screen is still hidden. Their sizes do not exist
      // yet, so wait for the first layout instead of reading them.
      _pendingScroll = true;
      return;
    }
    _pendingScroll = false;

    final viewportWidth = controller.position.viewportDimension;
    if (viewportWidth <= 0) return;

    final dotStart = _offsetBeforeIndex(widget.currentIndex);
    final dotWidth = _dotWidthAt(widget.currentIndex);
    final target = dotStart + dotWidth / 2 - viewportWidth / 2;

    controller.animateTo(
      target.clamp(0.0, controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  /// Runs a deferred scroll once the dots have been laid out. Flutter sends
  /// this notification after a scroll view's first layout and whenever its
  /// size changes.
  bool _handleScrollMetrics(ScrollMetricsNotification notification) {
    if (_pendingScroll && notification.depth == 0) _scrollToCurrent();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 1) return const SizedBox.shrink();

    // Keeps the constraint valid when the window is narrower than the
    // margins, e.g. a zero-size window, instead of going negative.
    final maxTrackWidth = math.max(
      0.0,
      MediaQuery.sizeOf(context).width -
          PoemDotsIndicator.screenHorizontalMargin * 2,
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxTrackWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PoemDotsIndicator.horizontalPadding,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: widget.borderColor ?? AppColors.grey100),
          ),
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: _handleScrollMetrics,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.hardEdge,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < widget.count; index++) ...[
                    if (index > 0) const SizedBox(width: PoemDotsIndicator.gap),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: _dotWidthAt(index),
                      height: PoemDotsIndicator.dotSize,
                      decoration: BoxDecoration(
                        color:
                            index == widget.currentIndex
                                ? widget.activeColor
                                : widget.inactiveColor,
                        borderRadius: BorderRadius.circular(
                          PoemDotsIndicator.dotSize / 2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
