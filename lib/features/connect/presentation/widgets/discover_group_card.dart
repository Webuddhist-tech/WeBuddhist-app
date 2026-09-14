import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_join_request_drawer.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DiscoverGroupCard extends ConsumerWidget {
  const DiscoverGroupCard({
    super.key,
    required this.group,
    this.showJoinButton = false,
    this.subtitleOverride,
  });

  final GroupProfile group;
  final bool showJoinButton;
  final String? subtitleOverride;

  static const double _titleFontSize = 15;
  static const double _subtitleFontSize = 13;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final followKey = GroupFollowKey(
      groupId: group.id,
      groupType: group.groupType,
      loadInitialStatus: false,
    );
    final followState = ref.watch(groupFollowProvider(followKey));
    final countDelta = switch (followState) {
      GroupFollowSuccess(countDelta: final delta) => delta,
      _ => 0,
    };
    final subtitleText = subtitleOverride ?? _subtitle(context, countDelta);
    final hasTibetanTitle = _containsTibetan(group.title);
    final hasTibetanSubtitle =
        context.isTibetanLocale || _containsTibetan(subtitleText);
    final hasTibetanText = hasTibetanTitle || hasTibetanSubtitle;
    final titleStyle =
        hasTibetanTitle
            ? getContentTextStyle(
              AppConfig.tibetanLanguageCode,
              theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: _titleFontSize,
                height: AppFontConfig.tibetanContentLineHeight,
                leadingDistribution: AppFontConfig.tibetanLeadingDistribution,
              ),
            )
            : theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: _titleFontSize,
              height: 1.3,
            );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: subtitleColor,
      fontSize: hasTibetanSubtitle ? 14 : _subtitleFontSize,
      height: hasTibetanSubtitle ? AppFontConfig.tibetanUiLineHeight : null,
      leadingDistribution:
          hasTibetanSubtitle ? AppFontConfig.tibetanLeadingDistribution : null,
    );
    final subtitleFontSize = hasTibetanSubtitle ? 14.0 : _subtitleFontSize;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/home/group/${group.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 4,
            vertical: hasTibetanText ? 10 : 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _GroupAvatar(group: group, isDark: isDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      group.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                      strutStyle:
                          hasTibetanTitle
                              ? AppFontConfig.tibetanStrutStyle(
                                AppConfig.tibetanLanguageCode,
                                _titleFontSize,
                              )
                              : null,
                    ),
                    SizedBox(height: hasTibetanText ? 4 : 2),
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: subtitleStyle,
                      strutStyle:
                          hasTibetanSubtitle
                              ? AppFontConfig.tibetanStrutStyle(
                                AppConfig.tibetanLanguageCode,
                                subtitleFontSize,
                              )
                              : null,
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: true,
                        applyHeightToLastDescent: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (showJoinButton)
                _JoinButton(group: group, isDark: isDark, followKey: followKey),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(BuildContext context, int countDelta) {
    final memberCount = (group.memberOrFollowerCount + countDelta).clamp(
      0,
      1 << 31,
    );
    final formattedCount = _formatCompactCount(
      memberCount,
      intlFormatLocaleOf(context),
    );
    final memberLabel =
        memberCount == 1
            ? context.l10n.group_member
            : context.l10n.group_members;

    if (context.isTibetanLocale) {
      return '$memberLabel ${toTibetanDigits(formattedCount)}';
    }
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

  bool _containsTibetan(String value) {
    return RegExp(r'[\u0F00-\u0FFF]').hasMatch(value);
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
        width: 48,
        height: 48,
        child:
            group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: group.avatarUrl!,
                  fit: BoxFit.cover,
                  width: 48,
                  height: 48,
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

class _JoinButton extends ConsumerWidget {
  const _JoinButton({
    required this.group,
    required this.isDark,
    required this.followKey,
  });

  final GroupProfile group;
  final bool isDark;
  final GroupFollowKey followKey;

  bool get _isPrivateCommunity => group.isPrivateCommunity;

  bool get _isRequestPending =>
      group.myJoinRequestStatus == GroupJoinRequestStatus.pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followState = ref.watch(groupFollowProvider(followKey));
    final isLoading = followState is GroupFollowLoading;
    final isPending = _isRequestPending;
    final label =
        isPending
            ? context.l10n.group_request_sent
            : _isPrivateCommunity
            ? context.l10n.group_request
            : context.l10n.join;

    return SizedBox(
      height: 32,
      child: TextButton(
        onPressed:
            isLoading || isPending
                ? null
                : () => _onPressed(context, ref, followKey),
        style: TextButton.styleFrom(
          backgroundColor:
              isPending
                  ? (isDark ? AppColors.surfaceVariantDark : AppColors.grey100)
                  : (isDark ? AppColors.surfaceWhite : AppColors.textPrimary),
          foregroundColor:
              isPending
                  ? (isDark ? AppColors.surfaceWhite : AppColors.textPrimary)
                  : (isDark ? AppColors.textPrimary : AppColors.surfaceWhite),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child:
            isLoading
                ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                )
                : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  Future<void> _onPressed(
    BuildContext context,
    WidgetRef ref,
    GroupFollowKey followKey,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    if (_isPrivateCommunity) {
      final sent = await GroupJoinRequestDrawer.show(context, group);
      if (sent == true && context.mounted) {
        if (ref.exists(discoverGroupsProvider)) {
          await ref.read(discoverGroupsProvider.notifier).refresh();
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.group_join_request_sent_snackbar),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final notifier = ref.read(groupFollowProvider(followKey).notifier);
    await notifier.follow(connectGroup: group);
  }
}
