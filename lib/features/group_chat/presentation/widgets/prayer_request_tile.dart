import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';

/// One prayer request: who asked, what for, and a pray toggle.
class PrayerRequestTile extends StatelessWidget {
  const PrayerRequestTile({
    super.key,
    required this.request,
    required this.displayName,
    this.avatarUrl,
    this.onTogglePrayer,
  });

  final ChatMessageDTO request;
  final String displayName;
  final String? avatarUrl;
  final VoidCallback? onTogglePrayer;

  static const double _avatarSize = 22;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final bodyColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                avatarUrl: avatarUrl,
                displayName: displayName,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  strutStyle: context.tibetanStrutStyle(13, compact: true),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: nameColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.body,
            strutStyle: context.tibetanStrutStyle(14),
            style: TextStyle(fontSize: 14, height: 1.4, color: bodyColor),
          ),
          const SizedBox(height: 6),
          _PrayToggle(
            prayedByMe: request.prayedByMe,
            count: request.prayerCount,
            isDark: isDark,
            onTap: onTogglePrayer,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatarUrl,
    required this.displayName,
    required this.isDark,
  });

  final String? avatarUrl;
  final String displayName;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final hasUrl = url != null && url.isNotEmpty;
    const size = PrayerRequestTile._avatarSize;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child:
            hasUrl
                ? CachedNetworkImageWidget(
                  key: ValueKey(url),
                  imageUrl: url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorWidget: _initials(),
                )
                : _initials(),
      ),
    );
  }

  Widget _initials() {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Center(
        child: Text(
          chatSenderInitials(displayName).characters.take(1).toString(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.grey500 : AppColors.grey600,
          ),
        ),
      ),
    );
  }
}

class _PrayToggle extends StatelessWidget {
  const _PrayToggle({
    required this.prayedByMe,
    required this.count,
    required this.isDark,
    required this.onTap,
  });

  final bool prayedByMe;
  final int count;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isDark ? AppColors.accentGold : AppColors.accentGoldDark;
    final idleColor = isDark ? AppColors.textTertiaryDark : AppColors.grey800;
    final color = prayedByMe ? activeColor : idleColor;
    // The label counts everyone praying; only the colour is about me.
    final label =
        count > 0
            ? context.l10n.event_prayer_praying
            : context.l10n.event_prayer_pray;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              prayedByMe ? AppAssets.handsPrayingFill : AppAssets.handsPraying,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              count > 0 ? '$count · $label' : label,
              strutStyle: context.tibetanStrutStyle(12, compact: true),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
