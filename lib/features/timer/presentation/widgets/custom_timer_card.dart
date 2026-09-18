import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';

/// The dashed "+ Custom timer" card shown in "Your timers" until the user
/// creates their first custom timer (after which the pill FAB takes over).
///
/// Matches [PresetTimerCard]'s square footprint but uses a dashed border to
/// read as an "add" affordance rather than an existing timer.
class CustomTimerCard extends StatelessWidget {
  const CustomTimerCard({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  static const _borderRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final mutedColor = color.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _DashedRoundedBorderPainter(
              color: mutedColor,
              radius: _borderRadius,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppAssets.plus, size: 28, color: mutedColor),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: mutedColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const _strokeWidth = 1.5;
  static const _dashWidth = 6.0;
  static const _dashSpace = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _strokeWidth / 2,
        _strokeWidth / 2,
        size.width - _strokeWidth,
        size.height - _strokeWidth,
      ),
      Radius.circular(radius),
    );

    canvas.drawPath(_dashPath(Path()..addRRect(rRect)), paint);
  }

  Path _dashPath(Path source) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        dest.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + _dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
