import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_message_time.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reconnect_backoff.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class DirectChatState extends Equatable {
  /// Null until the room has been fetched or seeded by whoever opened it.
  final ChatRoomDTO? room;

  /// Newest first, as the API returns them and as `ListView(reverse: true)`
  /// lays them out.
  final List<ChatMessageDTO> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int skip;
  final int total;
  final String? error;

  /// Whether the first fetch has settled, so the empty state never flashes
  /// before it lands.
  final bool hasLoaded;

  const DirectChatState({
    this.room,
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.skip = 0,
    this.total = 0,
    this.error,
    this.hasLoaded = false,
  });

  DirectChatState copyWith({
    ChatRoomDTO? room,
    List<ChatMessageDTO>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? skip,
    int? total,
    String? error,
    bool? hasLoaded,
    bool clearError = false,
  }) {
    return DirectChatState(
      room: room ?? this.room,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      total: total ?? this.total,
      error: clearError ? null : error ?? this.error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }

  @override
  List<Object?> get props => [
    room,
    messages,
    isLoading,
    isLoadingMore,
    hasMore,
    skip,
    total,
    error,
    hasLoaded,
  ];
}

/// [held] and [incoming] as one newest-first list, one row per message.
///
/// The incoming copy wins, so an edit or a delete that happened since [held]
/// was fetched shows up. Ties on time break by id, so rows sent in the same
/// instant do not swap places between refreshes.
List<ChatMessageDTO> mergeDirectMessages(
  List<ChatMessageDTO> held,
  List<ChatMessageDTO> incoming,
) {
  final byId = <String, ChatMessageDTO>{
    for (final message in held) message.id: message,
    for (final message in incoming) message.id: message,
  };
  final merged = byId.values.toList();
  merged.sort((a, b) {
    final byTime = b.createdAtLocal.compareTo(a.createdAtLocal);
    if (byTime != 0) return byTime;
    return b.id.compareTo(a.id);
  });
  return merged;
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

/// One direct chat: its thread over REST, kept live by the chat socket.
///
/// The socket is scoped by the other person (`receiver_id`) and opens once
/// the room says who that is. It merges what arrives, pings so an idle socket
/// stays open, reconnects with backoff after a drop and refetches what it
/// missed, and closes while the app is in the background. A 1008 close means
/// the token or the room was refused: that is not retried, and the chat
/// carries on over REST, which reports a room it cannot reach for itself.
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
    loadInitial();
  }

  final Ref ref;
  final String roomId;

  /// How long a socket send waits for its echo before the socket is written
  /// off and the send is checked and retried over REST.
  final Duration echoTimeout;

  final DirectChatLiveConfig? _live;
  final bool _observeLifecycle;
  final Duration Function(int attempt) _backoff;

  static const int _limit = 30;
  static const Duration pingInterval = Duration(seconds: 25);
  static const int _policyViolation = 1008;

  ChatLiveClient? _client;
  StreamSubscription<ChatLiveEvent>? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _connecting = false;

  /// A socket has been up before, so the next one refetches what the gap
  /// missed.
  bool _hadSession = false;

  /// The current socket said, in `room_info`, that it is this room.
  bool _roomConfirmed = false;

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

  /// Shows [room] in the header while the fetch is in flight. A fetched room
  /// always wins over a seeded one.
  void seedRoom(ChatRoomDTO room) {
    if (state.room != null) return;
    state = state.copyWith(room: room);
    unawaited(_ensureConnected());
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    await _fetchNewest();
  }

  /// Reloads the newest page and merges it into what is held, so older pages
  /// the viewer scrolled to stay. Also the way back to a socket that is down.
  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    await _fetchNewest();
  }

  Future<void> _fetchNewest() async {
    final repository = ref.read(groupChatRepositoryProvider);
    // Both in flight at once; the room only refreshes the header, so its
    // failure costs nothing the seeded or previous room cannot cover.
    final roomFuture = repository.getRoom(roomId);
    final pageFuture = repository.listMessages(roomId, limit: _limit);
    final roomResult = await roomFuture;
    final pageResult = await pageFuture;
    if (!mounted) return;

    final room = roomResult.fold((_) => null, (room) => room);
    pageResult.fold(
      (failure) {
        state = state.copyWith(
          room: room,
          isLoading: false,
          hasLoaded: true,
          error: failure.message,
        );
      },
      (page) {
        final merged = mergeDirectMessages(state.messages, page.messages);
        state = state.copyWith(
          room: room,
          messages: merged,
          isLoading: false,
          hasLoaded: true,
          skip: merged.length,
          total: page.total,
          hasMore: merged.length < page.total,
          clearError: true,
        );
        unawaited(markRead());
      },
    );
    // Just fetched: a socket opened from here has nothing to catch up on.
    unawaited(_ensureConnected(catchUp: false));
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await ref
        .read(groupChatRepositoryProvider)
        .listMessages(roomId, skip: state.skip, limit: _limit);
    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        final merged = mergeDirectMessages(state.messages, page.messages);
        // Rows posted since the last page shift every offset down, so this
        // page can repeat rows already held. Paging on from what is held
        // keeps the next page from skipping any.
        state = state.copyWith(
          messages: merged,
          isLoadingMore: false,
          skip: merged.length,
          total: page.total,
          hasMore: page.messages.isNotEmpty && merged.length < page.total,
        );
      },
    );
  }

  /// Merges a message the socket delivered, new or edited.
  void applyLive(ChatMessageDTO message) {
    if (!mounted) return;
    final isNew = !state.messages.any((held) => held.id == message.id);
    final merged = mergeDirectMessages(state.messages, [message]);
    state = state.copyWith(
      messages: merged,
      skip: merged.length,
      total: isNew ? state.total + 1 : state.total,
    );
  }

  /// Turns a held message into a tombstone. A delete can come from the other
  /// person too.
  void applyDeleted(String messageId, String deletedAt) {
    if (!mounted || messageId.isEmpty) return;
    final stamp =
        deletedAt.isNotEmpty
            ? deletedAt
            : DateTime.now().toUtc().toIso8601String();
    var changed = false;
    final messages = <ChatMessageDTO>[];
    for (final held in state.messages) {
      if (held.id == messageId && held.deletedAt == null) {
        messages.add(held.copyWith(deletedAt: stamp));
        changed = true;
      } else {
        messages.add(held);
      }
    }
    if (changed) state = state.copyWith(messages: messages);
  }

  /// Sends [body] to the other person in the room. Nothing is sent before
  /// the room says who that is.
  ///
  /// Over the socket when it is up, waiting for the echo. When the echo does
  /// not come, the socket is replaced and the thread refetched, to see
  /// whether the message landed anyway before it goes again over REST: a
  /// slow echo must not post it twice.
  Future<Either<Failure, ChatMessageDTO>> send(String body) async {
    final otherUserId = _otherUserId;
    if (otherUserId.isEmpty) {
      return const Left(ValidationFailure('This chat has no recipient'));
    }

    final client = _client;
    if (client != null && _roomConfirmed && _pendingEcho == null) {
      final heldIds = {for (final message in state.messages) message.id};
      final echo = Completer<Either<Failure, ChatMessageDTO>?>();
      _pendingEcho = echo;
      client.sendMessage(body: body);

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
      await _fetchNewest();
      if (!mounted) return const Left(NetworkFailure('The chat was closed'));
      for (final message in state.messages) {
        if (!heldIds.contains(message.id) &&
            isOwnDirectMessage(message, otherUserId) &&
            message.body.trim() == body.trim()) {
          return Right(message);
        }
      }
    }

    final result = await ref
        .read(groupChatRepositoryProvider)
        .sendDirectMessage(otherUserId, body: body);
    if (!mounted) return result;

    result.fold((_) {}, (message) {
      applyLive(message);
      // The server counts a sender's own message as unread until
      // `last_read_at` passes it, so the Chats list would badge it.
      unawaited(markRead());
    });
    return result;
  }

  Future<void> markRead() async {
    await ref.read(groupChatRepositoryProvider).markRoomRead(roomId);
  }

  /// Opens the socket if it should be open and is not. Never throws: the
  /// reconnect timer, the lifecycle observer and every fetch call it without
  /// an error handler.
  ///
  /// A socket that replaces an earlier one refetches what the gap missed,
  /// unless [catchUp] is off because the caller has just fetched.
  Future<void> _ensureConnected({bool catchUp = true}) async {
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
    if (reconnected && catchUp) unawaited(refresh());
  }

  void _onLiveEvent(ChatLiveEvent event) {
    if (_disposed) return;
    _reconnectAttempt = 0;

    switch (event) {
      case ChatLiveRoomInfo(roomId: final id):
        // Scoped by person, the socket should name this room. If it names
        // another, nothing is sent over it and its messages are filtered out
        // below; REST carries the chat.
        _roomConfirmed = id == roomId;
      case ChatLiveMessageCreated(message: final json):
        _onMessage(json, created: true);
      case ChatLiveMessageUpdated(message: final json):
        _onMessage(json, created: false);
      case ChatLiveMessageDeleted(
        messageId: final messageId,
        deletedAt: final deletedAt,
      ):
        applyDeleted(messageId, deletedAt);
      case ChatLiveError(code: final code, message: final message):
        // Only a pending send can be refused; with none, nothing to do.
        _settleEcho(Left(ValidationFailure(message, code: code)));
      // Text only: no reactions, typing or presence in direct chats yet.
      case ChatLiveReactionsUpdated():
      case ChatLiveTyping():
      case ChatLivePresence():
      case ChatLivePrayersUpdated():
      case ChatLiveRoomClosed():
      case ChatLiveUnknown():
        break;
    }
  }

  void _onMessage(Map<String, dynamic> json, {required bool created}) {
    if (json.isEmpty) return;
    final message = ChatMessageDTO.fromJson(json);
    if (message.id.isEmpty || message.roomId != roomId) return;
    applyLive(message);
    if (!created) return;
    if (isOwnDirectMessage(message, _otherUserId)) {
      _settleEcho(Right(message));
    }
    // On screen means read, the viewer's own message included: the server
    // counts it unread until `last_read_at` passes it.
    unawaited(markRead());
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
        _settleEcho(null);
        unawaited(_tearDown());
      case AppLifecycleState.resumed:
        if (!_suspended) return;
        _suspended = false;
        _reconnectAttempt = 0;
        // Fetches what the background missed, then reopens the socket.
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
