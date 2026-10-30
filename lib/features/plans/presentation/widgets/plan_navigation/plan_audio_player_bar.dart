import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_audio_progress.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_segment_audio_controller.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/playback_speed_sheet.dart';

/// Progress line, optional recording title, speed, and repeat.
///
/// Sits under the round play button on plan tasks and group recitations.
/// The line shows elapsed time only — it does not seek. [versionTitle] is the
/// recording name from the backend; plan tasks leave it null and the pill
/// stays hidden. A long title ellipsizes so speed and repeat stay visible.
/// Repeat is off until tapped: the slice plays once, then stops or advances.
/// On, it loops, and the choice carries to the next task or recording.
class PlanAudioPlayerBar extends StatefulWidget {
  const PlanAudioPlayerBar({
    super.key,
    required this.controller,
    this.versionTitle,
    this.onVersionTap,
  });

  /// Null until a group recitation has started a recording. The bar still
  /// shows, with the speed remembered for the next play.
  final PlanSegmentAudioController? controller;

  final String? versionTitle;

  /// Opens the recording list. Null leaves the pill as a label.
  final VoidCallback? onVersionTap;

  @override
  State<PlanAudioPlayerBar> createState() => _PlanAudioPlayerBarState();
}

class _PlanAudioPlayerBarState extends State<PlanAudioPlayerBar> {
  @override
  void initState() {
    super.initState();
    _bind(widget.controller);
  }

  @override
  void didUpdateWidget(covariant PlanAudioPlayerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    _unbind(oldWidget.controller);
    _bind(widget.controller);
  }

  @override
  void dispose() {
    _unbind(widget.controller);
    super.dispose();
  }

  void _bind(PlanSegmentAudioController? controller) {
    controller?.addListener(_onController);
    controller?.progress.addListener(_onProgress);
  }

  void _unbind(PlanSegmentAudioController? controller) {
    if (controller == null || controller.isDisposed) return;
    controller.removeListener(_onController);
    controller.progress.removeListener(_onProgress);
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  void _onProgress() {
    if (mounted) setState(() {});
  }

  double get _speed =>
      widget.controller?.speed ?? PlanSegmentAudioController.preferredSpeed;

  bool get _repeat =>
      widget.controller?.repeat ?? PlanSegmentAudioController.preferredRepeat;

  void _toggleRepeat() {
    final next = !_repeat;
    final controller = widget.controller;
    if (controller == null) {
      PlanSegmentAudioController.preferredRepeat = next;
      setState(() {});
      return;
    }
    controller.setRepeat(next);
  }

  Future<void> _pickSpeed() {
    return showPlaybackSpeedSheet(
      context,
      selected: _speed,
      onChanged: (speed) {
        if (!mounted) return;
        final controller = widget.controller;
        if (controller == null) {
          PlanSegmentAudioController.preferredSpeed = speed;
          setState(() {});
          return;
        }
        controller.setSpeed(speed);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.controller?.progress.value ?? PlanAudioProgress.zero;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final title = widget.versionTitle?.trim();
    final showTitle = title != null && title.isNotEmpty;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProgressRow(progress: progress, color: onSurface),
            const SizedBox(height: 8),
            Row(
              children: [
                if (showTitle)
                  Flexible(
                    child: _VersionPill(
                      title: title,
                      color: onSurface,
                      onTap: widget.onVersionTap,
                    ),
                  )
                else
                  const Spacer(),
                _SpeedButton(
                  speed: _speed,
                  color: onSurface,
                  onTap: _pickSpeed,
                ),
                _RepeatButton(
                  repeating: _repeat,
                  color: onSurface,
                  onTap: _toggleRepeat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.progress, required this.color});

  final PlanAudioProgress progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(
      TextStyle(
        color: color.withValues(alpha: 0.55),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final leading = _clock(context, progress.position);
    final trailing = _clock(context, progress.duration ?? Duration.zero);
    final direction = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final track = IgnorePointer(
          child: CustomPaint(
            painter: _TrackPainter(fraction: progress.fraction, color: color),
            child: const SizedBox(height: 16),
          ),
        );
        if (!maxWidth.isFinite) {
          return _clockRow(leading, trailing, style, track);
        }

        // Clocks do not shrink on their own. When they take the row, the
        // track is what is left — sometimes nothing. Scale them only then,
        // so a normal width still pins the duration to the trailing edge.
        const gap = 8.0;
        const minTrack = 12.0;
        final leadingWidth = _textWidth(leading, style, textScaler, direction);
        final trailingWidth = _textWidth(
          trailing,
          style,
          textScaler,
          direction,
        );
        final naturalTrack = maxWidth - leadingWidth - trailingWidth - gap * 2;
        if (naturalTrack >= minTrack) {
          return _clockRow(leading, trailing, style, track);
        }

        final gaps = maxWidth >= minTrack + gap * 2 ? gap : 0.0;
        final reservedTrack = math.min(
          minTrack,
          math.max(0.0, maxWidth - gaps * 2),
        );
        final clockBudget = maxWidth - gaps * 2 - reservedTrack;
        final clockTotal = leadingWidth + trailingWidth;
        final leadingSlot =
            clockTotal <= 0
                ? clockBudget / 2
                : clockBudget * leadingWidth / clockTotal;
        final trailingSlot = clockBudget - leadingSlot;

        return Row(
          children: [
            if (leadingSlot > 0)
              SizedBox(
                width: leadingSlot,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(leading, style: style, maxLines: 1),
                ),
              ),
            if (gaps > 0) SizedBox(width: gaps),
            Expanded(child: track),
            if (gaps > 0) SizedBox(width: gaps),
            if (trailingSlot > 0)
              SizedBox(
                width: trailingSlot,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(trailing, style: style, maxLines: 1),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _clockRow(
    String leading,
    String trailing,
    TextStyle style,
    Widget track,
  ) {
    return Row(
      children: [
        Text(leading, style: style),
        const SizedBox(width: 8),
        Expanded(child: track),
        const SizedBox(width: 8),
        Text(trailing, style: style),
      ],
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    const trackHeight = 3.0;
    const thumbRadius = 6.0;
    final y = size.height / 2;
    // clamp(radius, width) throws once the track is narrower than the thumb.
    // Long clocks and large text can leave only that sliver, so fit the
    // thumb to the width before drawing.
    final radius = size.width < thumbRadius * 2 ? size.width / 2 : thumbRadius;
    final start = radius;
    final end = size.width - radius;
    final dx = start + (end - start) * fraction.clamp(0.0, 1.0);

    final track =
        Paint()
          ..color = color.withValues(alpha: 0.18)
          ..strokeWidth = trackHeight
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(start, y), Offset(end, y), track);

    final played =
        Paint()
          ..color = color
          ..strokeWidth = trackHeight
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(start, y), Offset(dx, y), played);
    canvas.drawCircle(Offset(dx, y), radius, played);
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({
    required this.title,
    required this.color,
    required this.onTap,
  });

  final String title;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap:
              onTap == null
                  ? null
                  : () {
                    HapticFeedback.lightImpact();
                    onTap!();
                  },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppAssets.speakerSimpleHigh, size: 16, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(AppAssets.caretUp, size: 14, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({
    required this.speed,
    required this.color,
    required this.onTap,
  });

  final double speed;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          _clockLabel(context, formatPlaybackSpeed(speed)),
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  const _RepeatButton({
    required this.repeating,
    required this.color,
    required this.onTap,
  });

  final bool repeating;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = repeating ? Theme.of(context).colorScheme.surface : color;
    final icon = Icon(AppAssets.repeat, size: 16, color: iconColor);

    return Semantics(
      button: true,
      toggled: repeating,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child:
                repeating
                    ? Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: icon,
                    )
                    : icon,
          ),
        ),
      ),
    );
  }
}

String _clock(BuildContext context, Duration duration) {
  return _clockLabel(context, formatPlanAudioClock(duration));
}

double _textWidth(
  String text,
  TextStyle style,
  TextScaler textScaler,
  TextDirection direction,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: direction,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

String _clockLabel(BuildContext context, String label) {
  return context.isTibetanLocale ? toTibetanDigits(label) : label;
}
