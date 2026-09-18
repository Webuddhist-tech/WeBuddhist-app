import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:intl/intl.dart';

/// Chat top bar: back arrow plus the group identity, matching the back-row
/// pattern used by the group profile and accumulator screens.
///
/// [profile] is null while membership is still resolving, leaving only the back
/// arrow so the bar does not change height once the group loads.
class GroupChatHeader extends StatelessWidget {
  const GroupChatHeader({
    super.key,
    required this.isDark,
    required this.onBack,
    this.profile,
    this.onOverflow,
  });

  final bool isDark;
  final VoidCallback onBack;
  final GroupProfile? profile;

  /// Notification toggle. Null keeps the button inert but present, so wiring
  /// mute later needs no layout change.
  final VoidCallback? onOverflow;

  static const double _avatarSize = 40;

  @override
  Widget build(BuildContext context) {
    final group = profile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(AppAssets.arrowLeft), onPressed: onBack),
          if (group == null)
            const Spacer()
          else ...[
            _Avatar(avatarUrl: group.avatarUrl, isDark: isDark),
            const SizedBox(width: 12),
            Expanded(child: _Identity(profile: group, isDark: isDark)),
          ],
          IconButton(
            icon: const Icon(AppAssets.bellSlash),
            onPressed: onOverflow,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.isDark});

  final String? avatarUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final hasUrl = url != null && url.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: GroupChatHeader._avatarSize,
        height: GroupChatHeader._avatarSize,
        child:
            hasUrl
                ? CachedNetworkImageWidget(
                  key: ValueKey(url),
                  imageUrl: url,
                  width: GroupChatHeader._avatarSize,
                  height: GroupChatHeader._avatarSize,
                  fit: BoxFit.cover,
                  errorWidget: _fallback(),
                )
                : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.usersThree,
        size: 20,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.profile, required this.isDark});

  final GroupProfile profile;
  final bool isDark;

  static const double _titleFontSize = 18;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final lineHeight = getLineHeight(locale.languageCode);
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          strutStyle: context.tibetanStrutStyle(_titleFontSize, compact: true),
          style: TextStyle(
            fontSize: _titleFontSize,
            fontWeight: FontWeight.w700,
            color: titleColor,
            height: lineHeight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _countLabel(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: secondaryColor,
            height: lineHeight,
          ),
        ),
      ],
    );
  }

  String _countLabel(BuildContext context) {
    final count = profile.memberOrFollowerCount;
    final label =
        profile.groupType.isPage
            ? (count == 1
                ? context.l10n.group_follower
                : context.l10n.group_followers)
            : (count == 1
                ? context.l10n.group_member
                : context.l10n.group_members);
    final formatted = _formatCompactCount(count, intlFormatLocaleOf(context));

    return context.isTibetanLocale
        ? '$label ${toTibetanDigits(formatted)}'
        : '$formatted $label';
  }

  String _formatCompactCount(int count, String locale) {
    if (count >= 1000000) {
      return '${_trimTrailingZero((count / 1000000).toStringAsFixed(1))}M';
    }
    if (count >= 1000) {
      return '${_trimTrailingZero((count / 1000).toStringAsFixed(1))}k';
    }
    return NumberFormat.decimalPattern(locale).format(count);
  }

  String _trimTrailingZero(String value) {
    return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
  }
}
