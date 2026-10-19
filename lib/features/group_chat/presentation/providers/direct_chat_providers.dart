import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_message_time.dart';
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

/// One direct chat, over REST.
///
/// There is no live socket for direct rooms, so the thread is refetched on
/// every occasion it could be stale: opening it, pulling to refresh, coming
/// back to the foreground, and a push for this room. Replies to a Help &
/// contact message take hours, not seconds, so that is enough.
class DirectChatNotifier extends StateNotifier<DirectChatState> {
  DirectChatNotifier({required this.ref, required this.roomId})
    : super(const DirectChatState()) {
    loadInitial();
  }

  final Ref ref;
  final String roomId;

  static const int _limit = 30;

  /// Shows [room] in the header while the fetch is in flight. A fetched room
  /// always wins over a seeded one.
  void seedRoom(ChatRoomDTO room) {
    if (state.room != null) return;
    state = state.copyWith(room: room);
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    await _fetchNewest();
  }

  /// Reloads the newest page and merges it into what is held, so older pages
  /// the viewer scrolled to stay.
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

  /// Sends [body] to the other person in the room. Nothing is sent before
  /// the room says who that is.
  Future<Either<Failure, ChatMessageDTO>> send(String body) async {
    final otherUserId = state.room?.otherUserId?.trim() ?? '';
    if (otherUserId.isEmpty) {
      return const Left(ValidationFailure('This chat has no recipient'));
    }

    final result = await ref
        .read(groupChatRepositoryProvider)
        .sendDirectMessage(otherUserId, body: body);
    if (!mounted) return result;

    result.fold((_) {}, (message) {
      final merged = mergeDirectMessages(state.messages, [message]);
      state = state.copyWith(
        messages: merged,
        skip: merged.length,
        total: state.total + 1,
      );
      // The server counts a sender's own message as unread until
      // `last_read_at` passes it, so the Chats list would badge it.
      unawaited(markRead());
    });
    return result;
  }

  Future<void> markRead() async {
    await ref.read(groupChatRepositoryProvider).markRoomRead(roomId);
  }
}

final directChatProvider = StateNotifierProvider.autoDispose
    .family<DirectChatNotifier, DirectChatState, String>((ref, roomId) {
      return DirectChatNotifier(ref: ref, roomId: roomId);
    });
