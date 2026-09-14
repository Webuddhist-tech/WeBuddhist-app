import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reactions.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_report_feedback.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_report_reason.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_thread_rows.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_date_separator.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_delete_dialog.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_emoji_picker.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_empty_state.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_message_bubble.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_message_menu.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_report_sheet.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_reactions_sheet.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_swipe_to_reply.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The message list for a joined room.
///
/// Reversed so index 0 is the newest message at the bottom: "load older" is a
/// tail append and the newest row stays pinned above the keyboard for free.
class GroupChatThread extends ConsumerStatefulWidget {
  const GroupChatThread({
    super.key,
    required this.roomId,
    required this.groupId,
    required this.onReply,
  });

  final String roomId;
  final String groupId;

  /// Starts a reply in the composer, which the screen owns.
  final ValueChanged<ChatMessageDTO> onReply;

  @override
  ConsumerState<GroupChatThread> createState() => _GroupChatThreadState();
}

class _GroupChatThreadState extends ConsumerState<GroupChatThread> {
  final _scrollController = ScrollController();

  /// One key per message so the long-press menu can measure the row it lifts.
  final _rowKeys = <String, GlobalKey>{};

  /// The newest message already seen, so an arrival can be told from a rebuild.
  String? _newestId;

  /// How close to the newest message counts as "following the conversation".
  /// Reversed list, so offset 0 is the bottom.
  static const double _followThreshold = 120;

  /// Bounds the walk towards an off-screen quote, so a parent that never
  /// materialises cannot spin.
  static const int _maxScrollHops = 20;

  /// Bounds how far back the thread will page to find a quoted original.
  static const int _maxLoadHops = 12;

  /// Offset past which the jump-to-latest button appears.
  static const double _jumpButtonThreshold = 400;

  bool _showJumpToLatest = false;

  /// The message a quote jumped to, tinted briefly so the eye can find it in
  /// a wall of text. Long enough to notice, short enough not to look selected.
  static const Duration _highlightDuration = Duration(milliseconds: 900);
  String? _highlightedId;
  Timer? _highlightTimer;

  /// Distance from the reversed end at which the next page is requested.
  static const double _loadMoreThreshold = 320;

  /// The viewer's backend user id — the id space chat's `sender_id` and
  /// reaction `user_ids` use. Read from the profile rather than passed in, so
  /// a session that loads `/users/info` after this screen opens starts
  /// matching on it without the thread holding a stale copy.
  String get _viewerId => ref.read(userProvider).user?.id?.trim() ?? '';

  String? get _viewerEmail => ref.read(userProvider).user?.email;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _flashHighlight(String messageId) {
    _highlightTimer?.cancel();
    setState(() => _highlightedId = messageId);
    _highlightTimer = Timer(_highlightDuration, () {
      if (mounted) setState(() => _highlightedId = null);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(groupChatThreadProvider(widget.roomId).notifier).loadMore();
    }

    final shouldShow = position.pixels > _jumpButtonThreshold;
    if (shouldShow != _showJumpToLatest) {
      setState(() => _showJumpToLatest = shouldShow);
    }
  }

  GlobalKey _rowKey(String messageId) =>
      _rowKeys.putIfAbsent(messageId, GlobalKey.new);

  bool get _isNearBottom =>
      !_scrollController.hasClients ||
      _scrollController.offset <= _followThreshold;

  /// Brings the newest message into view. The list is reversed, so the bottom
  /// is offset zero.
  void _scrollToNewest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  /// Follows a newly arrived message.
  ///
  /// Own messages always scroll — you should see what you just sent, wherever
  /// you were reading. Someone else's only scrolls when already near the
  /// bottom, so a message arriving does not yank you out of older history you
  /// are reading.
  void _onNewestChanged(ChatMessageDTO newest, bool isMine) {
    final follow = isMine || _isNearBottom;
    _newestId = newest.id;
    if (!follow) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToNewest();
    });
  }

  /// Scrolls to a quoted original.
  ///
  /// `ListView.builder` only keeps rows near the viewport alive, so a parent
  /// that is off screen has no context to scroll to yet — which is why tapping
  /// a quote used to work for nearby originals and do nothing for distant
  /// ones. Older messages sit at a larger offset in this reversed list, so the
  /// search walks that way a viewport at a time, building rows as it goes,
  /// until the target materialises and `ensureVisible` can place it exactly.
  Future<void> _scrollToMessage(String messageId) async {
    if (await _ensureMessageVisible(messageId)) return;

    // Older than the loaded window: page back until it appears, so a quote
    // still reaches its original however far up the thread it sits.
    if (!await _loadUntilPresent(messageId)) return;

    for (var attempt = 0; attempt < _maxScrollHops; attempt++) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final next = (position.pixels + position.viewportDimension * 0.85).clamp(
        0.0,
        position.maxScrollExtent,
      );
      // Already at the oldest loaded row: nowhere further to look.
      if (next <= position.pixels) return;

      _scrollController.jumpTo(next);
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) return;
      if (await _ensureMessageVisible(messageId)) return;
    }
  }

  /// Pages back until [messageId] is in the loaded window.
  ///
  /// Returns false when the thread runs out of history first, or when the walk
  /// is bounded out — a quote whose original was never in this room cannot be
  /// found by paging forever.
  Future<bool> _loadUntilPresent(String messageId) async {
    final provider = groupChatThreadProvider(widget.roomId);
    for (var attempt = 0; attempt < _maxLoadHops; attempt++) {
      final state = ref.read(provider);
      if (state.messages.any((message) => message.id == messageId)) return true;
      if (!state.hasMore) return false;

      await ref.read(provider.notifier).loadMore();
      if (!mounted) return false;
      // `loadMore` returns immediately while another page is already in
      // flight, so yield a frame rather than spinning through the budget.
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) return false;
    }
    return ref
        .read(provider)
        .messages
        .any((message) => message.id == messageId);
  }

  /// Places [messageId] in view when its row is currently built.
  Future<bool> _ensureMessageVisible(String messageId) async {
    final target = _rowKeys[messageId]?.currentContext;
    if (target == null) return false;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.3,
    );
    if (mounted) _flashHighlight(messageId);
    return true;
  }

  Future<void> _toggleReaction(String messageId, String emoji) async {
    // Resolved before the await: leaving this screen mid-request deactivates
    // the element, and an ancestor lookup then throws rather than showing
    // anything.
    final messenger = ScaffoldMessenger.of(context);
    final failedMessage = context.l10n.group_chat_reaction_failed;
    final failure = await ref
        .read(groupChatThreadProvider(widget.roomId).notifier)
        .toggleReaction(
          messageId,
          emoji,
          roomIdForCall: widget.roomId,
          currentUserId: _viewerId,
          currentUserEmail: _viewerEmail,
        );
    if (!mounted || failure == null) return;
    messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
  }

  void _showReactions(ChatMessageDTO message) {
    if (message.reactions.isEmpty) return;
    final user = ref.read(userProvider).user;
    showChatReactionsSheet(
      context,
      reactions: message.reactions,
      currentUserId: user?.id?.trim() ?? '',
      currentUserEmail: user?.email,
      // `ChatMessageReactionUserDTO` carries no avatar, but every loaded
      // message does — and reactors are almost always people who have posted
      // in the thread. Free lookup, no request.
      avatarUrls: _avatarsBySenderId(),
      selfAvatarUrl: user?.avatarUrl,
      onToggle: (emoji) => _toggleReaction(message.id, emoji),
      onAddReaction: () => showChatEmojiPicker(context),
    );
  }

  Map<String, String> _avatarsBySenderId() {
    final messages = ref.read(groupChatThreadProvider(widget.roomId)).messages;
    return {
      for (final message in messages)
        if ((message.senderAvatarUrl ?? '').isNotEmpty)
          message.senderId: message.senderAvatarUrl!,
    };
  }

  Future<void> _openMenu(ChatMessageDTO message, Widget row) async {
    final renderObject =
        _rowKeys[message.id]?.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final anchor = renderObject.localToGlobal(Offset.zero) & renderObject.size;

    final result = await showChatMessageMenu(
      context,
      anchor: anchor,
      message: row,
      myEmoji: currentChatReactionEmoji(message.reactions),
      // Reporting your own message is meaningless, and the server refuses it
      // with a generic 400 — so the gate is here. It waits for the viewer's
      // identity: until the profile has loaded, `_isSelf` cannot say "mine"
      // about anything, and "not mine" is then no grounds for offering it.
      canReport:
          _isViewerKnown && !_isSelf(message) && message.deletedAt == null,
      // Sender-only, and never twice. The backend enforces this too; the gate
      // is here because the API answers a non-sender attempt generically.
      canDelete: _canDelete(message),
    );
    if (!mounted || result == null) return;

    switch (result) {
      case ChatMessageReact(emoji: final emoji):
        await _toggleReaction(message.id, emoji);
      case ChatMessageMoreEmoji():
        final picked = await showChatEmojiPicker(context);
        if (!mounted || picked == null) return;
        await _toggleReaction(message.id, picked);
      case ChatMessageActionPicked(action: final action):
        await _onAction(action, message);
    }
  }

  bool get _isViewerKnown => isChatViewerKnown(
    currentUserId: _viewerId,
    currentUserEmail: _viewerEmail,
  );

  bool _isSelf(ChatMessageDTO message) {
    return isSelfChatMessage(
      senderId: message.senderId,
      senderEmail: message.senderEmail,
      currentUserId: _viewerId,
      currentUserEmail: _viewerEmail,
    );
  }

  /// Asks why, then posts it.
  Future<void> _reportMessage(ChatMessageDTO message) async {
    final submission = await showChatReportSheet(context);
    if (!mounted || submission == null) return;

    // Everything the request and its Retry will need, resolved once, here,
    // while the element is live. The snackbar goes on the app's root
    // messenger and outlives this thread — the member can back out of the
    // chat and still tap Retry — so nothing past this point may reach back
    // through `context` or `ref`.
    final l10n = context.l10n;
    final report = _ChatReport(
      repository: ref.read(groupChatRepositoryProvider),
      connectivity: ref.read(connectivityServiceProvider),
      messenger: ScaffoldMessenger.of(context),
      l10n: l10n,
      roomId: widget.roomId,
      messageId: message.id,
      reason: chatReportReasonWireValue(submission.reason),
      description: chatReportDescription(
        submission.reason,
        note: submission.note,
        offTopicLabel: l10n.group_chat_report_reason_off_topic,
      ),
    );
    await report.send();
  }

  bool _canDelete(ChatMessageDTO message) {
    return message.deletedAt == null && _isSelf(message);
  }

  Future<void> _deleteMessage(ChatMessageDTO message) async {
    if (!await confirmChatMessageDelete(context)) return;
    if (!mounted) return;

    // Resolved before the await for the same reason as `_toggleReaction`:
    // leaving the screen mid-request deactivates this element.
    final messenger = ScaffoldMessenger.of(context);
    final failedMessage = context.l10n.group_chat_delete_failed;

    final failure = await ref
        .read(groupChatThreadProvider(widget.roomId).notifier)
        .deleteMessage(message.id);

    if (!mounted || failure == null) return;
    messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
  }

  Future<void> _onAction(
    ChatMessageAction action,
    ChatMessageDTO message,
  ) async {
    switch (action) {
      case ChatMessageAction.copy:
        final messenger = ScaffoldMessenger.of(context);
        final copied = context.l10n.group_chat_copied;
        await Clipboard.setData(ClipboardData(text: message.body));
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(copied)));
      case ChatMessageAction.reply:
        widget.onReply(message);
      case ChatMessageAction.delete:
        await _deleteMessage(message);
      case ChatMessageAction.report:
        await _reportMessage(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupChatThreadProvider(widget.roomId));
    final notifier = ref.read(groupChatThreadProvider(widget.roomId).notifier);
    final user = ref.watch(userProvider).user;

    ref.listen(groupChatThreadProvider(widget.roomId), (_, next) {
      if (next.messages.isEmpty) return;
      final newest = next.messages.first;
      // Only an arrival counts; `skip`, loading flags and reaction edits all
      // rebuild without changing which message is newest.
      if (newest.id == _newestId) return;
      _onNewestChanged(
        newest,
        isSelfChatMessage(
          senderId: newest.senderId,
          senderEmail: newest.senderEmail,
          currentUserId: _viewerId,
          currentUserEmail: _viewerEmail,
        ),
      );
    });

    if (!state.hasLoaded && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.messages.isEmpty) {
      return _dismissKeyboardOnTap(_ThreadError(onRetry: notifier.retry));
    }

    if (state.messages.isEmpty) {
      return _dismissKeyboardOnTap(const GroupChatEmptyState());
    }

    final rows = buildChatThreadRows(state.messages);

    // No keyboard inset here. The composer sits in the same Column and grows
    // by the inset itself, which already shrinks this Expanded to the space
    // above the field — adding it again would double the gap under the newest
    // message.
    return _dismissKeyboardOnTap(
      Stack(
        children: [
          _buildList(state, rows, user),
          if (_showJumpToLatest)
            Positioned(
              right: 16,
              bottom: 12,
              child: _JumpToLatestButton(onTap: _scrollToNewest),
            ),
        ],
      ),
    );
  }

  Widget _buildList(
    GroupChatThreadState state,
    List<ChatThreadRow> rows,
    User? user,
  ) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      // Dragging the thread closes the keyboard, as every chat app does. On
      // iOS this is the primary way out — there is no system back button to
      // dismiss it, which is why the keyboard felt stuck there and not on
      // Android.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: rows.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= rows.length) return const _LoadingMoreFooter();

        final row = rows[index];
        switch (row) {
          case ChatDateRow(day: final day):
            return GroupChatDateSeparator(day: day);
          case ChatMessageRow(
            message: final message,
            isRunStart: final isRunStart,
          ):
            final isDeleted = message.deletedAt != null;

            GroupChatMessageBubble bubble({VoidCallback? onLongPress}) {
              return GroupChatMessageBubble(
                message: message,
                isSelf: isSelfChatMessage(
                  senderId: message.senderId,
                  senderEmail: message.senderEmail,
                  currentUserId: user?.id?.trim() ?? '',
                  currentUserEmail: user?.email,
                ),
                isRunStart: isRunStart,
                selfAvatarUrl: user?.avatarUrl,
                selfDisplayName: joinChatName(user?.firstName, user?.lastName),
                onLongPress: onLongPress,
                isHighlighted: message.id == _highlightedId,
                onShowReactions: () => _showReactions(message),
                onTapQuote:
                    message.parent == null
                        ? null
                        : () => _scrollToMessage(message.parent!.id),
              );
            }

            // The menu re-renders the row over its own blurred backdrop, so it
            // gets a copy without the long-press handler.
            final lifted = bubble();

            // Nothing on offer for a message that is gone: no menu to react,
            // quote or copy from, and nothing to swipe a reply at.
            if (isDeleted) {
              return KeyedSubtree(key: _rowKey(message.id), child: lifted);
            }

            return KeyedSubtree(
              key: _rowKey(message.id),
              // Swipe and long-press reach the same reply path, so the two
              // gestures cannot disagree about what a reply means.
              child: GroupChatSwipeToReply(
                onReply: () => widget.onReply(message),
                child: bubble(onLongPress: () => _openMenu(message, lifted)),
              ),
            );
        }
      },
    );
  }

  /// Taps that no child claims fall through to here and drop focus, so tapping
  /// the thread closes the keyboard.
  Widget _dismissKeyboardOnTap(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
  }
}

/// Jumps straight back to the newest message. Appears only once the thread
/// has been scrolled away from the bottom, so it never covers a message the
/// user is already reading at the end of the conversation.
class _JumpToLatestButton extends StatelessWidget {
  const _JumpToLatestButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            AppAssets.caretDoubleDown,
            size: 20,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _LoadingMoreFooter extends StatelessWidget {
  const _LoadingMoreFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ThreadError extends StatelessWidget {
  const _ThreadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.group_chat_load_failed,
              textAlign: TextAlign.center,
              strutStyle: context.tibetanStrutStyle(14),
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.group_chat_retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// One report, with everything needed to send it and to say how it went.
///
/// Self-contained on purpose: the Retry on its snackbar sends this same
/// object again, and by then the thread that built it may be gone.
class _ChatReport {
  const _ChatReport({
    required this.repository,
    required this.connectivity,
    required this.messenger,
    required this.l10n,
    required this.roomId,
    required this.messageId,
    required this.reason,
    required this.description,
  });

  final GroupChatRepository repository;
  final ConnectivityService connectivity;
  final ScaffoldMessengerState messenger;
  final AppLocalizations l10n;
  final String roomId;
  final String messageId;
  final String reason;
  final String? description;

  Future<void> send() async {
    final result = await repository.reportMessage(
      roomId,
      messageId: messageId,
      reason: reason,
      description: description,
    );
    final failure = result.fold<Failure?>((f) => f, (_) => null);

    // "Offline" is more honest than "something went wrong" when the request
    // never left. The failure type alone cannot tell us that, and the cached
    // flag may be stale (it is only refreshed on connectivity events), so
    // probe live. The probe only runs when the failure makes it relevant.
    final feedback = await chatReportFeedbackFor(
      failure,
      isOnline: connectivity.checkConnectivity,
    );

    switch (feedback) {
      case ChatReportFeedback.sent:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.group_chat_report_thanks)),
        );
      case ChatReportFeedback.rejected:
        // The server would answer the same way again, so no Retry.
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.group_chat_report_failed)),
        );
      case ChatReportFeedback.offline:
      case ChatReportFeedback.failed:
        // Retry is offered for both. The probe is a DNS lookup that can fail
        // on a network where the API is still reachable (a filtered resolver,
        // a slow one), so "offline" only changes the wording; it must never
        // cost the member the one action that gets the report through.
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              feedback == ChatReportFeedback.offline
                  ? l10n.group_chat_report_offline
                  : l10n.group_chat_report_failed,
            ),
            action: SnackBarAction(
              label: l10n.group_chat_report_retry,
              onPressed: send,
            ),
          ),
        );
    }
  }
}
