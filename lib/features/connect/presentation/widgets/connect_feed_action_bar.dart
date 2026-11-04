import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

typedef ConnectFeedAction =
    ({
      IconData icon,
      Color? iconColor,
      int? count,
      bool isLoading,
      VoidCallback? onTap,
    });

/// Shared engagement row for Connect feed cards.
class ConnectFeedActionBar extends StatelessWidget {
  const ConnectFeedActionBar({super.key, required this.actions, this.trailing});

  final List<ConnectFeedAction> actions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 10),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            _ActionChip(action: actions[i], defaultColor: defaultColor),
          ],
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.action, required this.defaultColor});

  final ConnectFeedAction action;
  final Color defaultColor;

  @override
  Widget build(BuildContext context) {
    final onTap = action.onTap;
    final isLoading = action.isLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: action.iconColor ?? defaultColor,
                  ),
                )
              else
                Icon(
                  action.icon,
                  size: 22,
                  color: action.iconColor ?? defaultColor,
                ),
              if (action.count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '${action.count}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: defaultColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
