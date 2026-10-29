import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';

class MeProfileHeader extends StatelessWidget {
  const MeProfileHeader({super.key, required this.user});

  final User user;

  static const _avatarSize = 80.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final avatarUrl = user.avatarUrl ?? '';
    final username = user.username?.trim() ?? '';
    final email = user.email ?? '';
    final bio = user.aboutMe ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(tag: 'profile-avatar', child: _Avatar(avatarUrl: avatarUrl)),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  // Personal details stay hidden in Clarity recordings.
                  child: ClarityMask(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (username.isNotEmpty)
                          Text(
                            username,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (email.isNotEmpty) ...[
                          if (username.isNotEmpty) const SizedBox(height: 4),
                          Text(
                            email,
                            style: textTheme.bodyMedium?.copyWith(
                              color:
                                  isDark
                                      ? AppColors.grey600
                                      : AppColors.grey900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              bio,
              style: textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.grey400 : AppColors.grey900,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MeProfileHeader._avatarSize,
      height: MeProfileHeader._avatarSize,
      child: ClipOval(
        child:
            avatarUrl.isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: avatarUrl,
                  width: MeProfileHeader._avatarSize,
                  height: MeProfileHeader._avatarSize,
                  fit: BoxFit.cover,
                  placeholder: const ColoredBox(color: AppColors.grey300),
                  errorWidget: ColoredBox(
                        color: AppColors.grey300,
                        child: Icon(
                          AppAssets.profile,
                          size: 36,
                          color: AppColors.grey600,
                        ),
                      ),
                )
                : DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.grey300, width: 1.5),
                  ),
                  child: Icon(
                    AppAssets.profile,
                    size: 36,
                    color: AppColors.grey600,
                  ),
                ),
      ),
    );
  }
}
