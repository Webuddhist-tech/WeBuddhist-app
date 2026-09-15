import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Where the event room stands: 404 on resolve means chat is switched off.
enum PrayerRoomStatus { resolving, ready, closed, failed }

class PrayerRequestsState extends Equatable {
  final PrayerRoomStatus roomStatus;
  final String? roomId;

  /// Newest-first, prayer requests only.
  final List<ChatMessageDTO> requests;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasLoaded;
  final bool hasMore;
  final int skip;
  final String? error;

  const PrayerRequestsState({
    this.roomStatus = PrayerRoomStatus.resolving,
    this.roomId,
    this.requests = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasLoaded = false,
    this.hasMore = true,
    this.skip = 0,
    this.error,
  });

  PrayerRequestsState copyWith({
    PrayerRoomStatus? roomStatus,
    String? roomId,
    List<ChatMessageDTO>? requests,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasLoaded,
    bool? hasMore,
    int? skip,
    String? error,
    bool clearError = false,
  }) {
    return PrayerRequestsState(
      roomStatus: roomStatus ?? this.roomStatus,
      roomId: roomId ?? this.roomId,
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    roomStatus,
    roomId,
    requests,
    isLoading,
    isLoadingMore,
    hasLoaded,
    hasMore,
    skip,
    error,
  ];
}

/// The prayer requests of one event room.
class PrayerRequestsNotifier extends StateNotifier<PrayerRequestsState> {
  PrayerRequestsNotifier({required this.ref, required this.eventId})
    : super(const PrayerRequestsState()) {
    load();
  }

  final Ref ref;
  final String eventId;
  static const int _limit = 30;

  /// Messages with a pray/un-pray round trip in flight.
  final Set<String> _toggling = {};

  GroupChatRepository get _repository => ref.read(groupChatRepositoryProvider);

  /// Resolves the room, then fetches its first page of prayer requests.
  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(
      roomStatus: PrayerRoomStatus.resolving,
      isLoading: true,
      clearError: true,
    );

    final roomResult = await _repository.getEventRoom(eventId);
    if (!mounted) return;

    final roomId = roomResult.fold((failure) {
      final closed = failure is NotFoundFailure;
      state = state.copyWith(
        roomStatus: closed ? PrayerRoomStatus.closed : PrayerRoomStatus.failed,
        isLoading: false,
        hasLoaded: true,
        error: closed ? null : failure.message,
      );
      return null;
    }, (room) => room.id);
    if (roomId == null) return;

    state = state.copyWith(roomId: roomId, roomStatus: PrayerRoomStatus.ready);
    await _loadFirstPage(roomId);
  }

  Future<void> retry() {
    state = state.copyWith(isLoading: false);
    return load();
  }

  Future<void> _loadFirstPage(String roomId) async {
    final result = await _repository.listMessages(
      roomId,
      skip: 0,
      limit: _limit,
      messageType: ChatMessageDTO.typePrayer,
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          hasLoaded: true,
          error: failure.message,
        );
      },
      (page) {
        final requests = page.messages.where(_isLive).toList();
        state = state.copyWith(
          requests: requests,
          isLoading: false,
          hasLoaded: true,
          hasMore: page.messages.length < page.total,
          skip: page.messages.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    final roomId = state.roomId;
    if (roomId == null ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await _repository.listMessages(
      roomId,
      skip: state.skip,
      limit: _limit,
      messageType: ChatMessageDTO.typePrayer,
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        final known = state.requests.map((request) => request.id).toSet();
        final fresh =
            page.messages
                .where(
                  (message) => _isLive(message) && !known.contains(message.id),
                )
                .toList();
        final requests = [...state.requests, ...fresh];
        state = state.copyWith(
          requests: requests,
          isLoadingMore: false,
          hasMore:
              page.messages.isNotEmpty &&
              state.skip + page.messages.length < page.total,
          skip: state.skip + page.messages.length,
          clearError: true,
        );
      },
    );
  }

  /// Re-reads the newest page after a socket reconnect, merging by id.
  Future<void> refreshLatest() async {
    final roomId = state.roomId;
    if (roomId == null) return;
    final result = await _repository.listMessages(
      roomId,
      skip: 0,
      limit: _limit,
      messageType: ChatMessageDTO.typePrayer,
    );
    if (!mounted) return;
    result.fold((_) {}, (page) {
      final pageIds = page.messages.map((message) => message.id).toSet();
      final kept = state.requests.where(
        (request) => !pageIds.contains(request.id),
      );
      final requests = [...page.messages.where(_isLive), ...kept];
      state = state.copyWith(
        requests: requests,
        skip: state.skip + (requests.length - state.requests.length),
      );
    });
  }

  /// Posts a prayer request. The created row is inserted directly; the
  /// socket echo dedupes against it by id.
  Future<Either<Failure, ChatMessageDTO>> send(String body) async {
    final result = await _repository.sendEventMessage(
      eventId,
      body: body,
      messageType: ChatMessageDTO.typePrayer,
    );
    if (!mounted) return result;
    result.fold((_) {}, appendLive);
    return result;
  }

  /// Inserts a prayer request that arrived over the socket or came back from
  /// a send. Anything else in the room is ignored here.
  void appendLive(ChatMessageDTO message) {
    if (message.id.isEmpty || !_isLive(message)) return;
    if (state.roomId != null && message.roomId != state.roomId) return;
    if (state.requests.any((existing) => existing.id == message.id)) return;
    state = state.copyWith(
      requests: [message, ...state.requests],
      skip: state.skip + 1,
      hasLoaded: true,
    );
  }

  void applyDeletion(String messageId) {
    if (!state.requests.any((request) => request.id == messageId)) return;
    state = state.copyWith(
      requests:
          state.requests.where((request) => request.id != messageId).toList(),
      skip: state.skip > 0 ? state.skip - 1 : 0,
    );
  }

  /// A `prayers_updated` broadcast. It carries no viewer-specific state, so
  /// `prayed_by_me` is derived from [viewerId]; an empty id leaves it alone.
  void applyPrayersUpdated(
    List<ChatLivePrayerUpdate> updates, {
    required String viewerId,
  }) {
    for (final update in updates) {
      // A round trip in flight already knows the answer; its response wins.
      if (_toggling.contains(update.messageId)) continue;
      _update(
        update.messageId,
        (request) => request.copyWith(
          prayerCount: update.prayerCount,
          prayedByMe:
              viewerId.isEmpty
                  ? request.prayedByMe
                  : update.userIds.contains(viewerId),
        ),
      );
    }
  }

  void markClosed() {
    state = state.copyWith(roomStatus: PrayerRoomStatus.closed);
  }

  /// Prays or takes a prayer back, optimistically.
  Future<void> togglePrayer(String messageId) async {
    final roomId = state.roomId;
    if (roomId == null || _toggling.contains(messageId)) return;
    final current = _find(messageId);
    if (current == null) return;

    final wasPrayed = current.prayedByMe;
    final delta = wasPrayed ? -1 : 1;
    _toggling.add(messageId);
    _update(
      messageId,
      (request) => request.copyWith(
        prayedByMe: !wasPrayed,
        prayerCount: _clampCount(request.prayerCount + delta),
      ),
    );

    final result =
        wasPrayed
            ? (await _repository.removePrayer(
              messageId,
            )).map((summary) => [summary])
            : await _repository.prayFor(roomId, messageIds: [messageId]);
    _toggling.remove(messageId);
    if (!mounted) return;

    result.fold(
      (_) => _update(
        messageId,
        (request) => request.copyWith(
          prayedByMe: wasPrayed,
          prayerCount: _clampCount(request.prayerCount - delta),
        ),
      ),
      (summaries) {
        for (final summary in summaries) {
          _update(
            summary.messageId,
            (request) => request.copyWith(
              prayerCount: summary.prayerCount,
              prayedByMe: summary.prayedByMe,
            ),
          );
        }
      },
    );
  }

  static bool _isLive(ChatMessageDTO message) =>
      message.isPrayerRequest && message.deletedAt == null;

  static int _clampCount(int value) => value < 0 ? 0 : value;

  ChatMessageDTO? _find(String messageId) {
    for (final request in state.requests) {
      if (request.id == messageId) return request;
    }
    return null;
  }

  void _update(
    String messageId,
    ChatMessageDTO Function(ChatMessageDTO request) transform,
  ) {
    var changed = false;
    final requests = [
      for (final request in state.requests)
        if (request.id == messageId)
          () {
            changed = true;
            return transform(request);
          }()
        else
          request,
    ];
    if (changed) state = state.copyWith(requests: requests);
  }
}

final prayerRequestsProvider = StateNotifierProvider.autoDispose
    .family<PrayerRequestsNotifier, PrayerRequestsState, String>(
      (ref, eventId) => PrayerRequestsNotifier(ref: ref, eventId: eventId),
    );
