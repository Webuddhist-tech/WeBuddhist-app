import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Neutral placeholder (grey fill + profile icon) shown when a user has no
/// avatar or their avatar fails to load. Callers handle clipping (e.g.
/// [ClipOval]).
class AvatarFallback extends StatelessWidget {
  const AvatarFallback({
    super.key,
    required this.isDark,
    this.size,
    this.iconSize,
  });

  final bool isDark;

  /// Width and height of the placeholder. When null it fills the parent's
  /// constraints.
  final double? size;

  /// When null the ambient [IconTheme] size is used.
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ColoredBox(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
        child: Center(
          child: Icon(
            AppAssets.profile,
            size: iconSize,
            color: isDark ? AppColors.grey500 : AppColors.grey600,
          ),
        ),
      ),
    );
  }
}
