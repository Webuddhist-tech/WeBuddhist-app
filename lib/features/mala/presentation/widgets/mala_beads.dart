import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A tappable strand of prayer beads that advances **forward only**.
///
/// The strand bends from the top-right down to the bottom-left along a red
/// thread, with one fixed gap (the counting point, right-of-centre) where the
/// thread shows through. The whole region is tappable
/// (`HitTestBehavior.opaque`). Each increment slides the strand one bead from
/// **right to left**: the front bead on the right crosses the gap to join the
/// left pile and a new bead enters from the top-right. Counting is monotonic,
/// so the motion never reverses.
///
/// Beads render [beadImageBytes] when present; a drawn gradient bead shows
/// while bytes are downloading or when unavailable.
class MalaBeads extends StatefulWidget {
  const MalaBeads({
    super.key,
    required this.total,
    required this.beadInRound,
    required this.beadsPerRound,
    required this.onTap,
    this.onSwipe,
    required this.beadColor,
    required this.threadColor,
    this.enabled = true,
    this.beadImageBytes,
  });

  /// Absolute lifetime count — drives continuous forward motion (no wrap jump).
  final int total;
  final int beadInRound;
  final int beadsPerRound;
  final VoidCallback onTap;

  /// Called instead of [onTap] for a leftward swipe or fling, when set.
  final VoidCallback? onSwipe;
  final Color beadColor;
  final Color threadColor;
  final bool enabled;
  final Uint8List? beadImageBytes;

  @override
  State<MalaBeads> createState() => _MalaBeadsState();
}

class _MalaBeadsState extends State<MalaBeads>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late double _phaseFrom;
  late double _phaseTo;

  ui.Image? _beadImage;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  @override
  void initState() {
    super.initState();
    _phaseFrom = widget.total.toDouble();
    _phaseTo = widget.total.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _resolveBeadImage();
  }

  @override
  void didUpdateWidget(covariant MalaBeads oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.beadImageBytes != oldWidget.beadImageBytes) {
      _resolveBeadImage();
    }
    if (widget.total != oldWidget.total) {
      if (widget.total == oldWidget.total + 1) {
        // A genuine +1 count — slide one bead from the previously settled phase.
        _phaseFrom = _phaseTo;
        _phaseTo = widget.total.toDouble();
        _controller.forward(from: 0); // never reverse()
      } else {
        // Any other jump (switching mantra, or the initial seed load) is not a
        // count — snap straight to the new total without the slide animation.
        _phaseFrom = _phaseTo = widget.total.toDouble();
        _controller.value = 1.0;
      }
    }
  }

  /// Renders Hive-backed bytes only. Network fetch (with presigned URL refresh)
  /// is handled by [MalaCounterNotifier]; until bytes arrive, draw the gradient bead.
  void _resolveBeadImage() {
    final bytes = widget.beadImageBytes;
    if (bytes != null && bytes.isNotEmpty) {
      _resolveImageProvider(MemoryImage(bytes));
      return;
    }

    _detachImageListener();
    _imageStream = null;
    if (_beadImage != null && mounted) setState(() => _beadImage = null);
  }

  void _resolveImageProvider(ImageProvider provider) {
    final stream = provider.resolve(ImageConfiguration.empty);
    if (stream.key == _imageStream?.key) return;

    _detachImageListener();
    final listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() => _beadImage = info.image);
      },
      onError: (_, __) {
        // Network image failed — fall back to the drawn gradient bead.
        if (mounted) setState(() => _beadImage = null);
      },
    );
    _imageStream = stream;
    _imageListener = listener;
    stream.addListener(listener);
  }

  void _detachImageListener() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageListener = null;
  }

  @override
  void dispose() {
    _detachImageListener();
    _controller.dispose();
    super.dispose();
  }

  /// Net horizontal drag distance of the in-progress gesture (negative = left).
  double _dragDx = 0;

  /// A drag this far left (px), or a leftward fling this fast (px/s), counts as
  /// one bead — matching the right→left motion of the strand.
  static const double _kSwipeDistance = 24;
  static const double _kFlingVelocity = 200;

  void _handleTap() {
    if (widget.enabled) widget.onTap();
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    // Right → left only (monotonic: a left → right swipe never decrements).
    final leftward =
        _dragDx <= -_kSwipeDistance || velocity <= -_kFlingVelocity;
    // One +1 per swipe, same as a tap.
    if (leftward && widget.enabled) (widget.onSwipe ?? widget.onTap)();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onHorizontalDragStart: (_) => _dragDx = 0,
      onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
      onHorizontalDragEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final curved = Curves.easeOut.transform(_controller.value);
          final phase = _phaseFrom + (_phaseTo - _phaseFrom) * curved;
          return CustomPaint(
            size: Size.infinite,
            painter: _MalaBeadsPainter(
              phase: phase,
              beadColor: widget.beadColor,
              threadColor: widget.threadColor,
              beadImage: _beadImage,
            ),
          );
        },
      ),
    );
  }
}

class _MalaBeadsPainter extends CustomPainter {
  _MalaBeadsPainter({
    required this.phase,
    required this.beadColor,
    required this.threadColor,
    this.beadImage,
  });

  /// Continuous slot position (the absolute count, eased).
  final double phase;
  final Color beadColor;
  final Color threadColor;

  /// Bead artwork (network or bundled asset). Null while loading.
  final ui.Image? beadImage;

  /// Candidate beads laid out along the strand; off-strand ones are skipped and
  /// any overflow past the edges is clipped.
  static const int _from = -9;
  static const int _to = 9;

  /// Arc position (0..1) of the gap's left edge — keeps the gap right-of-centre.
  static const double _focalT = 0.56;

  /// Bead radius as a fraction of the available width.
  static const double _radiusFactor = 0.075;

  /// Centre-to-centre spacing as a multiple of the radius (≈ touching).
  static const double _spacingFactor = 2.0;

  /// Extra empty bead-steps of thread at the single gap.
  static const double _gap = 1.0;

  static double _smoothstep(double x) {
    final t = x.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cut any overflow at the edges, like the design (no overlap-clustering).
    // canvas.clipRect(Offset.zero & size);

    // Strand sweeps from bottom-left (t=0) up to top-right (t=1). The control
    // point sits above the chord so the arc bows *outward* (convex toward the
    // bottom-right), matching the design — flat near the top-right, steepening
    // toward the bottom-left.
    final a = Offset(w * -0.06, h * 0.88); // bottom-left, off-screen
    final c = Offset(w * 0.40, h * 0.40); // control (outward bow)
    final b = Offset(w * 1.06, h * 0.34); // top-right, off-screen

    Offset bezier(double t) {
      final mt = 1 - t;
      return Offset(
        mt * mt * a.dx + 2 * mt * t * c.dx + t * t * b.dx,
        mt * mt * a.dy + 2 * mt * t * c.dy + t * t * b.dy,
      );
    }

    // Red mala thread.
    final threadPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = threadColor.withValues(alpha: 0.9)
          ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy),
      threadPaint,
    );

    // Arc-length table over an extended range. A Bézier isn't uniform in t, so
    // stepping beads in t bunches them where the curve is "slow" (the ends).
    // Spacing by arc length instead keeps even on-screen gaps, and the extended
    // range lets beads fill out to (and past) the clipped edges.
    const int samples = 240;
    const double tMin = -0.4;
    const double tMax = 1.4;
    final ts = List<double>.filled(samples + 1, 0);
    final cum = List<double>.filled(samples + 1, 0);
    var prev = bezier(tMin);
    var len = 0.0;
    ts[0] = tMin;
    for (var k = 1; k <= samples; k++) {
      final t = tMin + (tMax - tMin) * k / samples;
      final pt = bezier(t);
      len += (pt - prev).distance;
      ts[k] = t;
      cum[k] = len;
      prev = pt;
    }
    final totalLen = len;

    // Binary-search the table to convert between arc length and t.
    double tAtLength(double s) {
      if (s <= 0) return tMin;
      if (s >= totalLen) return tMax;
      var lo = 0, hi = samples;
      while (lo + 1 < hi) {
        final mid = (lo + hi) >> 1;
        if (cum[mid] <= s) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      final span = cum[hi] - cum[lo];
      final f = span <= 0 ? 0.0 : (s - cum[lo]) / span;
      return ts[lo] + (ts[hi] - ts[lo]) * f;
    }

    double lengthAtT(double t) {
      final f = ((t - tMin) / (tMax - tMin) * samples).clamp(
        0.0,
        samples * 1.0,
      );
      final lo = f.floor();
      final hi = (lo + 1).clamp(0, samples);
      return cum[lo] + (cum[hi] - cum[lo]) * (f - lo);
    }

    final radius = w * _radiusFactor;
    final spacing = radius * _spacingFactor;
    final sFocal = lengthAtT(_focalT);
    final frac =
        phase - phase.floorToDouble(); // continuous slide within a step

    // Draw right (far, top) first so left (near, bottom) beads layer on top.
    for (var i = _to; i >= _from; i--) {
      // Slot slides left as [frac] grows → right-to-left motion, forward only.
      final slot = i - frac;
      // Insert one gap right of slot 0: beads at slot>=1 sit a full [_gap] to
      // the right; a crossing bead (0<slot<1) glides smoothly through it.
      final p = slot + _gap * _smoothstep(slot);
      final s = sFocal + p * spacing;
      if (s < -spacing || s > totalLen + spacing) continue;

      _drawBead(canvas, bezier(tAtLength(s)), radius);
    }
  }

  void _drawBead(Canvas canvas, Offset center, double radius) {
    // Drop shadow.
    canvas.drawCircle(
      center.translate(0, radius * 0.18),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final image = beadImage;
    if (image != null) {
      _drawBeadImage(canvas, image, center, radius);
    } else {
      _drawDrawnBead(canvas, center, radius);
    }
  }

  void _drawBeadImage(
    Canvas canvas,
    ui.Image image,
    Offset center,
    double radius,
  ) {
    final dst = Rect.fromCircle(center: center, radius: radius);
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(dst));
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  /// Gradient fallback bead — shown while the image loads, and whenever there
  /// is no bead image (no URL / load failed).
  void _drawDrawnBead(Canvas canvas, Offset center, double radius) {
    final base = beadColor;
    final gradient = RadialGradient(
      center: const Alignment(-0.4, -0.5),
      colors: [
        Color.lerp(base, Colors.white, 0.45)!,
        base,
        Color.lerp(base, Colors.black, 0.30)!,
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = gradient.createShader(rect),
    );
    canvas.drawCircle(
      center.translate(-radius * 0.32, -radius * 0.38),
      radius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _MalaBeadsPainter old) =>
      old.phase != phase ||
      old.beadColor != beadColor ||
      old.threadColor != threadColor ||
      old.beadImage != beadImage;
}
