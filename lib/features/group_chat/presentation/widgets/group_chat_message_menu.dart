import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reactions.dart';

/// What the long-press menu resolved to.
sealed class ChatMessageMenuResult {
  const ChatMessageMenuResult();
}

class ChatMessageReact extends ChatMessageMenuResult {
  final String emoji;
  const ChatMessageReact(this.emoji);
}

/// The `+` was tapped: the caller opens the full emoji picker.
class ChatMessageMoreEmoji extends ChatMessageMenuResult {
  const ChatMessageMoreEmoji();
}

enum ChatMessageAction { reply, copy, report, delete }

class ChatMessageActionPicked extends ChatMessageMenuResult {
  final ChatMessageAction action;
  const ChatMessageActionPicked(this.action);
}

/// Opens the long-press menu over a blurred thread, with [anchor] — the global
/// rect of the pressed bubble — kept sharp in place.
///
/// Returns null when dismissed.
Future<ChatMessageMenuResult?> showChatMessageMenu(
  BuildContext context, {
  required Rect anchor,
  required Widget message,
  required String? myEmoji,
  required bool canReport,
  required bool canDelete,
}) {
  return Navigator.of(context).push<ChatMessageMenuResult>(
    PageRouteBuilder<ChatMessageMenuResult>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder:
          (_, _, _) => _ChatMessageMenu(
            anchor: anchor,
            message: message,
            myEmoji: myEmoji,
            canReport: canReport,
            canDelete: canDelete,
          ),
      transitionsBuilder:
          (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _ChatMessageMenu extends StatelessWidget {
  const _ChatMessageMenu({
    required this.anchor,
    required this.message,
    required this.myEmoji,
    required this.canReport,
    required this.canDelete,
  });

  final Rect anchor;
  final Widget message;
  final String? myEmoji;
  final bool canReport;
  final bool canDelete;

  static const double _pillHeight = 56;
  static const double _gap = 8;
  static const double _cardWidth = 240;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeTop = media.padding.top + 8;
    final safeBottom = media.size.height - media.padding.bottom - 8;
    // Counted, not assumed: Report and Delete are both conditional now, and a
    // hardcoded row count would size the card for rows it is not drawing —
    // which the positioning below then compounds.
    final rowCount = 2 + (canReport ? 1 : 0) + (canDelete ? 1 : 0);
    final cardHeight = 52.0 * rowCount + 16;

    // A long message cannot be lifted whole. The pill above it and the card
    // below it are the whole point of the menu, and a full-height bubble drove
    // the card clean off the bottom of the screen — leaving a wall of text and
    // no way to act on it. Cap the lift at the room actually left over.
    final room = safeBottom - safeTop - _pillHeight - _gap - _gap - cardHeight;
    final messageHeight = math.min(anchor.height, math.max(room, 0.0));
    final isClipped = messageHeight < anchor.height;

    // Keep the lifted message on screen when it sat near an edge: the pill
    // above and the card below both have to fit.
    var top = anchor.top;
    final minTop = safeTop + _pillHeight + _gap;
    final maxTop = safeBottom - messageHeight - _gap - cardHeight;
    if (maxTop > minTop) {
      top = top.clamp(minTop, maxTop);
    } else {
      top = minTop;
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.08),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          Positioned(
            left: anchor.left,
            top: top - _pillHeight - _gap,
            width: anchor.width,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _EmojiPill(myEmoji: myEmoji),
            ),
          ),
          Positioned(
            left: anchor.left,
            top: top,
            width: anchor.width,
            height: messageHeight,
            // Clipped, not scaled: the text stays the size it is in the
            // thread and the remainder is a scroll away. A cut message takes
            // touches so it can be read; a whole one stays inert, so tapping
            // it still dismisses the menu.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child:
                  isClipped
                      ? SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: message,
                      )
                      : IgnorePointer(child: message),
            ),
          ),
          Positioned(
            left: anchor.left,
            top: top + messageHeight + _gap,
            width: anchor.width,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: _cardWidth,
                child: _ActionsCard(canReport: canReport, canDelete: canDelete),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiPill extends StatelessWidget {
  const _EmojiPill({required this.myEmoji});

  final String? myEmoji;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: _ChatMessageMenu._pillHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(_ChatMessageMenu._pillHeight / 2),
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
              onTap: () => Navigator.of(context).pop(ChatMessageReact(emoji)),
              isSelected: emoji == myEmoji,
              isDark: isDark,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          _PillButton(
            onTap:
                () => Navigator.of(context).pop(const ChatMessageMoreEmoji()),
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
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : background,
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.canReport, required this.canDelete});

  final bool canReport;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionRow(
            icon: AppAssets.arrowBendUpLeft,
            label: context.l10n.group_chat_reply,
            action: ChatMessageAction.reply,
            isDark: isDark,
          ),
          _ActionRow(
            icon: AppAssets.copy,
            label: context.l10n.group_chat_copy,
            action: ChatMessageAction.copy,
            isDark: isDark,
          ),
          if (canReport)
            _ActionRow(
              icon: AppAssets.warning,
              label: context.l10n.group_chat_report,
              action: ChatMessageAction.report,
              isDark: isDark,
              isDestructive: true,
            ),
          if (canDelete)
            _ActionRow(
              icon: AppAssets.trash,
              label: context.l10n.group_chat_delete,
              action: ChatMessageAction.delete,
              isDark: isDark,
              isDestructive: true,
            ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.action,
    required this.isDark,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final ChatMessageAction action;
  final bool isDark;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive
            ? AppColors.error
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return InkWell(
      onTap: () => Navigator.of(context).pop(ChatMessageActionPicked(action)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                strutStyle: context.tibetanStrutStyle(15, compact: true),
                style: TextStyle(fontSize: 15, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
