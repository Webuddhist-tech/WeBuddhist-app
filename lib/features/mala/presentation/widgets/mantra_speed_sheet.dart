import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nested sheet from the mala settings: picks the mantra marquee speed with a
/// slider, ± steps, and preset chips. Writes straight to [malaSettingsProvider].
class MantraSpeedSheet extends ConsumerWidget {
  const MantraSpeedSheet({super.key});

  static const presets = [0.5, 0.75, 1.0, 1.5, 2.0];
  static const _step = 0.05;
  static const _accent = Color(0xFFB03027);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const MantraSpeedSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final speed = ref.watch(malaSettingsProvider.select((s) => s.mantraSpeed));
    final notifier = ref.read(malaSettingsProvider.notifier);
    final onSurface = theme.colorScheme.onSurface;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final valueLabel = _digits(context, '${speed.toStringAsFixed(2)}x');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.goldLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.mala_mantra_speed,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppAssets.x, size: 24),
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 20),
            Text(
              valueLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(AppAssets.minus, size: 24),
                    onPressed:
                        speed > kMalaMantraSpeedMin
                            ? () => notifier.setMantraSpeed(speed - _step)
                            : null,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: _accent,
                        inactiveTrackColor: onSurface.withValues(alpha: 0.12),
                        thumbColor: _accent,
                        overlayColor: _accent.withValues(alpha: 0.12),
                      ),
                      child: Slider(
                        value: speed,
                        min: kMalaMantraSpeedMin,
                        max: kMalaMantraSpeedMax,
                        divisions:
                            ((kMalaMantraSpeedMax - kMalaMantraSpeedMin) /
                                    _step)
                                .round(),
                        onChanged: notifier.setMantraSpeed,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppAssets.plus, size: 24),
                    onPressed:
                        speed < kMalaMantraSpeedMax
                            ? () => notifier.setMantraSpeed(speed + _step)
                            : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final preset in presets)
                    _SpeedChip(
                      label: _digits(context, _presetLabel(preset)),
                      caption:
                          preset == kMalaMantraSpeedDefault
                              ? l10n.mala_speed_normal
                              : null,
                      selected: (speed - preset).abs() < 0.001,
                      onTap: () => notifier.setMantraSpeed(preset),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static String _presetLabel(double preset) {
    final text = preset.toStringAsFixed(2);
    return text.endsWith('0') ? text.substring(0, text.length - 1) : text;
  }

  static String _digits(BuildContext context, String text) =>
      context.isTibetanLocale ? toTibetanDigits(text) : text;
}

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
              constraints: const BoxConstraints(minWidth: 56),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              alignment: Alignment.center,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
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
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}
