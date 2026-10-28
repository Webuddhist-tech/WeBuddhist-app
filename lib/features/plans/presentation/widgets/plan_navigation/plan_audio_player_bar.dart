import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_audio_progress.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_segment_audio_controller.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/playback_speed_sheet.dart';

/// Progress line, optional recording title, and speed control.
///
/// Sits under the round play button on plan tasks and group recitations.
/// The line shows elapsed time only — it does not seek. [versionTitle] is the
/// recording name from the backend; plan tasks leave it null and the pill
/// stays hidden. A long title ellipsizes so the speed control stays visible.
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

  Future<void> _pickSpeed() async {
    final picked = await showPlaybackSpeedSheet(context, selected: _speed);
    if (!mounted || picked == null) return;
    final controller = widget.controller;
    if (controller == null) {
      PlanSegmentAudioController.preferredSpeed = picked;
      setState(() {});
      return;
    }
    await controller.setSpeed(picked);
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
    final style = TextStyle(
      color: color.withValues(alpha: 0.55),
      fontSize: 12,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Row(
      children: [
        Text(_clock(context, progress.position), style: style),
        const SizedBox(width: 8),
        Expanded(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TrackPainter(fraction: progress.fraction, color: color),
              child: const SizedBox(height: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(_clock(context, progress.duration ?? Duration.zero), style: style),
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
    const trackHeight = 3.0;
    const thumbRadius = 6.0;
    final y = size.height / 2;
    final start = thumbRadius;
    final end = (size.width - thumbRadius).clamp(start, size.width);
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
    canvas.drawCircle(Offset(dx, y), thumbRadius, played);
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

String _clock(BuildContext context, Duration duration) {
  return _clockLabel(context, formatPlanAudioClock(duration));
}

String _clockLabel(BuildContext context, String label) {
  return context.isTibetanLocale ? toTibetanDigits(label) : label;
}
