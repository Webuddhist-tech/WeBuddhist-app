import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';

class PresetTimerCard extends StatelessWidget {
  const PresetTimerCard({
    super.key,
    required this.timer,
    required this.minLabel,
    this.ambientSoundName,
    this.onTap,
    this.onMoreTap,
  });

  final PresetTimer timer;
  final String minLabel;
  final String? ambientSoundName;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  static const _borderRadius = 16.0;
  static const _contentPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
  static const _labelSpacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isTibetan = AppFontConfig.isTibetanLanguage(
      Localizations.localeOf(context).languageCode,
    );

    final minuteText = Text(
      '${timer.displayMinutes}',
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        height: isTibetan ? AppFontConfig.tibetanCompactLineHeight : null,
        leadingDistribution:
            isTibetan ? AppFontConfig.tibetanLeadingDistribution : null,
        color: textColor,
      ),
    );

    final minLabelText = Text(
      minLabel,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: isTibetan ? AppFontConfig.tibetanCompactLineHeight : 1.2,
        leadingDistribution:
            isTibetan ? AppFontConfig.tibetanLeadingDistribution : null,
        color: textColor,
      ),
    );

    final showAmbientSound =
        timer.ambientSoundId != null && ambientSoundName != null;

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: _contentPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        isTibetan
                            ? [
                              minLabelText,
                              const SizedBox(height: _labelSpacing),
                              minuteText,
                              if (showAmbientSound) ...[
                                const SizedBox(height: _labelSpacing),
                                _AmbientSoundRow(label: ambientSoundName!),
                              ],
                            ]
                            : [
                              minuteText,
                              const SizedBox(height: _labelSpacing),
                              minLabelText,
                              if (showAmbientSound) ...[
                                const SizedBox(height: _labelSpacing),
                                _AmbientSoundRow(label: ambientSoundName!),
                              ],
                            ],
                  ),
                ),
              ),
              if (onMoreTap != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: textColor,
                      size: 20,
                    ),
                    onPressed: onMoreTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientSoundRow extends StatelessWidget {
  const _AmbientSoundRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppAssets.timerAmbientSound, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
      ],
    );
  }
}
