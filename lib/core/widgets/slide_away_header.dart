import 'package:flutter/material.dart';

/// Slides [child] up off the top edge when [visible] is false, like a
/// hide-on-scroll toolbar. The child stays mounted while hidden.
class SlideAwayHeader extends StatefulWidget {
  final bool visible;
  final Duration duration;
  final Widget child;

  const SlideAwayHeader({
    super.key,
    required this.visible,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<SlideAwayHeader> createState() => _SlideAwayHeaderState();
}

class _SlideAwayHeaderState extends State<SlideAwayHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.visible ? 1 : 0,
  );
  late final CurvedAnimation _height = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void didUpdateWidget(SlideAwayHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _height.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bottom-aligned so the header's top edge is what scrolls out of view.
    return ClipRect(
      child: AnimatedBuilder(
        animation: _height,
        builder:
            (context, child) => Align(
              alignment: Alignment.bottomCenter,
              heightFactor: _height.value,
              child: child,
            ),
        child: widget.child,
      ),
    );
  }
}
