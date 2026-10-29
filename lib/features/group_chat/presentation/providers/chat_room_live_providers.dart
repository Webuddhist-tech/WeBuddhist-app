import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/core/realtime/realtime_providers.dart';
import 'package:flutter_pecha/core/realtime/realtime_signals.dart';
import 'package:flutter_pecha/core/realtime/retry_permission_denied.dart';
import 'package:flutter_pecha/core/realtime/signal_field_diff.dart';
import 'package:flutter_pecha/core/realtime/signal_paths.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatRoomLiveState extends Equatable {
  const ChatRoomLiveState({
    this.closed = false,
    this.refreshes = 0,
    this.live = false,
  });

  /// The room can no longer be reached: its event ended or the group was
  /// unpublished. Direct rooms never close.
  final bool closed;

  /// Counts signal-driven refetches that landed, so a screen can mark the
  /// room read each time something new arrived.
  final int refreshes;

  /// Firestore is delivering for this room.
  final bool live;

  ChatRoomLiveState copyWith({bool? closed, int? refreshes, bool? live}) {
    return ChatRoomLiveState(
      closed: closed ?? this.closed,
      refreshes: refreshes ?? this.refreshes,
      live: live ?? this.live,
    );
  }

  @override
  List<Object?> get props => [closed, refreshes, live];
}

/// Keeps one room's thread current from its Firestore signal: a message or
/// reaction change refetches the loaded window into [groupChatThreadProvider],
/// merged by id. Shared by group and direct chat.
///
/// The room's reader document is written after the join commits, so the
/// first listen can be refused for a moment and is retried.
class ChatRoomLiveNotifier extends StateNotifier<ChatRoomLiveState> {
  ChatRoomLiveNotifier({
    required this.ref,
    required this.roomId,
    required RealtimeSignals? signals,
    int retryAttempts = 5,
    Duration retryDelay = const Duration(seconds: 2),
  }) : super(const ChatRoomLiveState()) {
    if (signals == null) return;
    _sub = retryPermissionDenied(
      () => signals.watchDoc(SignalPaths.chatRoom(roomId)),
      attempts: retryAttempts,
      delay: retryDelay,
    ).listen(_onSnapshot, onError: _onError);
  }

  final Ref ref;
  final String roomId;
  final _logger = AppLogger('ChatRoomLive');
  final _diff = SignalFieldDiff({
    SignalFields.messagesChangedAt,
    SignalFields.reactionsChangedAt,
  });

  StreamSubscription<SignalSnapshot>? _sub;
  bool _refreshing = false;
  bool _dirty = false;

  void _onSnapshot(SignalSnapshot snapshot) {
    if (!mounted) return;
    // Already closed is state, not a change, so it is read on every snapshot.
    if (snapshot[SignalFields.closedAt] != null && !state.closed) {
      state = state.copyWith(closed: true, live: true);
    } else if (!state.live) {
      state = state.copyWith(live: true);
    }
    final first = !_diff.hasBaseline;
    final changes = _diff.update(roomId, snapshot);
    // The first snapshot is only a baseline, so whatever changed since the
    // thread loaded is caught up once, here.
    final catchUp =
        first && ref.read(groupChatThreadProvider(roomId)).hasLoaded;
    if (changes.isNotEmpty || catchUp) unawaited(_refreshThread());
  }

  void _onError(Object error) {
    _logger.debug('No live updates for room $roomId: $error');
    if (mounted) state = state.copyWith(live: false);
  }

  /// A burst of signals costs at most one fetch in flight plus one more.
  Future<void> _refreshThread() async {
    if (_refreshing) {
      _dirty = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _dirty = false;
        final user = ref.read(userProvider).user;
        final thread = ref.read(groupChatThreadProvider(roomId).notifier);
        final ok = await thread.refreshLatest(
          currentUserId: user?.id?.trim(),
          currentUserEmail: user?.email,
        );
        if (!mounted) return;
        if (ok) {
          await thread.refreshLoaded(
            currentUserId: user?.id?.trim(),
            currentUserEmail: user?.email,
          );
          if (!mounted) return;
          state = state.copyWith(refreshes: state.refreshes + 1);
        }
      } while (_dirty && mounted);
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final chatRoomLiveProvider = StateNotifierProvider.autoDispose
    .family<ChatRoomLiveNotifier, ChatRoomLiveState, String>((ref, roomId) {
      return ChatRoomLiveNotifier(
        ref: ref,
        roomId: roomId,
        signals: ref.watch(liveSignalsProvider),
      );
    });
