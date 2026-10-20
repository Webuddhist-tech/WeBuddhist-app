import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';

/// One timer in the presets / your-timers list: duration, sound, play, and
/// the ⋮ menu.
class PresetTimerCard extends StatelessWidget {
  const PresetTimerCard({
    super.key,
    required this.timer,
    required this.minLabel,
    this.soundLabel,
    this.onPlay,
    this.onMoreTap,
  });

  final PresetTimer timer;
  final String minLabel;

  /// Ambient sound name, or the "no sound" label. Null while a sound id is
  /// set but its name has not loaded yet.
  final String? soundLabel;
  final VoidCallback? onPlay;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = textColor.withValues(alpha: 0.55);
    final isTibetan = AppFontConfig.isTibetanLanguage(
      Localizations.localeOf(context).languageCode,
    );

    final minuteStyle = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: isTibetan ? AppFontConfig.tibetanCompactLineHeight : 1,
      leadingDistribution:
          isTibetan ? AppFontConfig.tibetanLeadingDistribution : null,
      color: textColor,
    );
    final unitStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      height: isTibetan ? AppFontConfig.tibetanCompactLineHeight : 1,
      leadingDistribution:
          isTibetan ? AppFontConfig.tibetanLeadingDistribution : null,
      color: textColor,
    );

    final minutes = TextSpan(
      text: '${timer.displayMinutes}',
      style: minuteStyle,
    );
    final unit = TextSpan(text: minLabel, style: unitStyle);
    final gap = const TextSpan(text: ' ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children:
                        isTibetan ? [unit, gap, minutes] : [minutes, gap, unit],
                  ),
                ),
                if (soundLabel != null) ...[
                  const SizedBox(height: 4),
                  _SoundLabel(label: soundLabel!, color: mutedColor),
                ],
              ],
            ),
          ),
          if (onMoreTap != null)
            IconButton(
              icon: Icon(
                AppAssets.dotsThreeVertical,
                color: textColor,
                size: 22,
              ),
              onPressed: onMoreTap,
            ),
          _PlayButton(isDark: isDark, onPressed: onPlay),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _SoundLabel extends StatelessWidget {
  const _SoundLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(AppAssets.timerAmbientSound, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: color),
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.isDark, this.onPressed});

  final bool isDark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final background = isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final iconColor = isDark ? AppColors.textPrimary : AppColors.onPrimary;

    return Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(AppAssets.play, size: 18, color: iconColor),
        ),
      ),
    );
  }
}
