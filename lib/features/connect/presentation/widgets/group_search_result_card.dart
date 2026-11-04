import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// A space as one flat row: avatar, name and member count. Opens the space's
/// page unless [onTap] is given; [trailing] sits at the end, e.g. an unread dot.
class GroupSearchResultCard extends StatelessWidget {
  const GroupSearchResultCard({
    super.key,
    required this.group,
    this.onTap,
    this.trailing,
  });

  final GroupProfile group;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return InkWell(
      onTap: onTap ?? () => context.push('/home/group/${group.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _GroupAvatar(group: group, isDark: isDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }

  String _subtitle(BuildContext context) {
    // Same count as the space page header: `member_count` is not sent by the
    // joined-spaces list.
    final memberCount = group.memberOrFollowerCount;
    final formattedCount = _formatCompactCount(
      memberCount,
      intlFormatLocaleOf(context),
    );
    final memberLabel =
        group.groupType.isPage
            ? (memberCount == 1
                ? context.l10n.group_follower
                : context.l10n.group_followers)
            : (memberCount == 1
                ? context.l10n.group_member
                : context.l10n.group_members);

    return '$formattedCount $memberLabel';
  }

  String _formatCompactCount(int count, String locale) {
    if (count >= 1000000) {
      final value = count / 1000000;
      return '${_trimTrailingZero(value.toStringAsFixed(1))}M';
    }
    if (count >= 1000) {
      final value = count / 1000;
      return '${_trimTrailingZero(value.toStringAsFixed(1))}k';
    }
    return NumberFormat.decimalPattern(locale).format(count);
  }

  String _trimTrailingZero(String value) {
    return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.group, required this.isDark});

  final GroupProfile group;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final placeholderColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;

    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child:
            group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: group.avatarUrl!,
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                )
                : ColoredBox(
                  color: placeholderColor,
                  child: Icon(
                    AppAssets.usersThree,
                    size: 20,
                    color: isDark ? AppColors.grey500 : AppColors.grey600,
                  ),
                ),
      ),
    );
  }
}
