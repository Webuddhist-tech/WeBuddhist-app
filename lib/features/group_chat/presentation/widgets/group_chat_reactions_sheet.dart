import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reactions.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/core/utils/network_image_utils.dart';

/// One person in the who-reacted list, with the emoji they used.
class _ReactionEntry {
  final ChatMessageReactionUserDTO user;
  final String emoji;
  final bool isMine;

  const _ReactionEntry({
    required this.user,
    required this.emoji,
    required this.isMine,
  });
}

/// Opens the reactions drawer for a message — reached by tapping the badge on
/// the bubble, as in WhatsApp.
///
/// [onToggle] both removes the viewer's own reaction (tapping their row) and
/// applies one picked from [onAddReaction].
Future<void> showChatReactionsSheet(
  BuildContext context, {
  required List<ChatMessageReactionDTO> reactions,
  required String? currentUserId,
  required String? currentUserEmail,
  required ValueChanged<String> onToggle,
  required Future<String?> Function() onAddReaction,
  Map<String, String> avatarUrls = const {},
  String? selfAvatarUrl,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (_) => _ReactionsSheet(
          reactions: reactions,
          currentUserId: currentUserId,
          currentUserEmail: currentUserEmail,
          avatarUrls: avatarUrls,
          selfAvatarUrl: selfAvatarUrl,
          onToggle: onToggle,
          onAddReaction: onAddReaction,
        ),
  );
}

class _ReactionsSheet extends StatefulWidget {
  const _ReactionsSheet({
    required this.reactions,
    required this.currentUserId,
    required this.currentUserEmail,
    required this.avatarUrls,
    required this.selfAvatarUrl,
    required this.onToggle,
    required this.onAddReaction,
  });

  final List<ChatMessageReactionDTO> reactions;
  final String? currentUserId;
  final String? currentUserEmail;
  final Map<String, String> avatarUrls;
  final String? selfAvatarUrl;
  final ValueChanged<String> onToggle;
  final Future<String?> Function() onAddReaction;

  @override
  State<_ReactionsSheet> createState() => _ReactionsSheetState();
}

class _ReactionsSheetState extends State<_ReactionsSheet> {
  /// Null is the All tab.
  String? _selected;

  List<ChatMessageReactionDTO> get _tabs =>
      widget.reactions.where((reaction) => reaction.count > 0).toList();

  int get _total => _tabs.fold<int>(0, (sum, reaction) => sum + reaction.count);

  List<_ReactionEntry> get _entries {
    final entries = <_ReactionEntry>[];

    for (final reaction in _tabs) {
      if (_selected != null && reaction.emoji != _selected) continue;
      var listedMe = false;
      for (final user in reaction.users) {
        final isMine = isChatReactionViewer(
          user,
          currentUserId: widget.currentUserId,
          currentUserEmail: widget.currentUserEmail,
        );
        listedMe = listedMe || isMine;
        entries.add(
          _ReactionEntry(user: user, emoji: reaction.emoji, isMine: isMine),
        );
      }
      // A roster that names nobody — or names people but not the viewer — still
      // has to show their own row, or a reaction they hold offers no way to
      // take it back.
      if (!listedMe && reaction.reactedByMe) {
        entries.add(
          _ReactionEntry(
            user: ChatMessageReactionUserDTO(
              userId: widget.currentUserId ?? '',
              email: widget.currentUserEmail,
            ),
            emoji: reaction.emoji,
            isMine: true,
          ),
        );
      }
    }

    // Own reaction first, as WhatsApp does.
    entries.sort((a, b) {
      if (a.isMine == b.isMine) return 0;
      return a.isMine ? -1 : 1;
    });
    return entries;
  }

  Future<void> _add() async {
    final picked = await widget.onAddReaction();
    if (!mounted || picked == null) return;
    Navigator.of(context).pop();
    widget.onToggle(picked);
  }

  void _remove(String emoji) {
    Navigator.of(context).pop();
    widget.onToggle(emoji);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = _entries;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.grey800 : AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              context.l10n.group_chat_reactions_count(_total),
              strutStyle: context.tibetanStrutStyle(18, compact: true),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _AddTab(isDark: isDark, onTap: _add),
                // A single emoji needs no All tab — the one chip covers it.
                if (_tabs.length > 1)
                  _Tab(
                    label: context.l10n.group_chat_reactions_all,
                    count: _total,
                    isSelected: _selected == null,
                    isDark: isDark,
                    onTap: () => setState(() => _selected = null),
                  ),
                for (final reaction in _tabs)
                  _Tab(
                    emoji: reaction.emoji,
                    count: reaction.count,
                    isSelected:
                        _selected == reaction.emoji ||
                        (_tabs.length == 1 && _selected == null),
                    isDark: isDark,
                    onTap: () => setState(() => _selected = reaction.emoji),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _ReactionRow(
                  entry: entry,
                  avatarUrl:
                      entry.isMine
                          ? (widget.selfAvatarUrl ??
                              widget.avatarUrls[entry.user.userId])
                          : widget.avatarUrls[entry.user.userId],
                  isDark: isDark,
                  onRemove: entry.isMine ? () => _remove(entry.emoji) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTab extends StatelessWidget {
  const _AddTab({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            AppAssets.plus,
            size: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.count,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    this.label,
    this.emoji,
  });

  final String? label;
  final String? emoji;
  final int count;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted = '$count';
    final countText =
        context.isTibetanLocale ? toTibetanDigits(formatted) : formatted;
    final foreground =
        isSelected
            ? AppColors.surfaceWhite
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.grey900
                    : (isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceWhite),
            borderRadius: BorderRadius.circular(20),
            border:
                isSelected
                    ? null
                    : Border.all(
                      color:
                          isDark ? AppColors.cardBorderDark : AppColors.grey300,
                    ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null)
                Text(emoji!, style: const TextStyle(fontSize: 14))
              else
                Text(
                  label ?? '',
                  strutStyle: context.tibetanStrutStyle(14, compact: true),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                countText,
                style: TextStyle(fontSize: 14, color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionRow extends StatelessWidget {
  const _ReactionRow({
    required this.entry,
    required this.avatarUrl,
    required this.isDark,
    required this.onRemove,
  });

  final _ReactionEntry entry;
  final String? avatarUrl;
  final bool isDark;

  /// Non-null only on the viewer's own row: tapping it removes the reaction.
  final VoidCallback? onRemove;

  static const double _avatarSize = 40;

  @override
  Widget build(BuildContext context) {
    // ChatMessageReactionUserDTO carries `name` but no avatar, so these rows
    // show initials.
    final resolvedName =
        chatSenderDisplayName(
          messageName: entry.user.name,
          senderEmail: entry.user.email,
        ) ??
        context.l10n.group_chat_unknown_sender;
    final displayName =
        entry.isMine ? context.l10n.group_chat_you : resolvedName;
    final subtitle =
        entry.isMine
            ? context.l10n.group_chat_tap_to_remove
            : context.l10n.group_chat_reacted;

    return InkWell(
      onTap: onRemove,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            _Avatar(
              avatarUrl: avatarUrl,
              displayName: resolvedName,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    strutStyle: context.tibetanStrutStyle(15, compact: true),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(entry.emoji, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatarUrl,
    required this.displayName,
    required this.isDark,
  });

  /// Null for anyone who has not posted in the loaded window — initials then.
  final String? avatarUrl;
  final String displayName;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final hasUrl = url != null && url.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: _ReactionRow._avatarSize,
        height: _ReactionRow._avatarSize,
        child:
            hasUrl
                ? CachedNetworkImageWidget(
                  key: networkImageKey(url),
                  imageUrl: url,
                  width: _ReactionRow._avatarSize,
                  height: _ReactionRow._avatarSize,
                  fit: BoxFit.cover,
                  errorWidget: _initials(),
                )
                : _initials(),
      ),
    );
  }

  Widget _initials() {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Center(
        child: Text(
          chatSenderInitials(displayName),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.grey500 : AppColors.grey600,
          ),
        ),
      ),
    );
  }
}
