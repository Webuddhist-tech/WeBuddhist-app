import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_parent_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_quoted_message.dart';

/// The pinned quote above the composer while a reply is being written.
///
/// Lives in the same column as the composer, so it rides above the keyboard
/// with it rather than being covered by it.
class GroupChatReplyPreview extends StatelessWidget {
  const GroupChatReplyPreview({
    super.key,
    required this.message,
    required this.onCancel,
    this.isOwnMessage = false,
  });

  final ChatMessageDTO message;
  final VoidCallback onCancel;

  /// Replying to one's own message: the quote's header reads "You".
  final bool isOwnMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      color: isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // The quote block already names the author, so no separate
          // "replying to" line: it would say the same thing twice.
          Expanded(
            child: GroupChatQuotedMessage(
              parent: _asParent(message),
              isPreview: true,
              isOwnOriginal: isOwnMessage,
            ),
          ),
          IconButton(
            icon: const Icon(AppAssets.x, size: 18),
            color: isDark ? AppColors.grey500 : AppColors.grey600,
            onPressed: onCancel,
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
          ),
        ],
      ),
    );
  }

  /// The message being replied to, shaped as the quote the server will echo
  /// back on the reply itself.
  static ChatMessageParentDTO _asParent(ChatMessageDTO message) {
    return ChatMessageParentDTO(
      id: message.id,
      senderId: message.senderId,
      senderEmail: message.senderEmail,
      senderName: message.senderName,
      senderAvatarUrl: message.senderAvatarUrl,
      body: message.body,
      createdAt: message.createdAt,
    );
  }
}
