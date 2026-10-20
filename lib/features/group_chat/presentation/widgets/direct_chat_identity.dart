import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_rooms_list.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';

/// The other person in a direct chat: their picture, or their initial on a
/// warm tint (the "W" of the WeBuddhist Team in the mocks).
class DirectChatAvatar extends StatelessWidget {
  const DirectChatAvatar({super.key, required this.room, required this.size});

  final ChatRoomDTO room;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = room.imgUrl;
    final hasUrl = url != null && url.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child:
            hasUrl
                ? CachedNetworkImageWidget(
                  key: ValueKey(url),
                  imageUrl: url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorWidget: _initial(isDark),
                )
                : _initial(isDark),
      ),
    );
  }

  Widget _initial(bool isDark) {
    return ColoredBox(
      color:
          isDark
              ? AppColors.chatOutgoingBubbleDark
              : AppColors.chatOutgoingBubble,
      child: Center(
        child: Text(
          // One letter, not [chatSenderInitials]' two: the Team is "W".
          chatSenderInitials(chatRoomTitle(room)).characters.first,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.accentGold : AppColors.accentGoldDarkest,
          ),
        ),
      ),
    );
  }
}

/// Marks the WeBuddhist Team chat, next to its name.
class OfficialChatBadge extends StatelessWidget {
  const OfficialChatBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark ? AppColors.eventInPersonChipDark : AppColors.eventInPersonChip;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        context.l10n.chat_official_badge,
        strutStyle: context.tibetanStrutStyle(10, compact: true),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
