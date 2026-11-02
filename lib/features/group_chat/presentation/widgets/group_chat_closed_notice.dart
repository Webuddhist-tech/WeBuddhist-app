import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Replaces the composer once the room has been closed.
class GroupChatClosedNotice extends StatelessWidget {
  const GroupChatClosedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottom),
      child: Text(
        context.l10n.chat_room_closed,
        textAlign: TextAlign.center,
        strutStyle: context.tibetanStrutStyle(14),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}
