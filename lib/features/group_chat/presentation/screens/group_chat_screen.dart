import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/usecases/resolve_group_chat_room.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/chat_room_live_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_analytics.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_composer_controller.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_link_spans.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_rooms_list.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/providers/push_notification_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_composer.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_closed_notice.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_composer_link_preview.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_error_state.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_header.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_notification_bell.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_reply_preview.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_selection_header.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_thread.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Where the screen stands on the room that backs this group. The room
/// endpoint creates it on first use, so a member either has one or the
/// lookup failed; the composer is live in every state but [resolving].
enum _RoomState { resolving, joined, unavailable }

/// Member-gated chat shell. Group membership alone grants read and send.
class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;

  /// A message to open the thread on, rather than the newest one. Set when the
  /// chat is reached from the reports queue's "View message".
  final String? targetMessageId;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    this.targetMessageId,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen>
    with WidgetsBindingObserver {
  // Styles its own markers as they are typed.
  final _bodyController = ChatComposerController();
  final _bodyFocusNode = FocusNode();
  /// The room's Firestore signal, kept alive for as long as this screen is.
  ProviderSubscription<ChatRoomLiveState>? _liveSub;
  bool _closed = false;

  /// Foreground pushes, used as a backstop for the signal — see
  /// [_onForegroundPush].
  StreamSubscription<PushMessage>? _pushSub;
  bool _redirecting = false;
  bool _sending = false;
  bool _resolvingRoom = false;
  _RoomState _roomState = _RoomState.resolving;
  String? _roomId;

  /// Fires `group_chat_opened` at most once for this screen. See [_trackOpened].
  final _openTracker = ChatOpenTracker();

  /// The JWT `sub`, used **only** to namespace this account's local room
  /// cache. It is a different id space from chat's `sender_id`, so it must
  /// never reach an identity check — see [_viewerId].
  String _accountId = '';

  /// The provider container, captured while the element is still active.
  ///
  /// Push callbacks and the lifecycle observer outlive
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

  /// Cached for the same reason: [_showsPush] runs from the push stream, and
  /// `ModalRoute.of` on a deactivated element is an ancestor lookup.
  ModalRoute<dynamic>? _route;

  /// The message a reply is being composed for, quoted above the composer.
  ChatMessageDTO? _replyingTo;

  /// Messages selected in the thread, or null. While set, the header becomes
  /// the selection bar. The thread owns the selection; this is a view of it.
  ChatSelection? _selection;

  /// Draft link previews the sender closed, so a dismissed card does not come
  /// straight back on the next keystroke.
  final _dismissedPreviews = <String>{};

  bool get _hasRoomSession => _roomState == _RoomState.joined;

  @override
  void initState() {
    super.initState();
    _providers = ProviderScope.containerOf(context, listen: false);
    WidgetsBinding.instance.addObserver(this);
    _pushSub = _providers
        .read(pushMessagingRepositoryProvider)
        .onForegroundMessage
        .listen(_onForegroundPush);
    // The banner for a message this screen shows would only lead back here.
    // The subscription above still runs for such a push: suppressing the
    // banner must not drop the refetch it feeds.
    _providers.read(foregroundPushFilterProvider).claim(this, _showsPush);
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
    _pushSub = null;
    _providers.read(foregroundPushFilterProvider).release(this);
    _liveSub?.close();
    _liveSub = null;
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  /// True when the member is looking at this room and the push is about it.
  ///
  /// Every guard is about *looking at*: a route pushed on top, or the app no
  /// longer resumed, means the member is not, and the banner is the way they
  /// hear about the message. Room matching is [chatPushTargets]'.
  ///
  /// `isCurrent` cannot tell a page pushed on top from a sheet or dialog
  /// opened here (the report sheet, the emoji picker, the delete confirm),
  /// so a banner can show while one of those is open. Telling them apart
  /// needs a `RouteObserver` on the router, which the app does not have yet.
  bool _showsPush(Map<String, dynamic> data) {
    if (_disposed) return false;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return false;
    }
    if (!(_route?.isCurrent ?? false)) return false;
    // Prayer requests share the room but are not shown here, so their banner
    // stays.
    if (isPrayerPushPayload(data)) return false;
    return chatPushTargets(data, roomId: _roomId, groupId: widget.groupId);
  }

  /// The signal listener survives the background; the refetch on return
  /// covers a listener the SDK dropped meanwhile.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || !_hasRoomSession) return;
    if (state != AppLifecycleState.resumed) return;
    unawaited(_refreshThread());
    unawaited(_markRoomRead());
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
        _trackOpened(roomId, source: ChatOpenSource.resolved);
        _attachLive(roomId);
        await _markRoomRead();
      case GroupChatRoomUnavailable():
        setState(() => _roomState = _RoomState.unavailable);
    }
  }

  void _retryResolveRoom() {
    setState(() => _roomState = _RoomState.resolving);
    _resolvingRoom = false;
    unawaited(_resolveRoom());
  }

  /// Follows the room's signal: each refetch it lands marks the room read
  /// while the app is in view, and a closed room retires the composer. `listenManual` keeps the
  /// autoDispose controller alive for the life of this screen.
  void _attachLive(String roomId) {
    _liveSub?.close();
    _liveSub = ref.listenManual<ChatRoomLiveState>(
      chatRoomLiveProvider(roomId),
      (previous, next) {
        if (_disposed) return;
        // In the background nothing is seen; the return marks it read.
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        if (next.refreshes != (previous?.refreshes ?? 0) &&
            (lifecycle == null || lifecycle == AppLifecycleState.resumed)) {
          unawaited(_markRoomRead());
        }
        if (next.closed && !_closed && mounted) {
          setState(() => _closed = true);
        }
      },
      fireImmediately: true,
    );
  }

  /// A push for this thread arrived while it is on screen. The signal
  /// should already have refetched it; the push is the backstop for a
  /// listener that is not delivering, so it refetches too.
  Future<void> _onForegroundPush(PushMessage message) async {
    if (_disposed || !mounted) return;
    // A prayer request never reaches the thread and must not mark the room
    // read.
    if (isPrayerPushPayload(message.data)) return;
    if (!chatPushTargets(
      message.data,
      roomId: _roomId,
      groupId: widget.groupId,
    )) {
      return;
    }
    if (_roomId == null) return;
    await _refreshThread();
    if (_disposed || !mounted) return;
    unawaited(_markRoomRead());
  }

  /// Fires `group_chat_opened` once per screen, the first time it has a room
  /// to talk in. The room may come from the lookup on open or from this
  /// member's own first send; the event says which. It counts opens, not members: every visit to a
  /// chat that has a room fires it again, and a chat with no room fires
  /// nothing until one exists.
  void _trackOpened(String roomId, {required ChatOpenSource source}) {
    _openTracker.track(
      _providers.read(groupChatAnalyticsProvider),
      groupId: widget.groupId,
      roomId: roomId,
      source: source,
      screenDisposed: _disposed,
    );
  }

  Future<bool> _refreshThread() async {
    final roomId = _roomId;
    if (_disposed || roomId == null) return false;
    return _providers
        .read(groupChatThreadProvider(roomId).notifier)
        .refreshLatest(
          currentUserId: _viewerId,
          currentUserEmail: _viewerEmail,
        );
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
      // Read before the await, matching the thread notifier: a confirmed
      // send still has to be counted after this screen is gone.
      final analytics = _providers.read(groupChatAnalyticsProvider);
      final result = await _providers
          .read(groupChatRepositoryProvider)
          .sendGroupMessage(
            widget.groupId,
            body: body,
            parentMessageId: parent?.id,
          );
      // Both events are recorded here, before the `mounted` check and before
      // anything else is awaited: the server has accepted the message, so
      // they count whether or not this screen is still around to show it.
      result.map((message) {
        _trackOpened(message.roomId, source: ChatOpenSource.firstSend);
        analytics.messageSent(
          groupId: widget.groupId,
          roomId: message.roomId,
          messageId: message.id,
          parentMessageId: parent?.id,
        );
      });
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
          final newRoom = _roomId != message.roomId;
          setState(() {
            _sending = false;
            _replyingTo = null;
            _roomId = message.roomId;
            _roomState = _RoomState.joined;
          });
          // The POST returns the created message, so it is inserted directly
          // and the signal-driven refetch dedupes against it by id.
          _providers
              .read(groupChatThreadProvider(message.roomId).notifier)
              .appendLive(message);
          // Your own message is read the moment it is sent. The server counts
          // it as unread until `last_read_at` moves past it, so without this
          // the chats list shows the sender their own message with a badge.
          unawaited(_markRoomRead());
          if (newRoom) _attachLive(message.roomId);
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
        _RoomState.unavailable => GroupChatErrorState(
          onRetry: _retryResolveRoom,
        ),
        _RoomState.joined =>
          roomId == null
              ? _buildLoading()
              : GroupChatThread(
                roomId: roomId,
                targetMessageId: widget.targetMessageId,
                onReply: _startReply,
                onSelectionChanged: _onSelectionChanged,
              ),
      },
      // A confirmed member may always write: a lookup that failed still
      // sends — the POST creates the room by group id. A closed room cannot.
      showComposer: _roomState != _RoomState.resolving && !_closed,
      closed: _closed,
      // Members only: the preferences endpoint 404s for anyone else.
      showBell: true,
    );
  }

  Widget _buildShell(
    BuildContext context, {
    required Widget body,
    GroupProfile? profile,
    bool showComposer = false,
    bool showBell = false,
    bool closed = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider).user;
    // The selection belongs to the thread State that published it. Any other
    // body means that State is gone — a profile reload swaps in the spinner
    // — and a disposed State can never publish the null that dismisses the
    // bar, so its header would stay up with every action pointing at dead
    // widgets. Dropped here rather than in the thread's `dispose`, which
    // cannot call back into a parent mid-build.
    if (body is! GroupChatThread) _selection = null;
    final selection = _selection;

    return Scaffold(
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
                ? GroupChatHeader(
                  isDark: isDark,
                  onBack: _goBack,
                  profile: profile,
                  trailing:
                      showBell && profile != null
                          ? GroupChatNotificationBell(groupId: profile.id)
                          : null,
                )
                : GroupChatSelectionHeader(
                  isDark: isDark,
                  selection: selection,
                ),
            Expanded(child: body),
          ],
        ),
      ),
      // In the bottom slot rather than the body column, so a floating
      // snackbar is laid out above the composer instead of over it. The
      // composer still pads itself for the keyboard and the home indicator.
      bottomNavigationBar:
          closed
              ? const GroupChatClosedNotice()
              : showComposer
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Watches the draft directly, so the rest of the screen does
                  // not rebuild on every keystroke.
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
                  if (_replyingTo != null)
                    GroupChatReplyPreview(
                      message: _replyingTo!,
                      onCancel: _cancelReply,
                      isOwnMessage: isSelfChatMessage(
                        senderId: _replyingTo!.senderId,
                        senderEmail: _replyingTo!.senderEmail,
                        currentUserId: _viewerId,
                        currentUserEmail: _viewerEmail,
                      ),
                    ),
                  GroupChatComposer(
                    controller: _bodyController,
                    focusNode: _bodyFocusNode,
                    hintText: context.l10n.group_chat_message_hint,
                    isSending: _sending,
                    onSubmit: _send,
                    avatarUrl: user?.avatarUrl,
                    displayName: user?.visibleNameOrNull ?? user?.email,
                  ),
                ],
              )
              : null,
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }
}
