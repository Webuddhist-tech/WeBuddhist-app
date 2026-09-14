import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Shared spacing for Connect feed cards (posts, events, practices).
class ConnectFeedCardLayout {
  ConnectFeedCardLayout._();

  static const double horizontalPadding = 16;
  static const double bodyTopSpacing = 8;
  static const double bodyToMediaSpacing = 12;
  static const double mediaBottomSpacing = 12;
  static const double mediaTileGap = 4;
  static const double listItemGap = 10;
  static const double actionBarTopSpacing = 2;

  static Color listGapColor(bool isDark) =>
      isDark ? AppColors.scaffoldBackgroundDark : AppColors.scaffoldBackgroundLight;
}

/// Full-bleed media block with only vertical spacing below.
class ConnectFeedCardMediaFrame extends StatelessWidget {
  const ConnectFeedCardMediaFrame({
    super.key,
    required this.child,
    this.bottomSpacing = ConnectFeedCardLayout.mediaBottomSpacing,
  });

  final Widget child;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: child,
    );
  }
}
