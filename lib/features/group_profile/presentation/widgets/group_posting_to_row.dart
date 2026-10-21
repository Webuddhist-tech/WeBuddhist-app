import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

/// "Posting to" header shared by the group composers.
class GroupPostingToRow extends StatelessWidget {
  final GroupProfile profile;
  final bool isDark;

  const GroupPostingToRow({
    super.key,
    required this.profile,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          Text(
            context.l10n.group_post_posting_to,
            style: TextStyle(fontSize: 13, color: secondaryColor),
          ),
          const SizedBox(width: 8),
          ClipOval(
            child: SizedBox(
              width: 22,
              height: 22,
              child:
                  avatarUrl != null && avatarUrl.isNotEmpty
                      ? CachedNetworkImageWidget(
                        imageUrl: avatarUrl,
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                        errorWidget: _avatarFallback(),
                      )
                      : _avatarFallback(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              profile.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.usersThree,
        size: 12,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}
