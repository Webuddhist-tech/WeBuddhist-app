import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reconnect_backoff.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class DirectChatState extends Equatable {
  /// Null until the room has been fetched or seeded by whoever opened it.
  /// The messages are not here: they are the room's
  /// [groupChatThreadProvider], the same thread group chat runs on.
  final ChatRoomDTO? room;

  const DirectChatState({this.room});

  @override
  List<Object?> get props => [room];
}

/// Where a direct chat's socket comes from. A null config leaves the chat on
/// REST alone.
class DirectChatLiveConfig {
  const DirectChatLiveConfig({
    required this.getToken,
    required this.restBaseUrl,
    this.clientFactory = ChatLiveClient.new,
  });

  final Future<String?> Function() getToken;
  final String restBaseUrl;
  final ChatLiveClient Function() clientFactory;
}

final directChatLiveConfigProvider = Provider<DirectChatLiveConfig?>((ref) {
  return DirectChatLiveConfig(
    getToken: () => ref.read(authServiceProvider).getValidAccessToken(),
    restBaseUrl: ref.read(apiConfigProvider).baseUrl,
  );
});

/// Whether [message] is the viewer's own. A direct room holds two people, so
/// anything not from [otherUserId] is the viewer's.
bool isOwnDirectMessage(ChatMessageDTO message, String otherUserId) {
  return otherUserId.isNotEmpty && message.senderId != otherUserId;
}

/// One direct chat's session: the room, the chat socket and sending.
///
/// The messages live in the room's [groupChatThreadProvider], which brings
/// reactions, replies, delete and report the way group chat has them. This
/// keeps that thread live: what the socket delivers goes into it, and after a
/// gap — a reconnect, a return from the background, a push — it catches up.
///
/// The socket is scoped by the other person (`receiver_id`) and opens once
/// the room says who that is. It pings so an idle socket stays open,
/// reconnects with backoff after a drop, and closes while the app is in the
/// background. A 1008 close means the token or the room was refused: that is
/// not retried, and the chat carries on over REST, which reports a room it
/// cannot reach for itself.
///
/// While the socket is up, sends go over it: a REST send reaches the other
/// person only as a push, never their open socket. A socket send has no
/// reply, so the caller waits for the server's echo of the message.
class DirectChatNotifier extends StateNotifier<DirectChatState>
    with WidgetsBindingObserver {
  DirectChatNotifier({
    required this.ref,
    required this.roomId,
    DirectChatLiveConfig? live,
    bool observeLifecycle = true,
    Duration Function(int attempt) backoff = chatReconnectDelay,
    this.echoTimeout = const Duration(seconds: 10),
  }) : _live = live,
       _observeLifecycle = observeLifecycle,
       _backoff = backoff,
       super(const DirectChatState()) {
    if (_observeLifecycle) WidgetsBinding.instance.addObserver(this);
    unawaited(_loadRoom());
  }

  final Ref ref;
  final String roomId;

  /// How long a socket send waits for its echo before the socket is written
  /// off and the send is checked and retried over REST.
  final Duration echoTimeout;

  final DirectChatLiveConfig? _live;
  final bool _observeLifecycle;
  final Duration Function(int attempt) _backoff;

  static const Duration pingInterval = Duration(seconds: 25);
  static const int _policyViolation = 1008;

  ChatLiveClient? _client;
  StreamSubscription<ChatLiveEvent>? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _connecting = false;

  /// Retries a room fetch that failed. Without the room there is no one to
  /// send to, so the composer stays disabled until one lands.
  Timer? _roomRetryTimer;
  int _roomAttempt = 0;

  /// A socket has been up before, so the next one catches up on what the gap
  /// missed.
  bool _hadSession = false;

  /// The current socket said, in `room_info`, that it is this room.
  bool _roomConfirmed = false;

  /// No page is pushed on top of the chat, so what lands in it is seen. The
  /// screen reports this; a sheet or dialog opened from the chat does not
  /// count as leaving it.
  bool _onScreen = true;

  /// Something arrived while a page covered the chat, so it is marked read
  /// once the chat is uncovered rather than behind the viewer's back.
  bool _unreadWhileAway = false;

  /// Closed with 1008. Not retried for the life of the screen.
  bool _refused = false;
  bool _suspended = false;
  bool _disposed = false;

  /// The socket send waiting for its echo: the message, an error frame, or
  /// null when the socket went away first.
  Completer<Either<Failure, ChatMessageDTO>?>? _pendingEcho;

  /// Whether a send would go over the socket now.
  bool get isLive => _client != null && _roomConfirmed;

  String get _otherUserId => state.room?.otherUserId?.trim() ?? '';

  GroupChatThreadNotifier get _thread =>
      ref.read(groupChatThreadProvider(roomId).notifier);

  String? get _viewerId => ref.read(userProvider).user?.id?.trim();
  String? get _viewerEmail => ref.read(userProvider).user?.email;

  /// Shows [room] in the header while the fetch is in flight. A fetched room
  /// always wins over a seeded one.
  void seedRoom(ChatRoomDTO room) {
    if (state.room != null) return;
    state = DirectChatState(room: room);
    unawaited(_ensureConnected());
  }

  Future<void> _loadRoom() async {
    _roomRetryTimer?.cancel();
    final result = await ref.read(groupChatRepositoryProvider).getRoom(roomId);
    if (!mounted) return;
    result.fold((_) => _scheduleRoomRetry(), (room) {
      _roomAttempt = 0;
      state = DirectChatState(room: room);
    });
    _markReadIfOnScreen();
    unawaited(_ensureConnected());
  }

  /// Only while no room is held: a seeded one already names the recipient,
  /// and the fetch that failed would only refresh it.
  void _scheduleRoomRetry() {
    if (_disposed || _suspended || state.room != null) return;
    _roomRetryTimer?.cancel();
    _roomAttempt++;
    _roomRetryTimer = Timer(_backoff(_roomAttempt), () {
      if (!_disposed) unawaited(_loadRoom());
    });
  }

  /// Catches the thread up with the server and reopens the socket if it is
  /// down. For a push about this room and a return to the foreground. A room
  /// that never loaded is fetched again first.
  Future<void> refresh() async {
    if (_disposed) return;
    if (state.room == null) {
      await _loadRoom();
      if (_disposed) return;
    }
    await _catchUp();
    if (_disposed) return;
    _markReadIfOnScreen();
    unawaited(_ensureConnected());
  }

  Future<ThreadRefreshResult> _catchUp() {
    return _thread.refreshLatest(
      currentUserId: _viewerId,
      currentUserEmail: _viewerEmail,
    );
  }

  /// Sends [body] to the other person in the room, as a reply to
  /// [parentMessageId] when given. Nothing is sent before the room says who
  /// that is.
  ///
  /// Over the socket when it is up, waiting for the echo. When the echo does
  /// not come, the socket is replaced and the thread caught up, to see
  /// whether the message landed anyway before it goes again over REST: a
  /// slow echo must not post it twice. When that check cannot reach the
  /// server either, nothing is resent: the send fails and the draft stays,
  /// so posting it again is the sender's call.
  Future<Either<Failure, ChatMessageDTO>> send(
    String body, {
    String? parentMessageId,
  }) async {
    final otherUserId = _otherUserId;
    if (otherUserId.isEmpty) {
      return const Left(ValidationFailure('This chat has no recipient'));
    }

    final client = _client;
    if (client != null && _roomConfirmed && _pendingEcho == null) {
      final held = ref.read(groupChatThreadProvider(roomId)).messages;
      final heldIds = {for (final message in held) message.id};
      final echo = Completer<Either<Failure, ChatMessageDTO>?>();
      _pendingEcho = echo;
      client.sendMessage(body: body, parentMessageId: parentMessageId);

      final result = await echo.future.timeout(
        echoTimeout,
        onTimeout: () => null,
      );
      if (identical(_pendingEcho, echo)) _pendingEcho = null;
      if (result != null) return result;
      if (!mounted) return const Left(NetworkFailure('The chat was closed'));

      if (identical(_client, client)) {
        await _tearDown();
        _scheduleReconnect();
      }
      final caughtUp = await _catchUp();
      if (!mounted) return const Left(NetworkFailure('The chat was closed'));
      if (caughtUp == ThreadRefreshResult.failed) {
        return const Left(
          NetworkFailure('Could not check whether the message was sent'),
        );
      }
      final messages = ref.read(groupChatThreadProvider(roomId)).messages;
      for (final message in messages) {
        if (!heldIds.contains(message.id) &&
            isOwnDirectMessage(message, otherUserId) &&
            message.body.trim() == body.trim()) {
          return Right(message);
        }
      }
    }

    final result = await ref
        .read(groupChatRepositoryProvider)
        .sendDirectMessage(
          otherUserId,
          body: body,
          parentMessageId: parentMessageId,
        );
    if (!mounted) return result;

    result.fold((_) {}, (message) {
      _thread.appendLive(message);
      // The server counts a sender's own message as unread until
      // `last_read_at` passes it, so the Chats list would badge it.
      unawaited(markRead());
    });
    return result;
  }

  /// Best effort: a failed read receipt never surfaces.
  Future<void> markRead() async {
    await ref.read(groupChatRepositoryProvider).markRoomRead(roomId);
  }

  /// Whether a page is pushed on top of the chat, from the screen. Coming
  /// back to it marks read what arrived in the meantime.
  void setOnScreen(bool onScreen) {
    if (_disposed || _onScreen == onScreen) return;
    _onScreen = onScreen;
    if (onScreen && _unreadWhileAway) {
      _unreadWhileAway = false;
      unawaited(markRead());
    }
  }

  void _markReadIfOnScreen() {
    if (_onScreen) {
      unawaited(markRead());
    } else {
      _unreadWhileAway = true;
    }
  }

  /// Opens the socket if it should be open and is not. Never throws: the
  /// reconnect timer, the lifecycle observer and every load call it without
  /// an error handler.
  Future<void> _ensureConnected() async {
    final live = _live;
    if (live == null || _disposed || _refused || _suspended) return;
    if (_client != null || _connecting) return;
    final otherUserId = _otherUserId;
    if (otherUserId.isEmpty) return;
    // Set before the first await so a racing caller backs off instead of
    // opening a second socket that would orphan this one.
    _connecting = true;

    final String? token;
    try {
      token = await live.getToken();
    } catch (_) {
      _connecting = false;
      _scheduleReconnect();
      return;
    }
    if (_disposed || _suspended || token == null) {
      // Signed out: REST reports that for itself.
      _connecting = false;
      return;
    }

    final client = live.clientFactory();
    _client = client;
    _connecting = false;
    _roomConfirmed = false;
    final reconnected = _hadSession;
    _hadSession = true;
    try {
      _sub = client
          .connect(
            ChatLiveClient.liveUri(
              restBaseUrl: live.restBaseUrl,
              token: token,
              receiverId: otherUserId,
            ),
          )
          .listen(
            _onLiveEvent,
            onError: (_) => _onClosed(client),
            onDone: () => _onClosed(client),
            cancelOnError: true,
          );
    } catch (_) {
      _client = null;
      _scheduleReconnect();
      return;
    }
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) => _client?.sendPing());
    if (reconnected) unawaited(_catchUp());
  }

  void _onLiveEvent(ChatLiveEvent event) {
    if (_disposed) return;
    _reconnectAttempt = 0;

    switch (event) {
      case ChatLiveRoomInfo(roomId: final id):
        // Scoped by person, the socket should name this room. If it names
        // another, nothing is sent over it and its frames are filtered out
        // below; REST carries the chat.
        _roomConfirmed = id == roomId;
      case ChatLiveMessageCreated(message: final json):
        _onMessageCreated(json);
      case ChatLiveMessageDeleted(
        messageId: final messageId,
        deletedAt: final deletedAt,
      ):
        if (!_roomConfirmed || messageId.isEmpty) return;
        _thread.applyDeletion(
          messageId,
          deletedAt:
              deletedAt.isNotEmpty
                  ? deletedAt
                  : DateTime.now().toUtc().toIso8601String(),
        );
      case ChatLiveReactionsUpdated(
        messageId: final messageId,
        reactions: final raw,
      ):
        if (!_roomConfirmed || messageId.isEmpty) return;
        // The payload is shared by both people, so `reacted_by_me` is not
        // the viewer's; the thread re-derives it from the identity passed.
        _thread.replaceReactions(
          messageId,
          raw
              .whereType<Map<String, dynamic>>()
              .map(ChatMessageReactionDTO.fromJson)
              .toList(),
          currentUserId: _viewerId,
          currentUserEmail: _viewerEmail,
        );
      case ChatLiveError(code: final code, message: final message):
        // Only a pending send can be refused; with none, nothing to do.
        _settleEcho(Left(ValidationFailure(message, code: code)));
      // No edit UI anywhere in chat yet, and no typing or presence in direct
      // chats.
      case ChatLiveMessageUpdated():
      case ChatLiveTyping():
      case ChatLivePresence():
      case ChatLivePrayersUpdated():
      case ChatLiveRoomClosed():
      case ChatLiveUnknown():
        break;
    }
  }

  void _onMessageCreated(Map<String, dynamic> json) {
    if (json.isEmpty) return;
    final message = ChatMessageDTO.fromJson(json);
    if (message.id.isEmpty || message.roomId != roomId) return;
    _thread.appendFromSocket(message);
    if (isOwnDirectMessage(message, _otherUserId)) {
      _settleEcho(Right(message));
    }
    // On screen means read, the viewer's own message included: the server
    // counts it unread until `last_read_at` passes it. Under another page it
    // waits until the viewer comes back.
    _markReadIfOnScreen();
  }

  void _settleEcho(Either<Failure, ChatMessageDTO>? result) {
    final pending = _pendingEcho;
    if (pending == null || pending.isCompleted) return;
    _pendingEcho = null;
    pending.complete(result);
  }

  /// The far end closed the socket, or the stream errored. A socket replaced
  /// or torn down here never lands on this: its subscription is cancelled
  /// first.
  void _onClosed(ChatLiveClient client) {
    if (_disposed || !identical(client, _client)) return;
    // Read before the teardown drops the channel.
    final refused = client.closeCode == _policyViolation;
    unawaited(_tearDown());
    _settleEcho(null);
    if (refused) {
      _refused = true;
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_live == null || _disposed || _refused || _suspended) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    _reconnectTimer = Timer(_backoff(_reconnectAttempt), () {
      if (!_disposed) unawaited(_ensureConnected());
    });
  }

  /// Clears the fields before the first await, so a reconnect firing while
  /// the old socket is still closing sees it gone.
  Future<void> _tearDown() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    _roomConfirmed = false;
    final sub = _sub;
    final client = _client;
    _sub = null;
    _client = null;
    await sub?.cancel();
    await client?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _suspended = true;
        _reconnectTimer?.cancel();
        _roomRetryTimer?.cancel();
        _settleEcho(null);
        unawaited(_tearDown());
      case AppLifecycleState.resumed:
        if (!_suspended) return;
        _suspended = false;
        _reconnectAttempt = 0;
        // Catches up on what the background missed, then reopens the socket.
        unawaited(refresh());
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (_observeLifecycle) WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _roomRetryTimer?.cancel();
    _settleEcho(null);
    unawaited(_tearDown());
    super.dispose();
  }
}

final directChatProvider = StateNotifierProvider.autoDispose
    .family<DirectChatNotifier, DirectChatState, String>((ref, roomId) {
      return DirectChatNotifier(
        ref: ref,
        roomId: roomId,
        live: ref.read(directChatLiveConfigProvider),
      );
    });
