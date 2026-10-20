import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/widgets/dashed_rounded_border_painter.dart';

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
            painter: DashedRoundedBorderPainter(
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
