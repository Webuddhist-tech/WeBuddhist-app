import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_audio_progress.dart';

/// Playback speed sheet. Changes apply immediately and the sheet stays open
/// until it is dismissed.
Future<void> showPlaybackSpeedSheet(
  BuildContext context, {
  required double selected,
  required ValueChanged<double> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder:
        (context) =>
            _PlaybackSpeedSheet(selected: selected, onChanged: onChanged),
  );
}

class _PlaybackSpeedSheet extends StatefulWidget {
  const _PlaybackSpeedSheet({required this.selected, required this.onChanged});

  final double selected;
  final ValueChanged<double> onChanged;

  @override
  State<_PlaybackSpeedSheet> createState() => _PlaybackSpeedSheetState();
}

class _PlaybackSpeedSheetState extends State<_PlaybackSpeedSheet> {
  static const _min = 0.5;
  static const _max = 1.5;
  static const _step = 0.01;
  static const _speedColor = Color(0xFFAD2424);

  late double _speed;

  @override
  void initState() {
    super.initState();
    _speed = _snap(widget.selected);
    if ((_speed - widget.selected).abs() > 0.001) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onChanged(_speed);
      });
    }
  }

  double _snap(double speed) {
    final clamped = speed.clamp(_min, _max);
    return (clamped * 100).round() / 100;
  }

  void _set(double speed, {bool haptic = false}) {
    final next = _snap(speed);
    if ((next - _speed).abs() < 0.001) return;
    if (haptic) HapticFeedback.lightImpact();
    setState(() => _speed = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final track = isDark ? AppColors.grey800 : AppColors.grey300;
    final thumb = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sheetColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.goldLight;

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.playback_speed,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppAssets.x, size: 22),
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _digits(context, '${_speed.toStringAsFixed(2)}x'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _speedColor,
                height: 1.1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(AppAssets.minus, size: 22),
                    onPressed:
                        _speed > _min + 0.001
                            ? () => _set(_speed - _step, haptic: true)
                            : null,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: track,
                        inactiveTrackColor: track,
                        thumbColor: thumb,
                        overlayColor: thumb.withValues(alpha: 0.12),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                        trackShape: const RoundedRectSliderTrackShape(),
                      ),
                      child: Slider(
                        value: _speed,
                        min: _min,
                        max: _max,
                        divisions: ((_max - _min) / _step).round(),
                        onChanged: _set,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppAssets.plus, size: 22),
                    onPressed:
                        _speed < _max - 0.001
                            ? () => _set(_speed + _step, haptic: true)
                            : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final preset in planPlaybackSpeeds)
                    Expanded(
                      child: _SpeedChip(
                        label: _digits(context, _presetLabel(preset)),
                        caption: preset == 1.0 ? l10n.mala_speed_normal : null,
                        selected: (_speed - preset).abs() < 0.001,
                        onTap: () => _set(preset, haptic: true),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// `0.5`, `1.0`, `1.25` — a trailing zero after the tenths place is dropped.
String _presetLabel(double preset) {
  final text = preset.toStringAsFixed(2);
  return text.endsWith('0') ? text.substring(0, text.length - 1) : text;
}

String _digits(BuildContext context, String text) =>
    context.isTibetanLocale ? toTibetanDigits(text) : text;

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.caption,
  });

  final String label;
  final String? caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final fill =
        selected
            ? (isDark ? AppColors.textPrimaryDark : Colors.black)
            : (isDark ? AppColors.surfaceDark : AppColors.surfaceWhite);
    final foreground =
        selected ? (isDark ? AppColors.textPrimary : Colors.white) : onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: fill,
          shape: StadiumBorder(
            side: BorderSide(
              color:
                  selected
                      ? Colors.transparent
                      : (isDark ? AppColors.cardBorderDark : AppColors.grey300),
            ),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minWidth: 44),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
              alignment: Alignment.center,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(
            caption!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurface.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
