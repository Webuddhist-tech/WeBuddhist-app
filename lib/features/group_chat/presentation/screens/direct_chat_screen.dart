import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/feedback/domain/help_context_line.dart';
import 'package:flutter_pecha/features/feedback/presentation/utils/help_topic_l10n.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/direct_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_link_spans.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_rooms_list.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/direct_chat_identity.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_composer.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_composer_link_preview.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_reply_preview.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_selection_header.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_thread.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/providers/push_notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A direct chat between the viewer and one other person — in practice the
/// WeBuddhist Team, or, for the Team account, one of the people who wrote in.
///
/// The thread is group chat's own, so reactions, replies, copy, delete and
/// report work the same here. The session — room, socket, sending — lives in
/// [DirectChatNotifier]; this is the view, the composer and the push hooks.
class DirectChatScreen extends ConsumerStatefulWidget {
  const DirectChatScreen({super.key, required this.roomId, this.initialRoom});

  final String roomId;

  /// The room as the Chats list already has it, so the header shows at once.
  final ChatRoomDTO? initialRoom;

  @override
  ConsumerState<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends ConsumerState<DirectChatScreen> {
  final _bodyController = TextEditingController();
  final _bodyFocusNode = FocusNode();

  /// Read through the container rather than `ref`, so the push stream and the
  /// filter never touch a deactivated element (see `GroupChatScreen`).
  late final ProviderContainer _providers;
  StreamSubscription<PushMessage>? _pushSub;
  ModalRoute<dynamic>? _route;
  bool _disposed = false;
  bool _sending = false;

  /// The message a reply is being composed for, quoted above the composer.
  ChatMessageDTO? _replyingTo;

  /// Messages selected in the thread, or null. While set, the header becomes
  /// the selection bar. The thread owns the selection; this is a view of it.
  ChatSelection? _selection;

  /// Draft link previews the sender closed, so a dismissed card does not come
  /// straight back on the next keystroke.
  final _dismissedPreviews = <String>{};

  DirectChatNotifier get _notifier =>
      _providers.read(directChatProvider(widget.roomId).notifier);

  @override
  void initState() {
    super.initState();
    _providers = ProviderScope.containerOf(context, listen: false);
    _pushSub = _providers
        .read(pushMessagingRepositoryProvider)
        .onForegroundMessage
        .listen(_onForegroundPush);
    // The banner for a message this screen already shows would only lead
    // back here.
    _providers.read(foregroundPushFilterProvider).claim(this, _showsPush);

    final room = widget.initialRoom;
    if (room != null) {
      // After the frame: seeding during build would modify a provider while
      // the tree is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) _notifier.seedRoom(room);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route ??= ModalRoute.of(context);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_pushSub?.cancel());
    _providers.read(foregroundPushFilterProvider).release(this);
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  bool _showsPush(Map<String, dynamic> data) {
    if (_disposed) return false;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return false;
    }
    if (!(_route?.isCurrent ?? false)) return false;
    return chatPushTargets(data, roomId: widget.roomId);
  }

  /// The socket should already have delivered the message. A push for this
  /// room is the backstop for one that went quiet: the thread catches up and
  /// the socket reopens if it is down.
  void _onForegroundPush(PushMessage message) {
    if (_disposed) return;
    if (!chatPushTargets(message.data, roomId: widget.roomId)) return;
    unawaited(_notifier.refresh());
  }

  /// Starts a reply. The intent is always to type next, so focus follows.
  void _startReply(ChatMessageDTO message) {
    setState(() => _replyingTo = message);
    _bodyFocusNode.requestFocus();
  }

  void _cancelReply() => setState(() => _replyingTo = null);

  void _onSelectionChanged(ChatSelection? selection) {
    if (!mounted || _disposed) return;
    setState(() => _selection = selection);
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _sending) return;
    final parent = _replyingTo;

    setState(() => _sending = true);
    try {
      final result = await _notifier.send(
        body,
        parentMessageId: parent?.id,
      );
      if (!mounted) return;
      result.fold(
        (failure) {
          // The quoted message is gone. Drop the quote but keep the draft,
          // so sending again posts it as an ordinary message.
          if (chatSendErrorKind(failure) == ChatSendErrorKind.invalidParent) {
            setState(() => _replyingTo = null);
          }
          presentChatSendError(context, failure);
        },
        (_) {
          _bodyController.clear();
          setState(() => _replyingTo = null);
        },
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// A Help & contact message shows without its first line, which
  /// [_messageHeader] draws above it instead.
  ChatMessageDTO _presentMessage(ChatMessageDTO message) {
    if (message.deletedAt != null) return message;
    final parsed = parseHelpContext(message.body);
    return parsed == null ? message : message.copyWith(body: parsed.body);
  }

  Widget? _messageHeader(BuildContext context, ChatMessageDTO message) {
    if (message.deletedAt != null) return null;
    final parsed = parseHelpContext(message.body);
    if (parsed == null) return null;
    return _HelpContextLabel(helpContext: parsed.context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(directChatProvider(widget.roomId));
    final room = state.room ?? widget.initialRoom;
    final user = ref.watch(userProvider).user;
    final canSend = (room?.otherUserId?.trim() ?? '').isNotEmpty;
    final selection = _selection;
    final replyingTo = _replyingTo;

    return Scaffold(
      // The composer pads itself for the keyboard, as in group chat.
      resizeToAvoidBottomInset: false,
      backgroundColor:
          isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // The selection bar and the header share a footprint, so the
            // thread does not jump when they swap.
            selection == null
                ? _DirectChatHeader(room: room, isDark: isDark)
                : GroupChatSelectionHeader(
                  isDark: isDark,
                  selection: selection,
                ),
            Expanded(
              child: GroupChatThread(
                roomId: widget.roomId,
                onReply: _startReply,
                onSelectionChanged: _onSelectionChanged,
                showIdentity: false,
                presentMessage: _presentMessage,
                messageHeader: _messageHeader,
              ),
            ),
          ],
        ),
      ),
      // In the bottom slot rather than the body column, so a floating
      // snackbar is laid out above the composer instead of over it.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Watches the draft directly, so the rest of the screen does not
          // rebuild on every keystroke.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _bodyController,
            builder: (context, value, _) {
              final url = firstChatLinkUrl(value.text);
              if (url == null || _dismissedPreviews.contains(url)) {
                return const SizedBox.shrink();
              }
              return GroupChatComposerLinkPreview(
                url: url,
                onDismiss: () => setState(() => _dismissedPreviews.add(url)),
              );
            },
          ),
          if (replyingTo != null)
            GroupChatReplyPreview(
              message: replyingTo,
              onCancel: _cancelReply,
              isOwnMessage: isSelfChatMessage(
                senderId: replyingTo.senderId,
                senderEmail: replyingTo.senderEmail,
                currentUserId: user?.id?.trim(),
                currentUserEmail: user?.email,
              ),
            ),
          GroupChatComposer(
            controller: _bodyController,
            focusNode: _bodyFocusNode,
            hintText: context.l10n.group_chat_message_hint,
            isSending: _sending,
            onSubmit: _send,
            enabled: canSend,
            avatarUrl: user?.avatarUrl,
            displayName:
                joinChatName(user?.firstName, user?.lastName) ?? user?.email,
          ),
        ],
      ),
    );
  }
}

/// Back, the other person's picture and name, and for the WeBuddhist Team
/// when they usually reply. Laid out like `GroupChatHeader`, so the selection
/// bar takes its place without the thread moving.
class _DirectChatHeader extends StatelessWidget {
  const _DirectChatHeader({required this.room, required this.isDark});

  final ChatRoomDTO? room;
  final bool isDark;

  static const double _avatarSize = 40;

  @override
  Widget build(BuildContext context) {
    final room = this.room;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          if (room == null)
            const Spacer()
          else ...[
            DirectChatAvatar(room: room, size: _avatarSize),
            const SizedBox(width: 12),
            Expanded(child: _Identity(room: room, isDark: isDark)),
          ],
          // Balances the back button, as the group header's bell slot does.
          const SizedBox(width: kMinInteractiveDimension),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.room, required this.isDark});

  final ChatRoomDTO room;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          chatRoomTitle(room),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          strutStyle: context.tibetanStrutStyle(16, compact: true),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        if (room.isOfficial)
          Text(
            context.l10n.chat_team_reply_time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            strutStyle: context.tibetanStrutStyle(12, compact: true),
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _HelpContextLabel extends StatelessWidget {
  const _HelpContextLabel({required this.helpContext});

  final HelpContext helpContext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = helpContextLabel(context.l10n, helpContext);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
      child: Text(
        context.isTibetanLocale ? toTibetanDigits(label) : label,
        textAlign: TextAlign.center,
        strutStyle: context.tibetanStrutStyle(12),
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}
