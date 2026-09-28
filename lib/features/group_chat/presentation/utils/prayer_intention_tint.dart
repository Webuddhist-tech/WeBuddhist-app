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

/// Card fill: a light wash of the intention in light mode, a deeper one over
/// the dark card in dark mode. Falls back to the plain card colours.
Color prayerIntentionCardColor(ChatPrayerIntentionDTO? intention, bool isDark) {
  final base = parsePrayerIntentionColor(intention?.color);
  if (base == null) {
    return isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
  }
  return isDark
      ? Color.alphaBlend(base.withValues(alpha: 0.32), AppColors.cardDark)
      : Color.alphaBlend(base.withValues(alpha: 0.14), AppColors.surfaceWhite);
}

/// Border to set a tinted card off from its surface.
Color prayerIntentionBorderColor(
  ChatPrayerIntentionDTO? intention,
  bool isDark,
) {
  final base = parsePrayerIntentionColor(intention?.color);
  if (base == null) {
    return isDark ? AppColors.cardBorderDark : AppColors.grey300;
  }
  return base.withValues(alpha: isDark ? 0.5 : 0.3);
}
