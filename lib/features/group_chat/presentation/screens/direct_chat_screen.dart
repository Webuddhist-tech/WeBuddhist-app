import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/feedback/domain/help_context_line.dart';
import 'package:flutter_pecha/features/feedback/presentation/utils/help_topic_l10n.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/direct_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_rooms_list.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_thread_rows.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/direct_chat_identity.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_composer.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_date_separator.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_error_state.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_message_bubble.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/providers/push_notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A direct chat between the viewer and one other person — in practice the
/// WeBuddhist Team, or, for the Team account, one of the people who wrote in.
class DirectChatScreen extends ConsumerStatefulWidget {
  const DirectChatScreen({super.key, required this.roomId, this.initialRoom});

  final String roomId;

  /// The room as the Chats list already has it, so the header shows at once.
  final ChatRoomDTO? initialRoom;

  @override
  ConsumerState<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends ConsumerState<DirectChatScreen>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _bodyController = TextEditingController();
  final _bodyFocusNode = FocusNode();

  /// Read through the container rather than `ref`, so the push stream and the
  /// filter never touch a deactivated element (see `GroupChatScreen`).
  late final ProviderContainer _providers;
  StreamSubscription<PushMessage>? _pushSub;
  ModalRoute<dynamic>? _route;
  bool _disposed = false;
  bool _sending = false;

  /// How close to the oldest loaded message the list gets before the next
  /// page is asked for.
  static const double _loadMoreThreshold = 400;

  DirectChatNotifier get _notifier =>
      _providers.read(directChatProvider(widget.roomId).notifier);

  @override
  void initState() {
    super.initState();
    _providers = ProviderScope.containerOf(context, listen: false);
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
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
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_pushSub?.cancel());
    _providers.read(foregroundPushFilterProvider).release(this);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_disposed) _notifier.refresh();
  }

  bool _showsPush(Map<String, dynamic> data) {
    if (_disposed) return false;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return false;
    }
    if (!(_route?.isCurrent ?? false)) return false;
    return chatPushTargets(data, roomId: widget.roomId);
  }

  void _onForegroundPush(PushMessage message) {
    if (_disposed) return;
    if (!chatPushTargets(message.data, roomId: widget.roomId)) return;
    _notifier.refresh();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // The list is reversed, so the oldest messages are at the max extent.
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _notifier.loadMore();
    }
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final result = await _notifier.send(body);
      if (!mounted) return;
      result.fold(
        (failure) => presentChatSendError(context, failure),
        (_) => _bodyController.clear(),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(directChatProvider(widget.roomId));
    final room = state.room ?? widget.initialRoom;
    final user = ref.watch(userProvider).user;
    final canSend = (room?.otherUserId?.trim() ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _DirectChatHeader(room: room),
      body: Column(
        children: [
          Expanded(child: _body(state, user)),
          GroupChatComposer(
            controller: _bodyController,
            focusNode: _bodyFocusNode,
            hintText: context.l10n.group_chat_message_hint,
            isSending: _sending,
            onSubmit: _send,
            enabled: canSend,
            avatarUrl: user?.avatarUrl,
            displayName: joinChatName(user?.firstName, user?.lastName),
          ),
        ],
      ),
    );
  }

  Widget _body(DirectChatState state, User? user) {
    if (!state.hasLoaded && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.messages.isEmpty && state.error != null) {
      return GroupChatErrorState(onRetry: _notifier.refresh);
    }

    if (state.messages.isEmpty) return const _EmptyDirectChat();

    final rows = buildChatThreadRows(state.messages);
    final viewerId = user?.id?.trim() ?? '';
    final viewerEmail = user?.email;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: rows.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= rows.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final row = rows[index];
          switch (row) {
            case ChatDateRow(day: final day):
              return GroupChatDateSeparator(day: day);
            case ChatMessageRow(
              message: final message,
              isRunStart: final isRunStart,
            ):
              return _DirectMessageRow(
                message: message,
                isRunStart: isRunStart,
                isSelf: isSelfChatMessage(
                  senderId: message.senderId,
                  senderEmail: message.senderEmail,
                  currentUserId: viewerId,
                  currentUserEmail: viewerEmail,
                ),
              );
          }
        },
      ),
    );
  }
}

class _DirectChatHeader extends StatelessWidget implements PreferredSizeWidget {
  const _DirectChatHeader({required this.room});

  final ChatRoomDTO? room;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final room = this.room;

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      toolbarHeight: preferredSize.height,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(AppAssets.arrowLeft),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      shape: Border(
        bottom: BorderSide(
          color:
              isDark
                  ? AppColors.surfaceWhite.withValues(alpha: 0.08)
                  : AppColors.grey100,
        ),
      ),
      title:
          room == null
              ? null
              : Row(
                children: [
                  DirectChatAvatar(room: room, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          chatRoomTitle(room),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          strutStyle: context.tibetanStrutStyle(
                            16,
                            compact: true,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (room.isOfficial)
                          Text(
                            context.l10n.chat_team_reply_time,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            strutStyle: context.tibetanStrutStyle(
                              12,
                              compact: true,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

/// One message, with the "Sent from Help & contact" line above it when the
/// backend wrote one in.
class _DirectMessageRow extends StatelessWidget {
  const _DirectMessageRow({
    required this.message,
    required this.isRunStart,
    required this.isSelf,
  });

  final ChatMessageDTO message;
  final bool isRunStart;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final parsed =
        message.deletedAt == null ? parseHelpContext(message.body) : null;
    final bubble = GroupChatMessageBubble(
      message: parsed == null ? message : message.copyWith(body: parsed.body),
      isSelf: isSelf,
      isRunStart: isRunStart,
      showIdentity: false,
    );
    if (parsed == null) return bubble;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_HelpContextLabel(helpContext: parsed.context), bubble],
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

class _EmptyDirectChat extends StatelessWidget {
  const _EmptyDirectChat();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppAssets.chatCircleDots,
              size: 40,
              color: isDark ? AppColors.grey600 : AppColors.grey400,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.group_chat_empty_title,
              textAlign: TextAlign.center,
              strutStyle: context.tibetanStrutStyle(16, compact: true),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
