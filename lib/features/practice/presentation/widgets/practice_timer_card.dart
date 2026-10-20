import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';

class PracticeTimerCard extends StatelessWidget {
  const PracticeTimerCard({
    super.key,
    required this.timer,
    required this.minLabel,
    required this.onTap,
  });

  final PresetTimer timer;
  final String minLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTibetan = AppFontConfig.isTibetanLanguage(
      Localizations.localeOf(context).languageCode,
    );
    final textColor = Theme.of(context).colorScheme.onSurface;

    final minuteText = Text(
      '${timer.displayValue}',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: isTibetan ? AppFontConfig.tibetanCompactLineHeight : 1,
        leadingDistribution:
            isTibetan ? AppFontConfig.tibetanLeadingDistribution : null,
        color: textColor,
      ),
    );

    final minLabelText = Text(
      timer.displaysSeconds ? context.l10n.timer_duration_sec : minLabel,
      style: TextStyle(fontSize: 14, color: textColor),
    );

    return Material(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                isTibetan
                    ? [minLabelText, const SizedBox(height: 2), minuteText]
                    : [minuteText, const SizedBox(height: 2), minLabelText],
          ),
        ),
      ),
    );
  }
}
