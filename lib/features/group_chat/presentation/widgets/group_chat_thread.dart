import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_analytics.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_copy_text.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_haptics.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reactions.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_report_request.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_report_reason.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_selection.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_thread_rows.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_date_separator.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_delete_dialog.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_emoji_picker.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_emoji_pill.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_empty_state.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_message_bubble.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_report_sheet.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_reactions_sheet.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_selection_header.dart';
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
    required this.onSelectionChanged,
  });

  final String roomId;
  final String groupId;

  /// Starts a reply in the composer, which the screen owns.
  final ValueChanged<ChatMessageDTO> onReply;

  /// The selection as it stands, or null once cleared. The screen swaps its
  /// header for the selection bar while this is non-null.
  final ValueChanged<ChatSelection?> onSelectionChanged;

  @override
  ConsumerState<GroupChatThread> createState() => _GroupChatThreadState();
}

class _GroupChatThreadState extends ConsumerState<GroupChatThread> {
  final _scrollController = ScrollController();

  /// One key per message so the emoji pill can be placed against the row it
  /// belongs to, and a quote can scroll to its original.
  final _rowKeys = <String, GlobalKey>{};

  /// The stack the pill is positioned in; row rects are measured against it.
  final _stackKey = GlobalKey();

  /// Selected message ids, in the order they were picked.
  final _selectedIds = <String>{};

  /// Where the pill sits, in the stack's own coordinates, or null while it is
  /// hidden. Scrolling hides it; the selection stays.
  Rect? _pillRect;

  /// The message the pill reacts on. Held separately from [_selectedIds] so
  /// the pill can be gone while that row is still selected.
  String? _pillMessageId;

  /// True from the moment the delete dialog is confirmed until the request
  /// settles. The selection stays on screen meanwhile, so without this the
  /// header would offer Delete again and a second confirm would send the
  /// same ids on top of a request still running.
  bool _deleteInFlight = false;

  /// Gap between the pill and the bubble it floats over, and its clearance
  /// from the edges of the stack it is positioned in.
  static const double _pillGap = 8;

  /// The keyboard inset last seen. The composer grows by it, which shrinks
  /// this thread and moves every row without a scroll event.
  double _viewInsetBottom = 0;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The keyboard opening or closing resizes the stack the pill is measured
    // against, so its rect no longer points at its row. Same policy as a
    // scroll: the pill goes, the selection stays. No `setState` — a rebuild
    // follows this callback anyway.
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset != _viewInsetBottom) {
      _viewInsetBottom = inset;
      _pillRect = null;
      _pillMessageId = null;
    }
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

    // The pill is anchored to where its row *was*; rather than chase the
    // row it goes away, and the selection it belongs to stays.
    if (_pillRect != null) _hidePill();
  }

  GlobalKey _rowKey(String messageId) =>
      _rowKeys.putIfAbsent(messageId, GlobalKey.new);

  bool get _isNearBottom =>
      !_scrollController.hasClients ||
      _scrollController.offset <= _followThreshold;

  /// Brings the newest message into view. The list is reversed, so the bottom
  /// is offset zero.
  ///
  /// One continuous animation, however far away: a jump partway first was
  /// tried and the cut it makes is exactly what stops it feeling smooth.
  /// The duration grows with the distance but is capped, and the curve is
  /// ease-out, so a long way flies past at the start — rows are a blur there
  /// anyway — and the last stretch settles onto the newest message.
  void _scrollToNewest() {
    if (!_scrollController.hasClients) return;
    final distance = _scrollController.position.pixels;
    final milliseconds = (distance / _scrollPixelsPerMs)
        .clamp(_minScrollMs, _maxScrollMs)
        .round();
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: milliseconds),
      curve: Curves.easeOutCubic,
    );
  }

  /// Speed of the animated scroll, and its bounds so a short hop is still
  /// visible and a long one never drags.
  static const double _scrollPixelsPerMs = 3;
  static const double _minScrollMs = 260;
  static const double _maxScrollMs = 1100;

  /// Follows a newly arrived message.
  ///
  /// Own messages always scroll — you should see what you just sent, wherever
  /// you were reading. Someone else's only scrolls when already near the
  /// bottom, so a message arriving does not yank you out of older history you
  /// are reading.
  void _onNewestChanged(ChatMessageDTO newest, bool isMine) {
    final follow = isMine || _isNearBottom;
    _newestId = newest.id;
    // A new row at the reversed end pushes the others up without a scroll
    // notification, so the pill would be left over a different message.
    _hidePill();
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

  // ---- Selection ---------------------------------------------------------

  bool get _hasSelection => _selectedIds.isNotEmpty;

  /// The selected messages as the thread holds them now — reactions and
  /// deletion state included — dropping any that have since left the window.
  List<ChatMessageDTO> get _selectedMessages {
    final byId = {
      for (final message
          in ref.read(groupChatThreadProvider(widget.roomId)).messages)
        message.id: message,
    };
    return [
      for (final id in _selectedIds)
        if (byId[id] case final message?) message,
    ];
  }

  /// Long-press: the haptic first, so it lands the moment the press is
  /// recognised, then the row joins the selection and gets the pill.
  void _onLongPressRow(ChatMessageDTO message) {
    unawaited(chatLongPressHaptic());
    if (!_selectedIds.contains(message.id) && !_trySelect(message)) return;
    if (_selectedIds.length == 1) {
      _showPillFor(message);
    } else {
      _hidePill();
    }
  }

  /// Tap while a selection exists toggles the row. Outside selection mode the
  /// bubble takes no tap at all, so this is never reached.
  void _onTapRow(ChatMessageDTO message) {
    HapticFeedback.selectionClick();
    if (_selectedIds.contains(message.id)) {
      _selectedIds.remove(message.id);
      _hidePill();
      _publishSelection();
      return;
    }
    if (_trySelect(message)) _hidePill();
  }

  /// Adds [message], or refuses it — a tombstone, or the cap — and says why
  /// when it is the cap.
  bool _trySelect(ChatMessageDTO message) {
    if (!chatMessageIsSelectable(message)) return false;
    if (!chatSelectionHasRoom(_selectedIds.length)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.group_chat_selection_limit(kChatMaxSelection),
          ),
        ),
      );
      return false;
    }
    _selectedIds.add(message.id);
    _publishSelection();
    return true;
  }

  void _clearSelection() {
    if (!_hasSelection && _pillRect == null) return;
    _selectedIds.clear();
    _pillRect = null;
    _pillMessageId = null;
    _publishSelection();
  }

  /// Rebuilds and hands the screen a fresh [ChatSelection], or null.
  void _publishSelection() {
    if (!mounted) return;
    setState(() {});
    if (!_hasSelection) {
      widget.onSelectionChanged(null);
      return;
    }
    final gates = chatSelectionGates(
      _selectedMessages,
      currentUserId: _viewerId,
      currentUserEmail: _viewerEmail,
      deleteInFlight: _deleteInFlight,
    );
    widget.onSelectionChanged(
      ChatSelection(
        count: _selectedIds.length,
        gates: gates,
        onReply: _replySelected,
        onCopy: _copySelection,
        onDelete: _deleteSelection,
        onReport: _reportSelected,
        onClear: _clearSelection,
      ),
    );
  }

  /// Drops from the selection — and from under the pill — any row that has
  /// stopped being selectable since it was picked: tombstoned by a live
  /// `message_deleted`, or gone from a restarted window.
  ///
  /// Runs on every thread change while something is selected. The header
  /// holds the gates it was last handed, so a row that turns into a
  /// tombstone underneath it would otherwise keep Reply, Copy and Delete on
  /// offer for a message that no longer has a body.
  void _reconcileSelection(List<ChatMessageDTO> messages) {
    if (!_hasSelection && _pillMessageId == null) return;

    final stale = chatSelectionStaleIds([
      ..._selectedIds,
      if (_pillMessageId case final pillId?) pillId,
    ], messages);
    if (stale.isEmpty) return;

    if (stale.contains(_pillMessageId)) _hidePill();
    if (_selectedIds.any(stale.contains)) {
      _selectedIds.removeAll(stale);
      _publishSelection();
    }
  }

  /// Places the pill above [message]'s bubble, aligned to the bubble's near
  /// edge — right for own messages, left for everyone else's — and flips it
  /// below the bubble when there is no room above.
  void _showPillFor(ChatMessageDTO message) {
    final row = _rowKeys[message.id]?.currentContext?.findRenderObject();
    final stack = _stackKey.currentContext?.findRenderObject();
    if (row is! RenderBox || stack is! RenderBox) return;
    if (!row.hasSize || !stack.hasSize) return;

    final rowRect = row.localToGlobal(Offset.zero, ancestor: stack) & row.size;
    final isSelf = _isSelf(message);
    var left =
        isSelf
            ? rowRect.right -
                GroupChatMessageBubble.bubbleEdgeInset -
                GroupChatEmojiPill.width
            : rowRect.left + GroupChatMessageBubble.bubbleEdgeInset;
    final maxLeft = stack.size.width - GroupChatEmojiPill.width - 8;
    left = maxLeft < 8 ? 8 : left.clamp(8.0, maxLeft);

    var top = rowRect.top - GroupChatEmojiPill.height - _pillGap;
    if (top < 0) top = rowRect.bottom + _pillGap;
    // A row taller than the space left — a long message at the bottom with
    // the keyboard up — has no room above or below. The stack clips, so the
    // pill would land out of sight; keep it over the bubble's lower edge
    // instead.
    final maxTop = stack.size.height - GroupChatEmojiPill.height - _pillGap;
    if (top > maxTop) top = maxTop < 0 ? 0 : maxTop;

    setState(() {
      _pillMessageId = message.id;
      _pillRect = Rect.fromLTWH(
        left,
        top,
        GroupChatEmojiPill.width,
        GroupChatEmojiPill.height,
      );
    });
  }

  void _hidePill() {
    if (_pillRect == null && _pillMessageId == null) return;
    setState(() {
      _pillRect = null;
      _pillMessageId = null;
    });
  }

  Future<void> _reactFromPill(String emoji) async {
    final messageId = _pillMessageId;
    _clearSelection();
    if (messageId == null) return;
    await _toggleReaction(messageId, emoji);
  }

  Future<void> _pickMoreFromPill() async {
    final messageId = _pillMessageId;
    _clearSelection();
    if (messageId == null) return;
    final picked = await showChatEmojiPicker(context);
    if (!mounted || picked == null) return;
    await _toggleReaction(messageId, picked);
  }

  void _replySelected() {
    final selected = _selectedMessages;
    if (selected.length != 1) return;
    final message = selected.single;
    _clearSelection();
    widget.onReply(message);
  }

  Future<void> _copySelection() async {
    final selected = _selectedMessages;
    if (selected.isEmpty) return;
    final l10n = context.l10n;
    final text = chatCopyText(
      selected,
      timeOf: (message) => GroupChatMessageBubble.timeLabel(context, message),
      nameOf:
          (message) =>
              _isSelf(message)
                  ? l10n.group_chat_you
                  : chatSenderDisplayName(
                        messageName: message.senderName,
                        senderEmail: message.senderEmail,
                      ) ??
                      l10n.group_chat_unknown_sender,
    );
    final messenger = ScaffoldMessenger.of(context);
    _clearSelection();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.group_chat_copied)));
  }

  Future<void> _reportSelected() async {
    final selected = _selectedMessages;
    if (selected.length != 1) return;
    final message = selected.single;
    _clearSelection();
    await _reportMessage(message);
  }

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
    final report = ChatReportRequest(
      repository: ref.read(groupChatRepositoryProvider),
      analytics: ref.read(groupChatAnalyticsProvider),
      isOnline: ref.read(connectivityServiceProvider).checkConnectivity,
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

  /// Deletes every selected own message after one dialog — one bulk request,
  /// or one call each where the server has no bulk route yet.
  ///
  /// Each success tombstones its row and drops it from the selection.
  /// Whatever failed stays selected, under one snackbar, so Delete can simply
  /// be tapped again. The selection only stays behind the dialog (mock 5);
  /// the pill does not.
  Future<void> _deleteSelection() async {
    // The header greys Delete for the duration, but a tap already queued
    // when the first confirm landed can still arrive here.
    if (_deleteInFlight) return;
    final targets = _selectedMessages;
    // All or nothing: a selection holding anyone else's message offers no
    // Delete at all, and this must not quietly delete the own subset either.
    if (targets.isEmpty || !targets.every(_canDelete)) return;
    _hidePill();

    if (!await confirmChatMessageDelete(context, count: targets.length)) {
      return;
    }
    if (!mounted || _deleteInFlight) return;

    // Resolved before the await for the same reason as `_toggleReaction`:
    // leaving the screen mid-request deactivates this element.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final notifier = ref.read(groupChatThreadProvider(widget.roomId).notifier);

    // Published so the header greys Delete before the request goes out, and
    // released before the selection is republished below either way.
    _deleteInFlight = true;
    _publishSelection();
    final ChatDeleteOutcome outcome;
    try {
      outcome = await notifier.deleteMessages([
        for (final message in targets) message.id,
      ]);
    } finally {
      _deleteInFlight = false;
    }
    if (!mounted) return;

    if (outcome.failed.isEmpty) {
      // Cleared while the set is still populated: `_clearSelection` treats
      // an already-empty set as nothing to do and would not tell the screen,
      // leaving the selection header and the row tint in place over
      // freshly deleted rows.
      // No success toast: the tombstone already shows the delete landed.
      _clearSelection();
      return;
    }
    // Partial success (the one-call-each fallback): the deleted rows leave
    // the selection, the refused ones stay in it for a retry.
    _selectedIds.removeAll(outcome.deleted);
    _publishSelection();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.group_chat_delete_failed(outcome.failed.length)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupChatThreadProvider(widget.roomId));
    final notifier = ref.read(groupChatThreadProvider(widget.roomId).notifier);
    final user = ref.watch(userProvider).user;

    // The header holds the gates it was last handed. A selection made while
    // the profile was still loading had no viewer to compare senders against,
    // so Delete and Report were off; once the identity lands, hand the header
    // a fresh selection or it stays that way until the next tap.
    ref.listen(userProvider, (previous, next) {
      if (!_hasSelection) return;
      final before = previous?.user;
      final after = next.user;
      if (before?.id?.trim() == after?.id?.trim() &&
          before?.email == after?.email) {
        return;
      }
      _publishSelection();
    });

    ref.listen(groupChatThreadProvider(widget.roomId), (_, next) {
      // Before the arrival check: a deletion changes rows without changing
      // which one is newest, and it is exactly what the selection has to
      // hear about.
      _reconcileSelection(next.messages);
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

    // The pill reacts on the live copy of its message, so the tinted circle
    // follows a reaction that lands while it is open.
    final pillMessage =
        _pillMessageId == null
            ? null
            : state.messages.cast<ChatMessageDTO?>().firstWhere(
              (message) => message!.id == _pillMessageId,
              orElse: () => null,
            );
    final pillRect = _pillRect;

    // No keyboard inset here. The composer sits in the same Column and grows
    // by the inset itself, which already shrinks this Expanded to the space
    // above the field — adding it again would double the gap under the newest
    // message.
    return PopScope(
      // System back leaves selection mode before it leaves the chat.
      canPop: !_hasSelection,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: _dismissKeyboardOnTap(
        Stack(
          key: _stackKey,
          children: [
            _buildList(state, rows, user),
            if (_showJumpToLatest)
              Positioned(
                right: 16,
                bottom: 12,
                child: _JumpToLatestButton(onTap: _scrollToNewest),
              ),
            if (pillRect != null && pillMessage != null)
              Positioned(
                left: pillRect.left,
                top: pillRect.top,
                child: GroupChatEmojiPill(
                  myEmoji: currentChatReactionEmoji(pillMessage.reactions),
                  onPick: _reactFromPill,
                  onMore: _pickMoreFromPill,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    GroupChatThreadState state,
    List<ChatThreadRow> rows,
    User? user,
  ) {
    // Until the server stamps `deleted_at` onto a quoted parent, the thread
    // knows a quote's original is gone only when that original is loaded.
    final deletedIds = {
      for (final message in state.messages)
        if (message.deletedAt != null) message.id,
    };
    final viewerId = user?.id?.trim() ?? '';
    final viewerEmail = user?.email;
    final selecting = _hasSelection;

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
            final parent = message.parent;

            final bubble = GroupChatMessageBubble(
              message: message,
              isSelf: isSelfChatMessage(
                senderId: message.senderId,
                senderEmail: message.senderEmail,
                currentUserId: viewerId,
                currentUserEmail: viewerEmail,
              ),
              isRunStart: isRunStart,
              selfAvatarUrl: user?.avatarUrl,
              selfDisplayName: joinChatName(user?.firstName, user?.lastName),
              isHighlighted: message.id == _highlightedId,
              isSelected: _selectedIds.contains(message.id),
              isParentDeleted:
                  parent != null && deletedIds.contains(parent.id),
              isParentOwn:
                  parent != null &&
                  isSelfChatMessage(
                    senderId: parent.senderId,
                    senderEmail: parent.senderEmail,
                    currentUserId: viewerId,
                    currentUserEmail: viewerEmail,
                  ),
              onShowReactions: () => _showReactions(message),
              onTapQuote:
                  parent == null ? null : () => _scrollToMessage(parent.id),
            );

            // In selection mode the whole tinted row is the target, not just
            // the bubble: a tap anywhere on it toggles the row, a long-press
            // adds it with the pill, and nothing inside — badge, quote, link
            // — fires. A tombstone swallows the tap so it neither joins the
            // selection nor clears it by falling through to the thread.
            if (selecting) {
              return KeyedSubtree(
                key: _rowKey(message.id),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isDeleted ? () {} : () => _onTapRow(message),
                  onLongPress: isDeleted ? null : () => _onLongPressRow(message),
                  child: AbsorbPointer(child: bubble),
                ),
              );
            }

            // Nothing on offer for a message that is gone: nothing to react
            // to, quote, copy or select.
            if (isDeleted) {
              return KeyedSubtree(key: _rowKey(message.id), child: bubble);
            }

            return KeyedSubtree(
              key: _rowKey(message.id),
              // Long-press anywhere on the row — bubble, avatar or the space
              // beside them — starts a selection. Translucent, so the taps
              // inside the bubble (badge, quote, links) keep working, and
              // only a still press wins the arena against the swipe and the
              // scroll.
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPress: () => _onLongPressRow(message),
                // Swipe and the selection header reach the same reply path,
                // so the two gestures cannot disagree about what a reply
                // means.
                child: GroupChatSwipeToReply(
                  onReply: () => widget.onReply(message),
                  child: bubble,
                ),
              ),
            );
        }
      },
    );
  }

  /// Taps that no child claims fall through to here: they drop focus, so
  /// tapping the thread closes the keyboard, and they end a selection.
  Widget _dismissKeyboardOnTap(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
        _clearSelection();
      },
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
