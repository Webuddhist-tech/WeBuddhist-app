import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';

/// `#RRGGBB` or `#AARRGGBB` (hash optional) to a [Color]; null when malformed.
Color? parsePrayerIntentionColor(String? hex) {
  final raw = hex?.trim().replaceFirst('#', '') ?? '';
  if (raw.length != 6 && raw.length != 8) return null;
  final value = int.tryParse(raw, radix: 16);
  if (value == null) return null;
  return Color(raw.length == 6 ? 0xFF000000 | value : value);
}

/// The intention's base colour, or the neutral chat accent when unset.
Color prayerIntentionColor(ChatPrayerIntentionDTO? intention, bool isDark) {
  return parsePrayerIntentionColor(intention?.color) ??
      (isDark ? AppColors.grey500 : AppColors.grey800);
}

Color _surface(bool isDark) =>
    isDark ? AppColors.cardDark : AppColors.surfaceWhite;

bool _nearSurface(Color color, bool isDark) =>
    (color.computeLuminance() - _surface(isDark).computeLuminance()).abs() <
    0.05;

/// Card fill: a light wash of the intention in light mode; in dark mode the
/// same hue pulled down to a deep, muted shade. No intention means white, or
/// a grey on dark.
Color prayerIntentionCardColor(ChatPrayerIntentionDTO? intention, bool isDark) {
  final base = parsePrayerIntentionColor(intention?.color);
  if (base == null) {
    return isDark ? AppColors.chipBackgroundDark : AppColors.surfaceWhite;
  }
  if (!isDark) {
    return Color.alphaBlend(
      base.withValues(alpha: 0.14),
      AppColors.surfaceWhite,
    );
  }
  final hsl = HSLColor.fromColor(base);
  return hsl
      .withSaturation(hsl.saturation.clamp(0.0, 0.35))
      .withLightness(0.16)
      .toColor();
}

/// A hairline only when the fill would otherwise vanish into the sheet, as
/// with no intention or a white one.
BorderSide prayerIntentionCardBorder(
  ChatPrayerIntentionDTO? intention,
  bool isDark,
) {
  final base = parsePrayerIntentionColor(intention?.color);
  final plain = base == null || _nearSurface(base, isDark) || _isGrey(base);
  if (!plain) return BorderSide.none;
  return BorderSide(
    color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
  );
}

bool _isGrey(Color color) => HSLColor.fromColor(color).saturation < 0.05;

/// Text in the intention's colour on the sheet surface; falls back to the
/// primary text colour when the accent would not contrast with it.
Color prayerAccentTextColor(Color accent, bool isDark) {
  final luminance = accent.computeLuminance();
  if (isDark) {
    return luminance < 0.15 ? AppColors.textPrimaryDark : accent;
  }
  return luminance > 0.5 ? AppColors.textPrimary : accent;
}

/// Text or icon painted on top of a fill in the accent colour.
Color prayerAccentOnColor(Color accent) =>
    accent.computeLuminance() > 0.5
        ? AppColors.textPrimary
        : AppColors.surfaceWhite;

/// Whether the accent is too close to the surface to serve as a fill on
/// its own, and needs a visible border.
bool prayerAccentNeedsBorder(Color accent, bool isDark) =>
    _nearSurface(accent, isDark);
