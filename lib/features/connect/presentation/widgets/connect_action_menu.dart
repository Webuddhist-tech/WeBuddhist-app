import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// One more entry between Edit and Delete.
class ConnectMenuEntry {
  const ConnectMenuEntry({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Overflow button with an optional Edit entry, any [extras], and a
/// destructive Delete.
class ConnectActionMenu extends StatelessWidget {
  const ConnectActionMenu({
    super.key,
    this.onEdit,
    this.onDelete,
    this.extras = const [],
    this.icon = AppAssets.dotsThreeVertical,
    this.iconSize = 20,
    this.iconColor,
    this.style,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final List<ConnectMenuEntry> extras;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    final entries = [
      if (onEdit != null)
        ConnectMenuEntry(
          icon: AppAssets.pencilSimple,
          label: context.l10n.edit,
          onTap: onEdit!,
        ),
      ...extras,
      if (onDelete != null)
        ConnectMenuEntry(
          icon: AppAssets.trash,
          label: context.l10n.delete,
          onTap: onDelete!,
        ),
    ];

    return PopupMenuButton<int>(
      icon: Icon(
        icon,
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
      onSelected: (index) => entries[index].onTap(),
      itemBuilder:
          (context) => [
            for (var i = 0; i < entries.length; i++)
              _item(
                i,
                entries[i].icon,
                entries[i].label,
                entries[i].onTap == onDelete ? AppColors.error : textColor,
              ),
          ],
    );
  }

  PopupMenuItem<int> _item(
    int index,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem<int>(
      value: index,
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
