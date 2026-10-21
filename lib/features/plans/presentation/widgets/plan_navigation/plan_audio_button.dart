import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_segment_audio_controller.dart';

/// Floating play / pause / loading button for plan subtask audio.
///
/// Driven by a [PlanSegmentAudioController]: it rebuilds on button-state
/// changes and morphs between the play ▶ and pause ⏸ icons. Drop it into a
/// [Stack] / [Positioned] overlay on any screen that plays plan audio.
class PlanAudioButton extends StatefulWidget {
  const PlanAudioButton({super.key, required this.controller});

  final PlanSegmentAudioController controller;

  @override
  State<PlanAudioButton> createState() => _PlanAudioButtonState();
}

class _PlanAudioButtonState extends State<PlanAudioButton>
    with SingleTickerProviderStateMixin {
  /// Drives the play↔pause icon morph. At 0.0 = play ▶, at 1.0 = pause ⏸.
  late final AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.controller.buttonState == PlanAudioButtonState.pause
          ? 1.0
          : 0.0,
    );
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant PlanAudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The reader swaps controllers when the user picks another recording.
    // Follow the new one, or the button never hears it start playing.
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_onControllerChanged);
    widget.controller.addListener(_onControllerChanged);
    _iconController.value =
        widget.controller.buttonState == PlanAudioButtonState.pause ? 1.0 : 0.0;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _iconController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    // Keep the icon morph in sync with the play/pause state.
    if (widget.controller.buttonState == PlanAudioButtonState.pause) {
      _iconController.forward();
    } else {
      _iconController.reverse();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final isLoading =
        widget.controller.buttonState == PlanAudioButtonState.loading;

    return Material(
      color: bgColor.withAlpha(235),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black38,
      child: InkWell(
        onTap: isLoading ? null : widget.controller.toggle,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withAlpha(100), width: 1.5),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: color,
                  ),
                )
              : AnimatedIcon(
                  icon: AnimatedIcons.play_pause,
                  progress: _iconController,
                  size: 28,
                  color: color,
                ),
        ),
      ),
    );
  }
}
