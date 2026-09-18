import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

enum _ConnectAction { edit, delete }

/// Overflow button with an optional Edit entry and a destructive Delete.
class ConnectActionMenu extends StatelessWidget {
  const ConnectActionMenu({
    super.key,
    this.onEdit,
    this.onDelete,
    this.iconSize = 20,
    this.iconColor,
    this.style,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final double iconSize;
  final Color? iconColor;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return PopupMenuButton<_ConnectAction>(
      icon: Icon(
        AppAssets.dotsThreeVertical,
        size: iconSize,
        color:
            iconColor ??
            (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
      ),
      padding: EdgeInsets.zero,
      style: style,
      offset: const Offset(0, 28),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.grey800 : AppColors.grey300),
      ),
      onSelected: (action) {
        switch (action) {
          case _ConnectAction.edit:
            onEdit?.call();
          case _ConnectAction.delete:
            onDelete?.call();
        }
      },
      itemBuilder:
          (context) => [
            if (onEdit != null)
              _item(
                _ConnectAction.edit,
                AppAssets.pencilSimple,
                context.l10n.edit,
                textColor,
              ),
            if (onDelete != null)
              _item(
                _ConnectAction.delete,
                AppAssets.trash,
                context.l10n.delete,
                AppColors.error,
              ),
          ],
    );
  }

  PopupMenuItem<_ConnectAction> _item(
    _ConnectAction action,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem<_ConnectAction>(
      value: action,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
