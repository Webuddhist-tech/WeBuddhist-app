import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_relative_time.dart';
import 'package:go_router/go_router.dart';

/// Shared author header for Connect feed cards (group avatar, name, time).
class ConnectFeedCardHeader extends StatelessWidget {
  const ConnectFeedCardHeader({
    super.key,
    required this.groupName,
    this.groupAvatarUrl,
    this.groupId,
    this.timestamp,
    this.subtitle,
    this.subtitleIcon,
    this.stackTimestamp = false,
    this.onMoreTap,
    this.trailing,
  });

  final String groupName;
  final String? groupAvatarUrl;
  final String? groupId;
  final DateTime? timestamp;
  final String? subtitle;
  final IconData? subtitleIcon;
  final bool stackTimestamp;
  final VoidCallback? onMoreTap;
  final Widget? trailing;

  static const double avatarRadius = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final displayName =
        groupName.trim().isNotEmpty
            ? groupName.trim()
            : context.l10n.connect_group_fallback_title;
    final timeLabel = ConnectRelativeTime.format(context, timestamp);
    final trimmedSubtitle = subtitle?.trim();
    final secondLine = [
      if (trimmedSubtitle != null && trimmedSubtitle.isNotEmpty) trimmedSubtitle,
      if (stackTimestamp && timeLabel.isNotEmpty) timeLabel,
    ].join(' · ');

    final avatar = CircleAvatar(
      radius: avatarRadius,
      backgroundColor:
          isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      backgroundImage:
          groupAvatarUrl != null && groupAvatarUrl!.isNotEmpty
              ? groupAvatarUrl!.cachedNetworkImageProvider
              : null,
      child:
          groupAvatarUrl == null || groupAvatarUrl!.isEmpty
              ? Icon(
                AppAssets.usersThree,
                size: 18,
                color: secondaryColor,
              )
              : null,
    );

    final trimmedGroupId = groupId?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (trimmedGroupId != null && trimmedGroupId.isNotEmpty)
            GestureDetector(
              onTap: () => context.push('/home/group/$trimmedGroupId'),
              behavior: HitTestBehavior.opaque,
              child: avatar,
            )
          else
            avatar,
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap:
                  trimmedGroupId != null && trimmedGroupId.isNotEmpty
                      ? () => context.push('/home/group/$trimmedGroupId')
                      : null,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!stackTimestamp && timeLabel.isNotEmpty) ...[
                        Text(
                          ' · $timeLabel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (secondLine.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        if (subtitleIcon != null) ...[
                          Icon(subtitleIcon, size: 14, color: secondaryColor),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            secondLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onMoreTap != null)
            IconButton(
              onPressed: onMoreTap,
              icon: Icon(
                AppAssets.dotsThreeVertical,
                size: 20,
                color: secondaryColor,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
        ],
      ),
    );
  }
}
