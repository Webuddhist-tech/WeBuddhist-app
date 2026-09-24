import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/screens/my_groups_screen.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

bool _containsTibetan(String value) {
  return RegExp(r'[\u0F00-\u0FFF]').hasMatch(value);
}

/// Horizontal row of followed groups shown above the Connect main tabs.
class FollowedGroupsRow extends StatelessWidget {
  const FollowedGroupsRow({
    super.key,
    required this.groups,
    this.isLoading = false,
    this.highlightGroupIds = const {},
  });

  final List<GroupProfile> groups;
  final bool isLoading;
  final Set<String> highlightGroupIds;

  static const double _avatarSize = 48;
  static const double _titleFontSize = 11;
  static const double _labelHeight = 14;

  @override
  Widget build(BuildContext context) {
    if (isLoading && groups.isEmpty) {
      return const _FollowedGroupsRowSkeleton();
    }

    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 84,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        scrollDirection: Axis.horizontal,
        itemCount: groups.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == groups.length) {
            return _AllGroupsTile(isDark: isDark);
          }
          final group = groups[index];
          return _FollowedGroupTile(
            group: group,
            isDark: isDark,
            hasHighlight: highlightGroupIds.contains(group.id),
          );
        },
      ),
    );
  }
}

class _FollowedGroupTile extends StatelessWidget {
  const _FollowedGroupTile({
    required this.group,
    required this.isDark,
    this.hasHighlight = true,
  });

  final GroupProfile group;
  final bool isDark;
  final bool hasHighlight;

  @override
  Widget build(BuildContext context) {
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final hasTibetanTitle =
        context.isTibetanLocale || _containsTibetan(group.title);
    final titleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: FollowedGroupsRow._titleFontSize,
      color: subtitleColor,
      fontWeight: FontWeight.w500,
      height:
          hasTibetanTitle ? AppFontConfig.tibetanCompactLineHeight : null,
      leadingDistribution:
          hasTibetanTitle ? AppFontConfig.tibetanLeadingDistribution : null,
    );

    return SizedBox(
      width: 60,
      child: GestureDetector(
        onTap: () => context.push('/home/group/${group.id}'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StoryAvatar(
              group: group,
              isDark: isDark,
              hasHighlight: hasHighlight,
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: FollowedGroupsRow._labelHeight,
              child: Text(
                group.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style:
                    hasTibetanTitle
                        ? getContentTextStyle(
                          AppConfig.tibetanLanguageCode,
                          titleStyle,
                        )
                        : titleStyle,
                strutStyle:
                    hasTibetanTitle
                        ? AppFontConfig.tibetanStrutStyle(
                          AppConfig.tibetanLanguageCode,
                          FollowedGroupsRow._titleFontSize,
                          compact: true,
                        )
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({
    required this.group,
    required this.isDark,
    required this.hasHighlight,
  });

  final GroupProfile group;
  final bool isDark;
  final bool hasHighlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: FollowedGroupsRow._avatarSize + 4,
      height: FollowedGroupsRow._avatarSize + 4,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            hasHighlight
                ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    Color(0xFFFF6B35),
                    Color(0xFF833AB4),
                  ],
                )
                : null,
        border:
            hasHighlight
                ? null
                : Border.all(
                  color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
                  width: 1.5,
                ),
      ),
      child: _GroupAvatar(group: group, isDark: isDark),
    );
  }
}

class _AllGroupsTile extends StatelessWidget {
  const _AllGroupsTile({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final backgroundColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final label = context.l10n.connect_all_groups;
    final hasTibetanLabel =
        context.isTibetanLocale || _containsTibetan(label);
    final titleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: FollowedGroupsRow._titleFontSize,
      color: subtitleColor,
      fontWeight: FontWeight.w500,
      height:
          hasTibetanLabel ? AppFontConfig.tibetanCompactLineHeight : null,
      leadingDistribution:
          hasTibetanLabel ? AppFontConfig.tibetanLeadingDistribution : null,
    );

    return SizedBox(
      width: 60,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: 'my-groups'),
              builder: (_) => const MyGroupsScreen(),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: FollowedGroupsRow._avatarSize,
              height: FollowedGroupsRow._avatarSize,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                AppAssets.caretRight,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: FollowedGroupsRow._labelHeight,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style:
                    hasTibetanLabel
                        ? getContentTextStyle(
                          AppConfig.tibetanLanguageCode,
                          titleStyle,
                        )
                        : titleStyle,
                strutStyle:
                    hasTibetanLabel
                        ? AppFontConfig.tibetanStrutStyle(
                          AppConfig.tibetanLanguageCode,
                          FollowedGroupsRow._titleFontSize,
                          compact: true,
                        )
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
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
        width: FollowedGroupsRow._avatarSize,
        height: FollowedGroupsRow._avatarSize,
        child:
            group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: group.avatarUrl!,
                  fit: BoxFit.cover,
                  width: FollowedGroupsRow._avatarSize,
                  height: FollowedGroupsRow._avatarSize,
                )
                : ColoredBox(
                  color: placeholderColor,
                  child: Icon(
                    AppAssets.usersThree,
                    size: 22,
                    color: isDark ? AppColors.grey500 : AppColors.grey600,
                  ),
                ),
      ),
    );
  }
}

class _FollowedGroupsRowSkeleton extends StatelessWidget {
  const _FollowedGroupsRowSkeleton();

  static const int _placeholderCount = 5;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SizedBox(
        height: 84,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _placeholderCount,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            return SizedBox(
              width: 60,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Bone(
                    width: FollowedGroupsRow._avatarSize,
                    height: FollowedGroupsRow._avatarSize,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  const SizedBox(height: 4),
                  Bone(
                    width: 44,
                    height: 11,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
