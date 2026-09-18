import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reactions.dart';

/// The reaction chip: a separate element hung under the bubble's inner corner
/// — bottom-right under an incoming message, bottom-left under one of the
/// viewer's own. Glyphs and an aggregate count on a small surface of the same
/// colour and shadow as the bubble.
///
/// The bubble positions it in a [Stack]; it is not a child of the bubble's
/// own column.
///
/// At most [kChatBadgeEmojiLimit] distinct emoji are shown, busiest first,
/// followed by the total across all of them — so the chip never wraps and the
/// bubble keeps a stable height however many emoji accumulate. An own reaction
/// is not marked: design chose one look for every glyph, and it keeps them on
/// one baseline.
class GroupChatReactionBadges extends StatelessWidget {
  const GroupChatReactionBadges({
    super.key,
    required this.reactions,
    required this.onShowAll,
  });

  final List<ChatMessageReactionDTO> reactions;

  /// Tapping the chip opens the reactions drawer, as in WhatsApp — it does
  /// not toggle. Reacting happens from the pill or the drawer.
  final VoidCallback onShowAll;

  /// Fixed, so the bubble can reserve exactly this much under itself.
  static const double height = 26;

  @override
  Widget build(BuildContext context) {
    final badge = chatBadgeReactions(reactions);
    if (badge.emoji.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return GestureDetector(
      onTap: onShowAll,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color:
              isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final reaction in badge.emoji)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Text(
                  reaction.emoji,
                  style: const TextStyle(fontSize: 15, height: 1),
                ),
              ),
            const SizedBox(width: 1),
            Text(
              _count(context, badge.total),
              strutStyle: context.tibetanStrutStyle(14, compact: true),
              style: TextStyle(fontSize: 14, height: 1, color: countColor),
            ),
          ],
        ),
      ),
    );
  }

  String _count(BuildContext context, int total) {
    final formatted = '$total';
    return context.isTibetanLocale ? toTibetanDigits(formatted) : formatted;
  }
}
