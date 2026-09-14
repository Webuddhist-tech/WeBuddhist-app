import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/usecases/resolve_group_chat_room.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_composer_controller.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_link_spans.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reconnect_backoff.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_rooms_list.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/providers/push_notification_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_composer.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_composer_link_preview.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_empty_state.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_error_state.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_header.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_reply_preview.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_thread.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Where the screen stands on the room that backs this group.
///
/// [absent] is a member with nothing to read yet, not a member who still has
/// to opt in: the composer is live in every state but [resolving].
enum _RoomState { resolving, absent, joined, unavailable }

/// Member-gated chat shell. Group membership alone grants read and send.
class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen>
    with WidgetsBindingObserver {
  // Styles its own markers as they are typed.
  final _bodyController = ChatComposerController();
  final _bodyFocusNode = FocusNode();
  ChatLiveClient? _live;
  StreamSubscription<ChatLiveEvent>? _liveSub;

  /// Foreground pushes, used as a backstop for the socket — see
  /// [_onForegroundPush].
  StreamSubscription<PushMessage>? _pushSub;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _hadLiveSession = false;
  bool _connectingLive = false;
  bool _redirecting = false;
  bool _sending = false;
  bool _resolvingRoom = false;
  _RoomState _roomState = _RoomState.resolving;
  String? _roomId;

  /// The JWT `sub`, used **only** to namespace this account's local room
  /// cache. It is a different id space from chat's `sender_id`, so it must
  /// never reach an identity check — see [_viewerId].
  String _accountId = '';

  /// The provider container, captured while the element is still active.
  ///
  /// Socket frames, the lifecycle observer and the reconnect timer all outlive
  /// this element. A route pop *deactivates* it before `dispose` runs, and
  /// `_tearDownLive` is only started there, so a frame's worth of events still
  /// arrives in that window. `ref.read` walks up from the element and throws
  /// "Looking up a deactivated widget's ancestor is unsafe" there — an
  /// unhandled error mid-frame, which swaps a RenderErrorBox into the thread
  /// and corrupts the sliver child list behind it. Reading through the
  /// container never touches the element tree.
  late final ProviderContainer _providers;

  /// `State.mounted` stays true across deactivation, so it cannot gate this on
  /// its own. Set in [dispose] so a late arrival stops doing work instead of
  /// resurrecting an autoDispose provider for a screen that is gone.
  bool _disposed = false;

  /// Resolved while active, for the same reason as [_providers]: a socket
  /// error frame arriving after a route pop must not do an ancestor lookup.
  ScaffoldMessengerState? _messenger;
  AppLocalizations? _l10n;

  /// The message a reply is being composed for, quoted above the composer.
  ChatMessageDTO? _replyingTo;

  /// Draft link previews the sender closed, so a dismissed card does not come
  /// straight back on the next keystroke.
  final _dismissedPreviews = <String>{};

  /// True once the group has a room session worth holding a socket open for.
  /// [_RoomState.absent] counts: the socket is group-scoped, so it reports the
  /// room the moment another member creates it.
  bool get _hasRoomSession =>
      _roomState == _RoomState.joined || _roomState == _RoomState.absent;

  @override
  void initState() {
    super.initState();
    _providers = ProviderScope.containerOf(context, listen: false);
    WidgetsBinding.instance.addObserver(this);
    _pushSub = _providers
        .read(pushMessagingRepositoryProvider)
        .onForegroundMessage
        .listen(_onForegroundPush);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
    _l10n = context.l10n;
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    unawaited(_pushSub?.cancel());
    _pushSub = null;
    unawaited(_tearDownLive());
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || !_hasRoomSession) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _reconnectTimer?.cancel();
        unawaited(_tearDownLive());
      case AppLifecycleState.resumed:
        unawaited(_ensureLiveConnected());
        unawaited(_markRoomRead());
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// Clears the fields before the first await, so anything that looks at
  /// `_live` while the old socket is still closing — a second push verdict, a
  /// reconnect firing — sees it gone rather than a client mid-teardown.
  Future<void> _tearDownLive() async {
    final sub = _liveSub;
    final live = _live;
    _liveSub = null;
    _live = null;
    await sub?.cancel();
    await live?.dispose();
  }

  String get _profilePath => '/home/group/${widget.groupId}';

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_profilePath);
    }
  }

  /// Leaves the chat once group membership is denied or the session is not
  /// eligible. [notAMember] is reserved for a confirmed non-follower.
  void _leaveChat({required bool toHome, bool notAMember = false}) {
    if (_redirecting) return;
    _redirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (notAMember) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.group_chat_not_a_member)),
        );
      }
      if (toHome) {
        context.go(AppRoutes.home);
        return;
      }
      _goBack();
    });
  }

  Future<String> _loadAccountId() async {
    if (_accountId.isNotEmpty) return _accountId;
    final accountId =
        await _providers
            .read(storageServiceProvider)
            .get<String>(StorageKeys.currentUserId) ??
        '';
    _accountId = accountId;
    return accountId;
  }

  /// The viewer's backend user id, in the same id space as chat's `sender_id`
  /// and reaction `user_ids`.
  ///
  /// Empty until `/users/info` has landed, and empty is the honest answer:
  /// every consumer then falls back to matching on email, where a value from
  /// the wrong id space would instead assert a confident "not mine".
  String get _viewerId => _providers.read(userProvider).user?.id?.trim() ?? '';

  String? get _viewerEmail => _providers.read(userProvider).user?.email;

  /// Resolves the room once per screen. Runs again only through
  /// [_retryResolveRoom] after a failed lookup.
  Future<void> _resolveRoom() async {
    if (_disposed || _resolvingRoom) return;
    _resolvingRoom = true;
    final accountId = await _loadAccountId();
    if (!mounted) return;
    final lookup = await _providers.read(resolveGroupChatRoomProvider)(
      userId: accountId,
      groupId: widget.groupId,
    );
    if (!mounted) return;
    switch (lookup) {
      case GroupChatRoomFound(roomId: final roomId):
        setState(() {
          _roomId = roomId;
          _roomState = _RoomState.joined;
        });
        await _ensureLiveConnected();
        await _markRoomRead();
      case GroupChatRoomMissing():
        setState(() => _roomState = _RoomState.absent);
        await _ensureLiveConnected();
      case GroupChatRoomUnavailable():
        setState(() => _roomState = _RoomState.unavailable);
    }
  }

  void _retryResolveRoom() {
    setState(() => _roomState = _RoomState.resolving);
    _resolvingRoom = false;
    unawaited(_resolveRoom());
  }

  /// Connects the socket. Never throws: every caller — the send flow, the
  /// lifecycle observer and the reconnect timer itself — invokes this without
  /// an error handler, so a failure here must degrade to a retry rather than
  /// escape as an unhandled async error.
  Future<void> _ensureLiveConnected() async {
    if (_disposed || _live != null || _connectingLive || !_hasRoomSession) {
      return;
    }
    // Set synchronously, before the first await, so a second caller racing in
    // before token retrieval resolves sees this and backs off instead of
    // opening a second socket that would silently orphan this one.
    _connectingLive = true;

    final String? token;
    try {
      token = await _providers.read(authServiceProvider).getValidAccessToken();
    } catch (_) {
      // A renewal can fail transiently; back off and try the whole thing again
      // instead of leaving live updates silently disconnected.
      _connectingLive = false;
      _scheduleReconnect();
      return;
    }
    if (!mounted || token == null) {
      _connectingLive = false;
      return;
    }

    final uri = ChatLiveClient.liveUri(
      restBaseUrl: _providers.read(apiConfigProvider).baseUrl,
      token: token,
      groupId: widget.groupId,
      roomId: _roomId,
    );
    final client = ChatLiveClient();
    _live = client;
    _connectingLive = false;
    final reconnected = _hadLiveSession;
    _hadLiveSession = true;

    try {
      _liveSub = client
          .connect(uri)
          .listen(
            _onLiveEvent,
            onError: (_) => _scheduleReconnect(),
            onDone: _scheduleReconnect,
            cancelOnError: true,
          );
    } catch (_) {
      // Clear the client first: the guard above treats a non-null _live as
      // "already connected" and would wedge live updates for good.
      _live = null;
      _scheduleReconnect();
      return;
    }

    // Anything missed while the socket was down is merged in by id.
    if (reconnected) await _refreshThread();
  }

  /// A push for this thread arrived while it is on screen.
  ///
  /// The socket should already have delivered that message. A socket that has
  /// gone half-open cannot be told from a healthy one — no error, no close,
  /// frames simply stop — and the client would sit there believing it is
  /// connected, which is what made new messages appear only after leaving and
  /// coming back.
  ///
  /// So the push is treated as a second opinion: refetch, and if the refetch
  /// turns up a message the socket never delivered, that is proof the socket
  /// is not working — replace it rather than trust it with the next one. The
  /// thread notifier makes that call, not a before/after comparison here: a
  /// message the socket delivers while the refetch is in flight also changes
  /// the newest row, and that is the socket working, not failing. Nor is a
  /// frame that lands just after the page: the refetch is given a grace
  /// window for the socket to catch up before its verdict counts.
  ///
  /// A refetch that fails proves nothing either way, and the push says a
  /// message exists that this screen may not hold. Keeping a socket that
  /// cannot be vouched for is how the half-open case went unnoticed in the
  /// first place, so it is replaced too. That costs a healthy socket at most
  /// one reconnect round trip: the reconnect refetches, which retries the
  /// page and merges anything posted in the gap, and a reconnect that fails
  /// backs off and retries rather than leaving the thread without a socket.
  Future<void> _onForegroundPush(PushMessage message) async {
    if (_disposed || !mounted) return;
    if (!chatPushTargets(
      message.data,
      roomId: _roomId,
      groupId: widget.groupId,
    )) {
      return;
    }
    if (_roomId == null) return;

    // The socket under judgement. The verdict takes a refetch plus the grace
    // window to arrive, and pushes can overlap within that — by the time it
    // lands, an earlier push or the reconnect timer may already have replaced
    // this socket. A verdict is only ever about the socket that was up when
    // the refetch went out; acting on it against whatever is up now would
    // close a fresh, healthy connection over the sins of the old one.
    final judged = _live;

    final outcome = await _refreshThread(socketGrace: _pushSocketGrace);
    if (_disposed || !mounted) return;

    unawaited(_markRoomRead());
    if (outcome == ThreadRefreshResult.nothingMissed) return;
    if (!identical(_live, judged)) return;

    // Tear the socket down first: `_ensureLiveConnected` treats a non-null
    // client as already connected and would otherwise leave the dead one in
    // place.
    await _tearDownLive();
    if (_disposed || !mounted) return;
    await _ensureLiveConnected();
  }

  void _onLiveEvent(ChatLiveEvent event) {
    if (_disposed || !mounted) return;
    // A frame on a fresh socket means the connection is healthy again.
    _reconnectAttempt = 0;

    switch (event) {
      case ChatLiveRoomInfo(roomId: final roomId):
        _adoptRoomId(roomId);
      case ChatLiveMessageCreated(message: final json):
        _onMessageCreated(json);
      case ChatLiveError():
        final messenger = _messenger;
        final l10n = _l10n;
        if (messenger != null && l10n != null) {
          showChatSendError(messenger, l10n, event);
        }
      case ChatLiveReactionsUpdated(
        messageId: final messageId,
        reactions: final raw,
      ):
        _onReactionsUpdated(messageId, raw);
      case ChatLiveMessageDeleted(
        messageId: final messageId,
        deletedAt: final deletedAt,
      ):
        _onMessageDeleted(messageId, deletedAt);
      case ChatLiveTyping():
      case ChatLivePresence():
      case ChatLiveUnknown():
        break;
    }
  }

  /// Adopts a room the server reports over the socket — covers a room someone
  /// else created while this screen was open.
  void _adoptRoomId(String roomId) {
    if (roomId.isEmpty || _roomId == roomId) return;
    setState(() {
      _roomId = roomId;
      _roomState = _RoomState.joined;
    });
    unawaited(_persistRoomId(roomId));
    unawaited(_markRoomRead());
  }

  void _onMessageCreated(Map<String, dynamic> json) {
    if (json.isEmpty) return;
    final message = ChatMessageDTO.fromJson(json);
    if (message.id.isEmpty || message.roomId.isEmpty) return;
    // The first message in a group creates its room, and this frame can be the
    // first mention of it when the sender was someone else.
    _adoptRoomId(message.roomId);
    if (_roomId != message.roomId) return;
    _providers
        .read(groupChatThreadProvider(message.roomId).notifier)
        .appendFromSocket(message);
    unawaited(_markRoomRead());
  }

  /// Applies a reaction broadcast. The payload is shared by every member, so
  /// `reacted_by_me` on it is not viewer-specific — the notifier re-derives
  /// own state from the identity we hold.
  /// A member deleted a message. Falls back to this client's clock only if
  /// the frame arrives without a timestamp — the row still has to become a
  /// tombstone, and the next fetch carries the server's own value.
  void _onMessageDeleted(String messageId, String deletedAt) {
    final roomId = _roomId;
    if (_disposed || roomId == null || messageId.isEmpty) return;
    _providers
        .read(groupChatThreadProvider(roomId).notifier)
        .applyDeletion(
          messageId,
          deletedAt:
              deletedAt.isNotEmpty
                  ? deletedAt
                  : DateTime.now().toUtc().toIso8601String(),
        );
  }

  void _onReactionsUpdated(String messageId, List<dynamic> raw) {
    final roomId = _roomId;
    if (_disposed || roomId == null || messageId.isEmpty) return;
    _providers
        .read(groupChatThreadProvider(roomId).notifier)
        .replaceReactions(
          messageId,
          raw
              .whereType<Map<String, dynamic>>()
              .map(ChatMessageReactionDTO.fromJson)
              .toList(),
          currentUserId: _viewerId,
          currentUserEmail: _viewerEmail,
        );
  }

  /// How long a push-triggered refetch waits for the socket to deliver what
  /// the page carried before calling the socket dead. Long enough to cover
  /// ordinary jitter between the push and the frame, short enough that a
  /// socket that really is half-open is replaced before the next message.
  static const Duration _pushSocketGrace = Duration(seconds: 2);

  Future<ThreadRefreshResult> _refreshThread({
    Duration socketGrace = Duration.zero,
  }) async {
    final roomId = _roomId;
    if (_disposed || roomId == null) return ThreadRefreshResult.failed;
    return _providers
        .read(groupChatThreadProvider(roomId).notifier)
        .refreshLatest(
          currentUserId: _viewerId,
          currentUserEmail: _viewerEmail,
          socketGrace: socketGrace,
        );
  }

  void _scheduleReconnect() {
    if (_disposed || !mounted || !_hasRoomSession) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    _reconnectTimer = Timer(chatReconnectDelay(_reconnectAttempt), () async {
      if (_disposed || !mounted) return;
      await _tearDownLive();
      await _ensureLiveConnected();
    });
  }

  /// Best-effort: a failed read receipt never surfaces to the user.
  Future<void> _markRoomRead() async {
    final roomId = _roomId;
    if (_disposed || roomId == null) return;
    await _providers.read(groupChatRepositoryProvider).markRoomRead(roomId);
  }

  Future<void> _persistRoomId(String roomId) async {
    if (_disposed) return;
    try {
      final accountId = await _loadAccountId();
      await _providers
          .read(groupChatRoomCacheProvider)
          .write(userId: accountId, groupId: widget.groupId, roomId: roomId);
    } catch (_) {
      // Cache is best-effort; join is already committed on the server.
    }
  }

  /// Starts a reply. The intent is always to type next, so focus follows.
  void _startReply(ChatMessageDTO message) {
    setState(() => _replyingTo = message);
    _bodyFocusNode.requestFocus();
  }

  void _cancelReply() => setState(() => _replyingTo = null);

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _sending) return;
    final parent = _replyingTo;
    setState(() => _sending = true);
    try {
      final result = await _providers
          .read(groupChatRepositoryProvider)
          .sendGroupMessage(
            widget.groupId,
            body: body,
            parentMessageId: parent?.id,
          );
      if (!mounted) return;
      await result.fold(
        (failure) async {
          // The quoted message is gone. Drop the quote but keep the draft, so
          // sending again posts it as an ordinary message rather than
          // silently changing what was written or stranding it.
          final lostParent =
              chatSendErrorKind(failure) == ChatSendErrorKind.invalidParent;
          setState(() {
            _sending = false;
            if (lostParent) _replyingTo = null;
          });
          presentChatSendError(context, failure);
        },
        (message) async {
          await _persistRoomId(message.roomId);
          if (!mounted) return;
          _bodyController.clear();
          setState(() {
            _sending = false;
            _replyingTo = null;
            _roomId = message.roomId;
            _roomState = _RoomState.joined;
          });
          // The POST returns the created message, so it is inserted directly
          // and the `message_created` echo dedupes against it by id.
          _providers
              .read(groupChatThreadProvider(message.roomId).notifier)
              .appendLive(message);
          // Your own message is read the moment it is sent. The server counts
          // it as unread until `last_read_at` moves past it, so without this
          // the chats list shows the sender their own message with a badge.
          // It used to be covered only by the `message_created` echo marking
          // read — which never arrives if the socket is not delivering.
          unawaited(_markRoomRead());
          await _ensureLiveConnected();
        },
      );
    } finally {
      if (mounted && _sending) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (auth.isGuest || !auth.isLoggedIn) {
      _leaveChat(toHome: true);
      return _buildShell(context, body: const SizedBox.shrink());
    }

    final profileAsync = ref.watch(groupProfileProvider(widget.groupId));

    return profileAsync.when(
      loading: () => _buildShell(context, body: _buildLoading()),
      error: (_, _) {
        _leaveChat(toHome: false);
        return _buildShell(context, body: const SizedBox.shrink());
      },
      data: (either) {
        return either.fold((_) {
          _leaveChat(toHome: false);
          return _buildShell(context, body: const SizedBox.shrink());
        }, (profile) => _buildMemberGate(context, profile));
      },
    );
  }

  Widget _buildMemberGate(BuildContext context, GroupProfile profile) {
    final followState = ref.watch(
      groupFollowProvider(
        GroupFollowKey(groupId: profile.id, groupType: profile.groupType),
      ),
    );

    // A failed re-check is not a confirmed non-member — it means the cause is
    // unknown, so fall back to the last known-good state instead of evicting
    // someone who is very likely still a member.
    final isMember = switch (followState) {
      GroupFollowSuccess(isFollowing: final following) => following,
      GroupFollowLoading() => profile.isFollowing,
      GroupFollowFailure() => profile.isFollowing,
    };
    final confirmedNonMember =
        followState is GroupFollowSuccess && !followState.isFollowing;

    if (followState is GroupFollowLoading && !profile.isFollowing) {
      return _buildShell(context, profile: profile, body: _buildLoading());
    }

    if (!isMember) {
      _leaveChat(toHome: false, notAMember: confirmedNonMember);
      return _buildShell(
        context,
        profile: profile,
        body: const SizedBox.shrink(),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_resolveRoom());
    });

    final roomId = _roomId;

    return _buildShell(
      context,
      profile: profile,
      body: switch (_roomState) {
        _RoomState.resolving => _buildLoading(),
        _RoomState.absent => const GroupChatEmptyState(),
        _RoomState.unavailable => GroupChatErrorState(
          onRetry: _retryResolveRoom,
        ),
        _RoomState.joined =>
          roomId == null
              ? _buildLoading()
              : GroupChatThread(
                roomId: roomId,
                groupId: widget.groupId,
                onReply: _startReply,
              ),
      },
      // A confirmed member may always write: a lookup that found no room, or
      // failed outright, still sends — the POST creates the room by group id.
      showComposer: _roomState != _RoomState.resolving,
    );
  }

  Widget _buildShell(
    BuildContext context, {
    required Widget body,
    GroupProfile? profile,
    bool showComposer = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider).user;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor:
          isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GroupChatHeader(isDark: isDark, onBack: _goBack, profile: profile),
            Expanded(child: body),
            if (showComposer)
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
                    onDismiss:
                        () => setState(() => _dismissedPreviews.add(url)),
                  );
                },
              ),
            if (showComposer && _replyingTo != null)
              GroupChatReplyPreview(
                message: _replyingTo!,
                onCancel: _cancelReply,
              ),
            if (showComposer)
              GroupChatComposer(
                controller: _bodyController,
                focusNode: _bodyFocusNode,
                hintText: context.l10n.group_chat_message_hint,
                isSending: _sending,
                onSubmit: _send,
                avatarUrl: user?.avatarUrl,
                displayName:
                    joinChatName(user?.firstName, user?.lastName) ??
                    user?.email,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }
}
