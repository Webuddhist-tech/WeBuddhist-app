import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_parent_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';

/// The quoted original, shown above the body of a reply.
///
/// Used both inside a bubble and — via [isPreview] — in the bar above the
/// composer while a reply is being written.
class GroupChatQuotedMessage extends StatelessWidget {
  const GroupChatQuotedMessage({
    super.key,
    required this.parent,
    this.isPreview = false,
    this.onOutgoing = false,
    this.isOwnOriginal = false,
    this.isDeleted = false,
    this.onTap,
  });

  final ChatMessageParentDTO parent;

  /// Preview mode sits on the page background rather than inside a bubble.
  final bool isPreview;

  /// Inside one of the viewer's own bubbles, whose fill is already the cream
  /// the quote uses elsewhere — so the panel goes paler instead.
  final bool onOutgoing;

  /// The original is the viewer's own message: the header reads "You".
  final bool isOwnOriginal;

  /// The original has been deleted. The quote becomes a tombstone with no
  /// header, matching the mocks; the words are gone for everyone.
  ///
  /// Decided from `parent.deleted_at` when the server sends it, and from the
  /// loaded thread meanwhile — the caller works that out, since only it can
  /// see the other rows.
  final bool isDeleted;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // The quote carries the original author's colour on both the name and the
    // rule, so a reply says who it answers at a glance.
    final accent = chatSenderColor(
      seed: chatSenderSeed(
        senderId: parent.senderId,
        senderEmail: parent.senderEmail,
        name: parent.senderName,
      ),
      onDark: isDark,
    );
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    // The panel is the outgoing cream on white and on the page; inside a
    // cream bubble it goes paler so it still reads as nested.
    final fill =
        onOutgoing
            ? AppColors.surfaceWhite.withValues(alpha: isDark ? 0.12 : 0.55)
            : (isDark
                ? AppColors.chatOutgoingBubbleDark
                : AppColors.chatOutgoingBubble);

    final panel = Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child:
          isDeleted
              ? _tombstone(context, textColor)
              : Text(
                parent.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                strutStyle: context.tibetanStrutStyle(14),
                style: TextStyle(fontSize: 14, color: textColor),
              ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isPreview ? 0 : 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          // Stretched, so the panel spans the bubble however short the quote.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The name sits above the panel, aligned with its rule, as in the
            // mock. A deleted original has no header: there is nothing left
            // to attribute.
            if (!isDeleted) ...[
              Text(
                _header(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                strutStyle: context.tibetanStrutStyle(13, compact: true),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const SizedBox(height: 2),
            ],
            panel,
          ],
        ),
      ),
    );
  }

  String _header(BuildContext context) {
    if (isOwnOriginal) return context.l10n.group_chat_you;
    return chatSenderDisplayName(
          messageName: parent.senderName,
          senderEmail: parent.senderEmail,
        ) ??
        context.l10n.group_chat_unknown_sender;
  }

  Widget _tombstone(BuildContext context, Color color) {
    return Row(
      children: [
        Icon(AppAssets.prohibit, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            context.l10n.group_chat_message_deleted_by_sender,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            strutStyle: context.tibetanStrutStyle(14),
            style: TextStyle(fontSize: 14, color: color),
          ),
        ),
      ],
    );
  }
}
