import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';

class AppBottomNavItem<T> extends StatelessWidget {
  const AppBottomNavItem({
    super.key,
    required this.model,
    required this.selectedType,
  });

  final AppBottomBarItemModel model;
  final T selectedType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    // Active color uses primary color, inactive uses grey (dark mode friendly)
    final activeColor =
        theme.colorScheme.brightness == Brightness.dark
            ? Colors.white
            : Colors.black;
    final inactiveColor =
        isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600;

    final isSelected = model.type == selectedType;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildLeading(
            isSelected: isSelected,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          model.label,
          strutStyle: context.tibetanStrutStyle(
            Theme.of(context).textTheme.bodySmall?.fontSize ?? 12,
            compact: true,
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? activeColor : inactiveColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLeading({
    required bool isSelected,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final avatarUrl = model.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return _NavProfileAvatar(
        key: ValueKey(isSelected),
        avatarUrl: avatarUrl,
        isSelected: isSelected,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        fallbackIcon:
            isSelected ? model.selectedIconData : model.unSelectedIconData,
        iconColor: isSelected ? activeColor : inactiveColor,
      );
    }

    return PhosphorIcon(
      isSelected ? model.selectedIconData : model.unSelectedIconData,
      size: 24,
      color: isSelected ? activeColor : inactiveColor,
    );
  }
}

class _NavProfileAvatar extends StatelessWidget {
  const _NavProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.fallbackIcon,
    required this.iconColor,
  });

  final String avatarUrl;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final IconData fallbackIcon;
  final Color iconColor;

  static const _size = 26.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: CachedNetworkImageWidget(
          imageUrl: avatarUrl,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorWidget: PhosphorIcon(fallbackIcon, size: _size, color: iconColor),
        ),
      ),
    );
  }
}

class AppBottomBarItemModel<T> {
  final IconData selectedIconData;
  final IconData unSelectedIconData;
  final String label;
  final Widget? selectedWidget;
  final String? avatarUrl;

  final T type;

  AppBottomBarItemModel({
    required this.selectedIconData,
    required this.unSelectedIconData,
    required this.selectedWidget,
    required this.label,
    required this.type,
    this.avatarUrl,
  });

  @override
  bool operator ==(covariant AppBottomBarItemModel<T> other) {
    if (identical(this, other)) return true;

    return other.type == type;
  }

  @override
  int get hashCode {
    return type.hashCode;
  }
}
