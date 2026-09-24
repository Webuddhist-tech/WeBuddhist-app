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

bool _containsTibetan(String value) {
  return RegExp(r'[\u0F00-\u0FFF]').hasMatch(value);
}

class MyGroupsSection extends StatelessWidget {
  const MyGroupsSection({super.key, required this.groups, required this.total});

  final List<GroupProfile> groups;
  final int total;

  static const double _tileSize = 72;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.my_groups,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              if (total > 0)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(name: 'my-groups'),
                        builder: (_) => const MyGroupsScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: subtitleColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    context.l10n.see_all,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _MyGroupTile(group: groups[index], isDark: isDark);
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MyGroupTile extends StatelessWidget {
  const _MyGroupTile({required this.group, required this.isDark});

  final GroupProfile group;
  final bool isDark;

  static const double _titleFontSize = 12;

  @override
  Widget build(BuildContext context) {
    final tileColor = isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final hasTibetanTitle = _containsTibetan(group.title);
    final titleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: _titleFontSize,
      color: subtitleColor,
      fontWeight: FontWeight.w500,
      height:
          hasTibetanTitle ? AppFontConfig.tibetanCompactLineHeight : null,
      leadingDistribution:
          hasTibetanTitle ? AppFontConfig.tibetanLeadingDistribution : null,
    );

    return SizedBox(
      width: 80,
      child: GestureDetector(
        onTap: () => context.push('/home/group/${group.id}'),
        child: Column(
          children: [
            Container(
              width: MyGroupsSection._tileSize,
              height: MyGroupsSection._tileSize,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _GroupAvatar(group: group, isDark: isDark),
            ),
            const SizedBox(height: 8),
            Text(
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
                        _titleFontSize,
                        compact: true,
                      )
                      : null,
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
    if (group.avatarUrl != null && group.avatarUrl!.isNotEmpty) {
      return CachedNetworkImageWidget(imageUrl: group.avatarUrl!);
    }

    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.usersThree,
        size: 28,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}
