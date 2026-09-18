import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_selection.dart';

/// A live selection, as the thread reports it to the screen.
///
/// Carries the count, which actions apply, and a callback for each — so the
/// header stays a dumb view and the thread, which owns the rows and the
/// repository calls, does the work.
class ChatSelection {
  const ChatSelection({
    required this.count,
    required this.gates,
    required this.onReply,
    required this.onCopy,
    required this.onDelete,
    required this.onReport,
    required this.onClear,
  });

  final int count;
  final ChatSelectionGates gates;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final VoidCallback onClear;
}

/// What the chat header becomes while messages are selected: a back arrow
/// that clears the selection, the count, and the actions that apply.
///
/// Same footprint as [GroupChatHeader] so the thread does not jump when the
/// two swap.
class GroupChatSelectionHeader extends StatelessWidget {
  const GroupChatSelectionHeader({
    super.key,
    required this.isDark,
    required this.selection,
  });

  final bool isDark;
  final ChatSelection selection;

  @override
  Widget build(BuildContext context) {
    final gates = selection.gates;
    final iconColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final count = '${selection.count}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            color: iconColor,
            onPressed: selection.onClear,
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
          ),
          Expanded(
            child: Text(
              context.isTibetanLocale ? toTibetanDigits(count) : count,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              strutStyle: context.tibetanStrutStyle(18, compact: true),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ),
          if (gates.canReply)
            IconButton(
              icon: const Icon(AppAssets.arrowBendUpLeft),
              color: iconColor,
              onPressed: selection.onReply,
              tooltip: context.l10n.group_chat_reply,
            ),
          if (gates.canCopy)
            IconButton(
              icon: const Icon(AppAssets.copy),
              color: iconColor,
              onPressed: selection.onCopy,
              tooltip: context.l10n.group_chat_copy,
            ),
          if (gates.showDelete)
            IconButton(
              icon: const Icon(AppAssets.trash),
              color: iconColor,
              disabledColor: isDark ? AppColors.grey600 : AppColors.grey400,
              // Greyed, not hidden, on a mixed selection: only own messages
              // can be deleted, and the icon staying put says so.
              onPressed: gates.canDelete ? selection.onDelete : null,
              tooltip: context.l10n.group_chat_delete,
            ),
          if (gates.canReport)
            IconButton(
              icon: const Icon(AppAssets.warning),
              color: AppColors.error,
              onPressed: selection.onReport,
              tooltip: context.l10n.group_chat_report,
            ),
        ],
      ),
    );
  }
}
