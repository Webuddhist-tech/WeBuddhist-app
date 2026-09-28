import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Small pill shown above the verse-of-the-day card when a festival or
/// observance is happening today. A pulsing red dot marks it as live.
class TodayEventBadge extends StatelessWidget {
  const TodayEventBadge({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  static String formatEventName(String name) {
    return name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(20);
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LiveDot(),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    formatEventName(label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  static const _dotSize = 8.0;
  static const _liveRed = Color(0xFFE53935);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _dotSize * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: _dotSize * (1 + t),
                height: _dotSize * (1 + t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _liveRed.withValues(alpha: 0.4 * (1 - t)),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: _dotSize,
          height: _dotSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _liveRed,
          ),
        ),
      ),
    );
  }
}
