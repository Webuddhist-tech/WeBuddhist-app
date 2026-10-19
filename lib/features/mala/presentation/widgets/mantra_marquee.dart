import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// One line of text that always scrolls horizontally (right to left), short
/// or long, with a copy following after [gap] so the loop never shows a seam.
///
/// The line stays still when the system asks for reduced motion
/// ([MediaQuery.disableAnimationsOf]): centred if it fits, otherwise clipped,
/// and the parent's tap-to-open-in-full shows the rest.
///
/// Speed is [basePixelsPerSecond] × [speedFactor]; changing the factor keeps
/// the current offset so the text never jumps. Nothing is interactive here:
/// wrap it in a gesture detector when a tap should open the full text.
class MantraMarquee extends StatefulWidget {
  const MantraMarquee({
    super.key,
    required this.text,
    required this.style,
    this.speedFactor = 1.0,
    this.basePixelsPerSecond = 40,
    this.gap = 28,
  });

  final String text;
  final TextStyle style;
  final double speedFactor;
  final double basePixelsPerSecond;
  final double gap;

  @override
  State<MantraMarquee> createState() => _MantraMarqueeState();
}

class _MantraMarqueeState extends State<MantraMarquee>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);
  Duration _lastTick = Duration.zero;
  TextPainter? _painter;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _layout();
  }

  @override
  void didUpdateWidget(covariant MantraMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text || widget.style != oldWidget.style) {
      _layout();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _offset.dispose();
    _painter?.dispose();
    super.dispose();
  }

  void _layout() {
    _painter?.dispose();
    _painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
  }

  /// Starts or stops the ticker. Called while laying out, which is safe: a
  /// ticker only schedules a frame callback, it does not mark anything dirty.
  void _setScrolling(bool scrolling) {
    if (scrolling == _ticker.isActive) return;
    if (scrolling) {
      // A restarted ticker counts elapsed time from zero again.
      _lastTick = Duration.zero;
      _ticker.start();
    } else {
      _ticker.stop();
      _offset.value = 0;
    }
  }

  void _onTick(Duration elapsed) {
    var dt = elapsed - _lastTick;
    _lastTick = elapsed;
    // After a muted stretch (TickerMode) a large dt would jump the text.
    if (dt > const Duration(milliseconds: 100)) {
      dt = const Duration(milliseconds: 16);
    }
    final speed = widget.basePixelsPerSecond * widget.speedFactor;
    _offset.value += speed * dt.inMicroseconds / Duration.microsecondsPerSecond;
  }

  @override
  Widget build(BuildContext context) {
    final painter = _painter;
    if (painter == null || widget.text.isEmpty) {
      _setScrolling(false);
      return const SizedBox.shrink();
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: SizedBox(
        height: painter.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scrolling = !reduceMotion;
            _setScrolling(scrolling);
            return ClipRect(
              child: CustomPaint(
                size: Size(constraints.maxWidth, painter.height),
                painter: _MarqueePainter(
                  textPainter: painter,
                  offset: _offset,
                  gap: widget.gap,
                  scrolling: scrolling,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MarqueePainter extends CustomPainter {
  _MarqueePainter({
    required this.textPainter,
    required this.offset,
    required this.gap,
    required this.scrolling,
  }) : super(repaint: offset);

  final TextPainter textPainter;
  final ValueListenable<double> offset;
  final double gap;
  final bool scrolling;

  @override
  void paint(Canvas canvas, Size size) {
    if (!scrolling) {
      // Centred when it fits; start-aligned (and clipped) when it does not.
      final x = (size.width - textPainter.width).clamp(0.0, double.infinity);
      textPainter.paint(canvas, Offset(x / 2, 0));
      return;
    }
    final period = textPainter.width + gap;
    if (period <= 0) return;
    var x = -(offset.value % period);
    while (x < size.width) {
      textPainter.paint(canvas, Offset(x, 0));
      x += period;
    }
  }

  @override
  bool shouldRepaint(covariant _MarqueePainter old) =>
      old.textPainter != textPainter ||
      old.gap != gap ||
      old.offset != offset ||
      old.scrolling != scrolling;
}
