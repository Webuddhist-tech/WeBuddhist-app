import 'package:flutter/material.dart';

/// Animated pill toggle that matches the app's custom design language.
///
/// Defaults to a blue/grey pill with a white thumb, consistent with the
/// "Show Second Version" toggle in the reader settings. Callers may override
/// [thumbOnColor] and [thumbOffColor] to achieve alternate thumb colours
/// (e.g. the theme-toggle uses grey/white thumb colours).
class AppToggleSwitch extends StatelessWidget {
  const AppToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.thumbOnColor = Colors.white,
    this.thumbOffColor = Colors.white,
    this.trackOnColor = _trackOnColor,
    this.trackOffColor = _trackOffColor,
    this.width = 64,
    this.height = 32,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color thumbOnColor;
  final Color thumbOffColor;
  final Color trackOnColor;
  final Color trackOffColor;

  /// The track's size; the thumb fills its height less 2 on each side.
  final double width;
  final double height;

  static const Color _trackOnColor = Color(0xFF196BF1);
  static const Color _trackOffColor = Color(0xFFADADAD);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: value ? trackOnColor : trackOffColor,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: height - 4,
            height: height - 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? thumbOnColor : thumbOffColor,
            ),
          ),
        ),
      ),
    );
  }
}
