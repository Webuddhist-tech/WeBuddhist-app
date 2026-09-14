import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_rooms_list.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_thread_rows.dart';
import 'package:intl/intl.dart';

/// One group chat in the Chats list.
class ChatRoomTile extends StatelessWidget {
  const ChatRoomTile({super.key, required this.room, this.onTap, this.now});

  final ChatRoomDTO room;
  final VoidCallback? onTap;

  /// Injectable for tests; defaults to the wall clock.
  final DateTime? now;

  static const double _avatarSize = 48;
  static const double _gutter = 12;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final subtitleColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(room: room, isDark: isDark),
            const SizedBox(width: _gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          strutStyle: context.tibetanStrutStyle(
                            16,
                            compact: true,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dateLabel(context),
                        strutStyle: context.tibetanStrutStyle(
                          12,
                          compact: true,
                        ),
                        style: TextStyle(fontSize: 12, color: subtitleColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _preview(context, subtitleColor)),
                      if (chatRoomIsUnread(room)) ...[
                        const SizedBox(width: 8),
                        _UnreadBadge(count: room.unreadCount),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Inset to the text rather than run under the avatar, so the
                  // avatars read as one column.
                  Divider(
                    height: 1,
                    thickness: 1,
                    color:
                        isDark
                            ? AppColors.surfaceWhite.withValues(alpha: 0.08)
                            : AppColors.grey100,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `Sender: message`, with the sender in the stronger colour.
  ///
  /// One [Text] rather than a Row, so the name and the message share a single
  /// two-line ellipsis instead of truncating independently.
  Widget _preview(BuildContext context, Color color) {
    final body = chatRoomPreviewBody(
      room,
      deletedLabel: context.l10n.group_chat_message_deleted_by_sender,
    );
    if (body == null) {
      return Text(
        context.l10n.group_chat_empty_title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        strutStyle: context.tibetanStrutStyle(14),
        style: TextStyle(
          fontSize: 14,
          color: color,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final message = room.lastMessage!;
    final sender = chatSenderDisplayName(
      messageName: message.senderName,
      senderEmail: message.senderEmail,
    );

    return Text.rich(
      TextSpan(
        children: [
          if (sender != null)
            TextSpan(
              text: '$sender: ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textPrimary,
              ),
            ),
          TextSpan(text: body),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      strutStyle: context.tibetanStrutStyle(14),
      style: TextStyle(fontSize: 14, color: color),
    );
  }

  /// A day label, as designed — *Today* / *Yesterday* / a date — rather than a
  /// clock time, matching the thread's own separators.
  String _dateLabel(BuildContext context) {
    final at = chatRoomSortKey(room);
    final kind = chatDateLabelKind(at, now ?? DateTime.now());

    switch (kind) {
      case ChatDateLabelKind.today:
        return context.l10n.group_chat_today;
      case ChatDateLabelKind.yesterday:
        return context.l10n.group_chat_yesterday;
      case ChatDateLabelKind.thisYear:
      case ChatDateLabelKind.older:
        final locale = intlFormatLocaleOf(context);
        final pattern =
            kind == ChatDateLabelKind.thisYear
                ? DateFormat.MMMd(locale)
                : DateFormat.yMMMd(locale);
        final formatted = pattern.format(at);
        return context.isTibetanLocale ? toTibetanDigits(formatted) : formatted;
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.room, required this.isDark});

  final ChatRoomDTO room;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final url = room.imgUrl;
    final hasUrl = url != null && url.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: ChatRoomTile._avatarSize,
        height: ChatRoomTile._avatarSize,
        child:
            hasUrl
                ? CachedNetworkImageWidget(
                  key: ValueKey(url),
                  imageUrl: url,
                  width: ChatRoomTile._avatarSize,
                  height: ChatRoomTile._avatarSize,
                  fit: BoxFit.cover,
                  errorWidget: _fallback(),
                )
                : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: const Icon(
        AppAssets.usersThree,
        size: 22,
        color: AppColors.grey500,
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      // A stadium, not a circle: BoxShape.circle ignores the width a
      // three-character count needs and clips it.
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        context.isTibetanLocale ? toTibetanDigits(label) : label,
        strutStyle: context.tibetanStrutStyle(11, compact: true),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.surfaceWhite,
        ),
      ),
    );
  }
}
