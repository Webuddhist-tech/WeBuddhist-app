import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/chat_room_live_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class DirectChatState extends Equatable {
  /// Null until the room has been fetched or seeded by whoever opened it.
  /// The messages are not here: they are the room's
  /// [groupChatThreadProvider], the same thread group chat runs on.
  final ChatRoomDTO? room;

  /// The room is gone, or the viewer is no longer a member of it.
  final bool unavailable;

  const DirectChatState({this.room, this.unavailable = false});

  @override
  List<Object?> get props => [room, unavailable];
}

/// Whether [message] is the viewer's own. A direct room holds two people, so
/// anything not from [otherUserId] is the viewer's.
bool isOwnDirectMessage(ChatMessageDTO message, String otherUserId) {
  return otherUserId.isNotEmpty && message.senderId != otherUserId;
}

/// Retries a room fetch at 1 s, 2 s, 4 s... capped at 30 s.
Duration directChatRoomRetryDelay(int attempt) {
  final exponent = (attempt - 1).clamp(0, 4);
  return Duration(seconds: (1 << exponent).clamp(1, 30));
}

/// One direct chat's session: the room, its live signal and sending.
///
/// The messages live in the room's [groupChatThreadProvider], which brings
/// reactions, replies, delete and report the way group chat has them. The
/// room's Firestore signal keeps that thread current through
/// [chatRoomLiveProvider]; a push or a return from the background catches
/// up as a backstop.
///
/// Direct rooms never close. A 404 means the room is gone and a 403 that the
/// viewer left it; neither is retried.
class DirectChatNotifier extends StateNotifier<DirectChatState>
    with WidgetsBindingObserver {
  DirectChatNotifier({
    required this.ref,
    required this.roomId,
    bool observeLifecycle = true,
    Duration Function(int attempt) roomRetryDelay = directChatRoomRetryDelay,
  }) : _observeLifecycle = observeLifecycle,
       _roomRetryDelay = roomRetryDelay,
       super(const DirectChatState()) {
    if (_observeLifecycle) WidgetsBinding.instance.addObserver(this);
    _liveSub = ref.listen<ChatRoomLiveState>(chatRoomLiveProvider(roomId), (
      previous,
      next,
    ) {
      if (_disposed) return;
      // Something new landed in the thread; on screen means read.
      if (next.refreshes != (previous?.refreshes ?? 0)) _markReadIfOnScreen();
    });
    unawaited(_loadRoom());
  }

  final Ref ref;
  final String roomId;

  final bool _observeLifecycle;
  final Duration Function(int attempt) _roomRetryDelay;

  ProviderSubscription<ChatRoomLiveState>? _liveSub;

  /// Retries a room fetch that failed. Without the room there is no one to
  /// send to, so the composer stays disabled until one lands.
  Timer? _roomRetryTimer;
  int _roomAttempt = 0;

  /// No page is pushed on top of the chat, so what lands in it is seen. The
  /// screen reports this; a sheet or dialog opened from the chat does not
  /// count as leaving it.
  bool _onScreen = true;

  /// Something arrived while a page covered the chat, so it is marked read
  /// once the chat is uncovered rather than behind the viewer's back.
  bool _unreadWhileAway = false;

  bool _suspended = false;
  bool _disposed = false;

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
  }

  Future<void> _loadRoom() async {
    _roomRetryTimer?.cancel();
    if (state.unavailable) return;
    final result = await ref.read(groupChatRepositoryProvider).getRoom(roomId);
    if (!mounted) return;
    result.fold(
      (failure) {
        if (failure is NotFoundFailure || failure is AuthorizationFailure) {
          state = DirectChatState(room: state.room, unavailable: true);
          return;
        }
        _scheduleRoomRetry();
      },
      (room) {
        _roomAttempt = 0;
        state = DirectChatState(room: room);
      },
    );
    if (state.unavailable) return;
    _markReadIfOnScreen();
  }

  /// Only while no room is held: a seeded one already names the recipient,
  /// and the fetch that failed would only refresh it.
  void _scheduleRoomRetry() {
    if (_disposed || _suspended || state.room != null) return;
    _roomRetryTimer?.cancel();
    _roomAttempt++;
    _roomRetryTimer = Timer(_roomRetryDelay(_roomAttempt), () {
      if (!_disposed) unawaited(_loadRoom());
    });
  }

  /// Catches the thread up with the server, for a push about this room and
  /// a return to the foreground. A room that never loaded is fetched again
  /// first.
  Future<void> refresh() async {
    if (_disposed) return;
    if (state.room == null) {
      await _loadRoom();
      if (_disposed) return;
    }
    if (state.unavailable) return;
    await _catchUp();
    if (_disposed) return;
    _markReadIfOnScreen();
  }

  Future<bool> _catchUp() {
    return _thread.refreshLatest(
      currentUserId: _viewerId,
      currentUserEmail: _viewerEmail,
    );
  }

  /// Sends [body] to the other person in the room, as a reply to
  /// [parentMessageId] when given. Nothing is sent before the room says who
  /// that is. The created message is inserted directly; the signal-driven
  /// refetch dedupes against it by id.
  Future<Either<Failure, ChatMessageDTO>> send(
    String body, {
    String? parentMessageId,
  }) async {
    final otherUserId = _otherUserId;
    if (otherUserId.isEmpty) {
      return const Left(ValidationFailure('This chat has no recipient'));
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

  /// In the background nothing is seen; the return refreshes and marks it.
  void _markReadIfOnScreen() {
    if (_suspended) return;
    if (_onScreen) {
      unawaited(markRead());
    } else {
      _unreadWhileAway = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _suspended = true;
        _roomRetryTimer?.cancel();
      case AppLifecycleState.resumed:
        if (!_suspended) return;
        _suspended = false;
        _roomAttempt = 0;
        // Catches up on what the background missed.
        unawaited(refresh());
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (_observeLifecycle) WidgetsBinding.instance.removeObserver(this);
    _roomRetryTimer?.cancel();
    _liveSub?.close();
    super.dispose();
  }
}

final directChatProvider = StateNotifierProvider.autoDispose
    .family<DirectChatNotifier, DirectChatState, String>((ref, roomId) {
      return DirectChatNotifier(ref: ref, roomId: roomId);
    });
