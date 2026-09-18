import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reactions.dart';

/// The quick-reaction pill that floats above a selected message: the six
/// quick reactions, then a `+` that opens the full picker.
///
/// The thread positions it; this widget only knows its own size, which is why
/// [height] and [width] are fixed constants rather than measured.
class GroupChatEmojiPill extends StatelessWidget {
  const GroupChatEmojiPill({
    super.key,
    required this.myEmoji,
    required this.onPick,
    required this.onMore,
  });

  /// The emoji the viewer already holds on this message, drawn in a tinted
  /// circle so tapping it again reads as un-reacting.
  final String? myEmoji;

  final ValueChanged<String> onPick;
  final VoidCallback onMore;

  static const double height = 56;
  static const double _buttonSize = 38;
  static const double _buttonMargin = 1;
  static const double _padding = 10;

  /// The quick reactions plus the `+`, each with its margin, plus padding.
  /// A getter, not a const: a list's length is not a constant expression.
  static double get width =>
      (kChatQuickReactions.length + 1) * (_buttonSize + 2 * _buttonMargin) +
      2 * _padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: _padding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final emoji in kChatQuickReactions)
            _PillButton(
              onTap: () {
                HapticFeedback.selectionClick();
                onPick(emoji);
              },
              isSelected: emoji == myEmoji,
              isDark: isDark,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          _PillButton(
            onTap: () {
              HapticFeedback.selectionClick();
              onMore();
            },
            isSelected: false,
            isDark: isDark,
            background: isDark ? AppColors.grey800 : AppColors.grey100,
            child: Icon(
              AppAssets.plus,
              size: 18,
              color: isDark ? AppColors.textPrimaryDark : AppColors.grey900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.onTap,
    required this.isSelected,
    required this.isDark,
    required this.child,
    this.background,
  });

  final VoidCallback onTap;
  final bool isSelected;
  final bool isDark;
  final Widget child;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final selectedColor = (isDark
            ? AppColors.accentGold
            : AppColors.accentGoldDark)
        .withValues(alpha: 0.22);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: GroupChatEmojiPill._buttonSize,
        height: GroupChatEmojiPill._buttonSize,
        margin: const EdgeInsets.symmetric(
          horizontal: GroupChatEmojiPill._buttonMargin,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : background,
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}
