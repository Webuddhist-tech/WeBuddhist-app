import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_requests_filter.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/pending_prayer_sends.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Where the event room stands: 404 on resolve means chat is switched off.
enum PrayerRoomStatus { resolving, ready, closed, failed }

/// How taps turn into pray calls: batched, at most ten prayers a second.
class PrayerPacing {
  const PrayerPacing({
    this.batchWindow = const Duration(milliseconds: 300),
    this.rateWindow = const Duration(seconds: 1),
    this.retryAfter = const Duration(seconds: 1),
  });

  final Duration batchWindow;
  final Duration rateWindow;
  final Duration retryAfter;

  static const int maxPrayersPerCall = 10;
  static const int maxPrayersPerWindow = 10;
  static const int maxRetries = 3;
}

final prayerPacingProvider = Provider<PrayerPacing>((_) => const PrayerPacing());

/// The last server-confirmed prayer state of one request.
class _PrayerSnapshot {
  const _PrayerSnapshot({
    required this.prayedByMe,
    required this.prayerCount,
    required this.myPrayerCount,
    required this.recentPrayers,
  });

  _PrayerSnapshot.of(ChatMessageDTO request)
    : this(
        prayedByMe: request.prayedByMe,
        prayerCount: request.prayerCount,
        myPrayerCount: request.myPrayerCount,
        recentPrayers: request.recentPrayers,
      );

  final bool prayedByMe;
  final int prayerCount;
  final int myPrayerCount;
  final List<ChatPrayerUserDTO> recentPrayers;
}

/// Taps on one request that the server has not confirmed yet.
class _PendingPrayers {
  _PendingPrayers(this.confirmed);

  _PrayerSnapshot confirmed;
  int queued = 0;
  int inFlight = 0;
  int retries = 0;

  /// Set by a 429: nothing goes out for this request before then.
  DateTime? notBefore;

  int get outstanding => queued + inFlight;
}

/// Taps on one request still to send after the sheet closed.
class _Leftover {
  _Leftover(this.left, this.notBefore);

  int left;
  int retries = 0;
  DateTime? notBefore;
}

/// Sends the leftovers paced like the live flush: every ready request goes
/// out in the same window, and a 429 holds back only its own request.
class _Drain {
  _Drain({
    required this.repository,
    required this.roomId,
    required this.pacing,
    required this.sends,
    required this.leftovers,
    required this.windowStart,
    required this.windowSent,
  });

  final GroupChatRepository repository;
  final String roomId;
  final PrayerPacing pacing;
  final PendingPrayerSends sends;
  final Map<String, _Leftover> leftovers;
  DateTime? windowStart;
  int windowSent;
  bool _running = false;

  /// Sends until nothing is left, unless that is already under way. Sign-out
  /// waits on it.
  void start() {
    if (_running || leftovers.isEmpty) return;
    _running = true;
    sends.add(_run());
  }

  /// Takes back the taps of a call that was still out when the sheet closed
  /// and came home rate limited.
  void retry(String messageId, int count, {required int retries}) {
    final leftover = leftovers.putIfAbsent(messageId, () => _Leftover(0, null));
    leftover.left += count;
    leftover.retries = math.max(leftover.retries, retries);
    leftover.notBefore = DateTime.now().add(pacing.retryAfter);
    start();
  }

  Future<void> _run() async {
    // Cleared in the same turn the loop gives up, so a late [retry] either
    // finds the loop still looking or starts it again; never neither.
    try {
      while (leftovers.isNotEmpty) {
        final now = DateTime.now();
        var start = windowStart;
        if (start == null || now.difference(start) >= pacing.rateWindow) {
          start = windowStart = now;
          windowSent = 0;
        }
        final windowEnd = start.add(pacing.rateWindow);

        DateTime? wakeAt;
        final calls = <Future<void>>[];
        for (final entry in leftovers.entries.toList()) {
          final leftover = entry.value;
          final notBefore = leftover.notBefore;
          if (notBefore != null && now.isBefore(notBefore)) {
            wakeAt = _earliest(wakeAt, notBefore);
            continue;
          }
          final budget = math.min(
            PrayerPacing.maxPrayersPerCall,
            PrayerPacing.maxPrayersPerWindow - windowSent,
          );
          if (budget <= 0) {
            wakeAt = _earliest(wakeAt, windowEnd);
            break;
          }
          final count = math.min(leftover.left, budget);
          windowSent += count;
          calls.add(_send(entry.key, leftover, count));
        }
        await Future.wait(calls);
        if (leftovers.isEmpty) return;

        // Whatever is left either waits on its deadline or on the window.
        if (calls.isNotEmpty) wakeAt = _earliest(wakeAt, windowEnd);
        final sleep = wakeAt!.difference(DateTime.now());
        if (sleep > Duration.zero) await Future<void>.delayed(sleep);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _send(String messageId, _Leftover leftover, int count) async {
    final result = await repository.prayFor(
      roomId,
      messageIds: [messageId],
      count: count,
    );
    result.fold(
      (failure) {
        if (failure is RateLimitFailure &&
            leftover.retries < PrayerPacing.maxRetries) {
          leftover.retries += 1;
          leftover.notBefore = DateTime.now().add(pacing.retryAfter);
          return;
        }
        // Only this call's taps are given up. The rest, which may include a
        // retry handed over meanwhile, still goes out.
        leftover.retries = 0;
        leftover.left -= count;
        if (leftover.left == 0) leftovers.remove(messageId);
      },
      (_) {
        leftover.retries = 0;
        leftover.left -= count;
        if (leftover.left == 0) leftovers.remove(messageId);
      },
    );
  }
}

DateTime _earliest(DateTime? a, DateTime b) =>
    a == null || b.isBefore(a) ? b : a;

class PrayerRequestsState extends Equatable {
  final PrayerRoomStatus roomStatus;
  final String? roomId;

  /// Prayer requests only, in the order of [filter].
  final List<ChatMessageDTO> requests;
  final PrayerRequestsFilter filter;

  /// How many requests match [filter] on the server.
  final int total;
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
    this.filter = PrayerRequestsFilter.initial,
    this.total = 0,
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
    PrayerRequestsFilter? filter,
    int? total,
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
      filter: filter ?? this.filter,
      total: total ?? this.total,
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
    filter,
    total,
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
    : _repository = ref.read(groupChatRepositoryProvider),
      _pacing = ref.read(prayerPacingProvider),
      _sends = ref.read(pendingPrayerSendsProvider),
      super(const PrayerRequestsState()) {
    load();
  }

  final Ref ref;
  final String eventId;
  static const int _limit = 30;

  // Held directly so queued taps can still go out after dispose.
  final GroupChatRepository _repository;
  final PrayerPacing _pacing;
  final PendingPrayerSends _sends;

  /// Requests with taps queued or a pray call in flight.
  final Map<String, _PendingPrayers> _pending = {};
  Timer? _flushTimer;
  DateTime? _flushAt;
  DateTime? _windowStart;
  int _windowSent = 0;

  /// Set on dispose: sends what the closed sheet still owes.
  _Drain? _drain;
  ChatPrayerUserDTO? _viewer;

  /// A loaded row was deleted while a page was being fetched, so that page
  /// started one row late on the server and has to be read again.
  bool _pageShifted = false;

  /// Bumped on every first-page load, so a page fetched under an earlier
  /// filter is dropped when it lands.
  int _listGeneration = 0;

  @override
  void dispose() {
    _flushTimer?.cancel();
    _drainOnDispose();
    super.dispose();
  }

  /// The sheet closed with taps still waiting: they were shown as prayed,
  /// so send them anyway, paced as before. Sign-out waits on the send. The
  /// drain is kept for the calls still out, which may yet need a retry.
  void _drainOnDispose() {
    final roomId = state.roomId;
    final leftovers = {
      for (final entry in _pending.entries)
        if (entry.value.queued > 0)
          entry.key: _Leftover(entry.value.queued, entry.value.notBefore),
    };
    _pending.clear();
    if (roomId == null) return;
    _drain = _Drain(
      repository: _repository,
      roomId: roomId,
      pacing: _pacing,
      sends: _sends,
      leftovers: leftovers,
      windowStart: _windowStart,
      windowSent: _windowSent,
    )..start();
  }

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

  /// Re-lists under [filter] from the first page. A change while the room
  /// is still resolving is kept and used once it is.
  Future<void> setFilter(PrayerRequestsFilter filter) async {
    if (filter == state.filter) return;
    final roomId = state.roomId;
    final canList =
        roomId != null && state.roomStatus == PrayerRoomStatus.ready;
    state = state.copyWith(
      filter: filter,
      requests: const [],
      total: 0,
      skip: 0,
      hasMore: true,
      hasLoaded: !canList,
      isLoading: canList,
      isLoadingMore: false,
      clearError: true,
    );
    if (!canList) return;
    await _loadFirstPage(roomId);
  }

  Future<void> _loadFirstPage(String roomId) async {
    final generation = ++_listGeneration;
    final filter = state.filter;
    final result = await _repository.listMessages(
      roomId,
      skip: 0,
      limit: _limit,
      messageType: ChatMessageDTO.typePrayer,
      sort: filter.sortParam,
      intention: filter.intentionParam,
    );
    if (!mounted || generation != _listGeneration) return;

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
          total: page.total,
          isLoading: false,
          hasLoaded: true,
          hasMore: page.messages.length < page.total,
          skip: page.messages.length,
          clearError: true,
        );
        // Only an unfiltered total is the room's count.
        if (!filter.byIntention) _publishCount(page.total);
      },
    );
  }

  void _publishCount(int count) {
    ref.read(prayerRequestCountProvider(eventId).notifier).state = count;
  }

  /// Moves the room's count on the event screen; [inList] moves the
  /// filtered total shown above the list too.
  void _shiftCount(int delta, {bool inList = true}) {
    if (inList) state = state.copyWith(total: _clampCount(state.total + delta));
    final current = ref.read(prayerRequestCountProvider(eventId));
    if (current == null) return;
    _publishCount(_clampCount(current + delta));
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

    final generation = _listGeneration;
    final filter = state.filter;
    final result = await _repository.listMessages(
      roomId,
      skip: state.skip,
      limit: _limit,
      messageType: ChatMessageDTO.typePrayer,
      sort: filter.sortParam,
      intention: filter.intentionParam,
    );
    if (!mounted || generation != _listGeneration) return;

    if (_pageShifted) {
      _pageShifted = false;
      state = state.copyWith(isLoadingMore: false);
      // `skip` was already pulled back by the deletion, so this rereads
      // from the row the shifted page missed. A failed page retries too.
      return loadMore();
    }

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
          total: page.total,
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

  /// Re-reads the first page after a socket reconnect, merging by id.
  Future<void> refreshLatest() async {
    final roomId = state.roomId;
    if (roomId == null) return;
    final generation = _listGeneration;
    final filter = state.filter;
    final result = await _repository.listMessages(
      roomId,
      skip: 0,
      limit: _limit,
      messageType: ChatMessageDTO.typePrayer,
      sort: filter.sortParam,
      intention: filter.intentionParam,
    );
    if (!mounted || generation != _listGeneration) return;
    result.fold((_) {}, (page) {
      final pageIds = page.messages.map((message) => message.id).toSet();
      final kept = state.requests.where(
        (request) => !pageIds.contains(request.id),
      );
      final requests = [...page.messages.where(_isLive), ...kept];
      state = state.copyWith(
        requests: requests,
        total: page.total,
        skip: state.skip + (requests.length - state.requests.length),
      );
    });
  }

  /// Posts a prayer request. The created row is inserted directly; the
  /// socket echo dedupes against it by id.
  Future<Either<Failure, ChatMessageDTO>> send(
    String body, {
    required String intention,
  }) async {
    final result = await _repository.sendEventMessage(
      eventId,
      body: body,
      messageType: ChatMessageDTO.typePrayer,
      intention: intention,
    );
    if (!mounted) return result;
    result.fold((_) {}, appendLive);
    return result;
  }

  /// Edits one of the viewer's own requests in place. Only body and intention
  /// are taken from the server's answer, so prayer counts stay as they are.
  Future<Either<Failure, ChatMessageDTO>> edit(
    String messageId, {
    required String body,
    required ChatPrayerIntentionDTO intention,
  }) async {
    final roomId = state.roomId;
    final current = _find(messageId);
    if (roomId == null || current == null) {
      return const Left(NotFoundFailure('Prayer request not found'));
    }
    final result = await _repository.updateMessage(
      roomId,
      messageId: messageId,
      body: body,
      intention: intention.slug,
    );
    return result.map((updated) {
      final newBody = updated?.body ?? body;
      final newIntention = updated?.intention ?? intention;
      // Patched onto whatever the row is now, not the copy from before the
      // round trip: a prayer that landed meanwhile must survive the save.
      var message = current.copyWith(body: newBody, intention: newIntention);
      if (mounted) {
        _update(messageId, (request) {
          message = request.copyWith(body: newBody, intention: newIntention);
          return message;
        });
      }
      return message;
    });
  }

  /// A `message_updated` broadcast: another device or member's edit. One
  /// that moves the request out of the intention in view drops it.
  void applyEdit(ChatMessageDTO message) {
    if (!_isLive(message)) return;
    if (!state.filter.matches(message.intention)) {
      _dropRow(message.id, inRoom: false);
      return;
    }
    _update(
      message.id,
      (request) =>
          request.copyWith(body: message.body, intention: message.intention),
    );
  }

  /// Deletes one of the viewer's own requests for everyone, then drops it
  /// locally; the socket echo finds nothing left to remove.
  Future<Either<Failure, Unit>> delete(String messageId) async {
    final roomId = state.roomId;
    if (roomId == null) {
      return const Left(NotFoundFailure('Prayer request not found'));
    }
    final result = await _repository.deleteMessage(
      roomId,
      messageId: messageId,
    );
    if (mounted) result.fold((_) {}, (_) => applyDeletion(messageId));
    return result;
  }

  /// Inserts a prayer request that arrived over the socket or came back from
  /// a send. Anything else in the room is ignored here. One outside the
  /// intention in view still counts for the room, but is not shown.
  void appendLive(ChatMessageDTO message) {
    if (message.id.isEmpty || !_isLive(message)) return;
    if (state.roomId != null && message.roomId != state.roomId) return;
    if (state.requests.any((existing) => existing.id == message.id)) return;
    if (!state.filter.matches(message.intention)) {
      _shiftCount(1, inList: false);
      return;
    }
    state = state.copyWith(
      requests: [message, ...state.requests],
      skip: state.skip + 1,
      hasLoaded: true,
    );
    _shiftCount(1);
  }

  void applyDeletion(String messageId) => _dropRow(messageId, inRoom: true);

  /// Takes a loaded row out of the list. [inRoom] says the request is gone
  /// from the room, not only from the filter in view.
  void _dropRow(String messageId, {required bool inRoom}) {
    if (!state.requests.any((request) => request.id == messageId)) return;
    if (state.isLoadingMore) _pageShifted = true;
    state = state.copyWith(
      requests:
          state.requests.where((request) => request.id != messageId).toList(),
      skip: state.skip > 0 ? state.skip - 1 : 0,
      total: _clampCount(state.total - 1),
    );
    if (inRoom) _shiftCount(-1, inList: false);
  }

  /// A `prayers_updated` broadcast. It carries no viewer-specific state, so
  /// `prayed_by_me` is derived from [viewerId]; an empty id leaves it alone.
  void applyPrayersUpdated(
    List<ChatLivePrayerUpdate> updates, {
    required String viewerId,
  }) {
    for (final update in updates) {
      final pending = _pending[update.messageId];
      if (pending != null) {
        _mergeLive(update, pending, viewerId);
        _render(update.messageId, pending);
        continue;
      }
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

  /// Folds a broadcast into what the server confirmed so far. Nobody can
  /// un-pray, so the people count only ever grows and the larger one wins.
  void _mergeLive(
    ChatLivePrayerUpdate update,
    _PendingPrayers pending,
    String viewerId,
  ) {
    final confirmed = pending.confirmed;
    final joined =
        confirmed.prayedByMe ||
        (viewerId.isNotEmpty && update.userIds.contains(viewerId));
    pending.confirmed = _PrayerSnapshot(
      prayedByMe: joined,
      prayerCount: math.max(update.prayerCount, confirmed.prayerCount),
      myPrayerCount: confirmed.myPrayerCount,
      recentPrayers:
          joined && !confirmed.prayedByMe
              ? _stackWithViewer(confirmed.recentPrayers, _viewer)
              : confirmed.recentPrayers,
    );
  }

  void markClosed() {
    state = state.copyWith(roomStatus: PrayerRoomStatus.closed);
  }

  /// Adds one prayer, shown at once. Taps are batched into one call with a
  /// `count`, paced to the server's ten prayers a second. [viewer] joins the
  /// avatar stack on the first one.
  void pray(String messageId, {ChatPrayerUserDTO? viewer}) {
    if (state.roomId == null) return;
    final current = _find(messageId);
    if (current == null) return;
    if (viewer != null && viewer.userId.isNotEmpty) _viewer = viewer;

    final pending = _pending.putIfAbsent(
      messageId,
      () => _PendingPrayers(_PrayerSnapshot.of(current)),
    );
    pending.queued += 1;
    _render(messageId, pending);
    _scheduleFlush(_pacing.batchWindow);
  }

  /// An earlier flush already on the clock is kept; a later one is pulled in.
  void _scheduleFlush(Duration delay) {
    final at = DateTime.now().add(delay);
    final current = _flushAt;
    if ((_flushTimer?.isActive ?? false) &&
        current != null &&
        !at.isBefore(current)) {
      return;
    }
    _flushTimer?.cancel();
    _flushAt = at;
    _flushTimer = Timer(delay, _flush);
  }

  void _flush() {
    _flushTimer = null;
    _flushAt = null;
    if (!mounted) return;
    final roomId = state.roomId;
    if (roomId == null) return;

    final now = DateTime.now();
    final windowStart = _windowStart;
    if (windowStart == null ||
        now.difference(windowStart) >= _pacing.rateWindow) {
      _windowStart = now;
      _windowSent = 0;
    }

    DateTime? wakeAt;
    for (final messageId in _pending.keys.toList()) {
      final pending = _pending[messageId]!;
      if (pending.queued == 0 || pending.inFlight > 0) continue;
      final notBefore = pending.notBefore;
      if (notBefore != null && now.isBefore(notBefore)) {
        wakeAt = _earliest(wakeAt, notBefore);
        continue;
      }
      pending.notBefore = null;
      final budget = math.min(
        PrayerPacing.maxPrayersPerCall,
        PrayerPacing.maxPrayersPerWindow - _windowSent,
      );
      if (budget <= 0) {
        wakeAt = _earliest(wakeAt, _windowStart!.add(_pacing.rateWindow));
        break;
      }
      final count = math.min(pending.queued, budget);
      pending.queued -= count;
      pending.inFlight = count;
      _windowSent += count;
      _sends.add(_send(roomId, messageId, pending, count));
    }
    if (wakeAt != null) _scheduleFlush(wakeAt.difference(DateTime.now()));
  }

  Future<void> _send(
    String roomId,
    String messageId,
    _PendingPrayers pending,
    int count,
  ) async {
    final result = await _repository.prayFor(
      roomId,
      messageIds: [messageId],
      count: count,
    );
    if (!mounted) {
      // The sheet closed mid-call. These taps were shown as prayed too, so a
      // 429 is retried by the drain like the queued ones.
      final limited = result.fold((f) => f is RateLimitFailure, (_) => false);
      if (limited && pending.retries < PrayerPacing.maxRetries) {
        _drain?.retry(messageId, count, retries: pending.retries + 1);
      }
      return;
    }
    pending.inFlight = 0;

    var retry = false;
    result.fold(
      (failure) {
        if (failure is RateLimitFailure &&
            pending.retries < PrayerPacing.maxRetries) {
          pending.retries += 1;
          pending.queued += count;
          pending.notBefore = DateTime.now().add(_pacing.retryAfter);
          retry = true;
          return;
        }
        pending.retries = 0;
        final confirmed = pending.confirmed;
        if (confirmed.prayedByMe && confirmed.myPrayerCount == 0) {
          // A broadcast listed the viewer, so at least one prayer is on the
          // server, whichever device sent it. The failed taps stay uncounted.
          pending.confirmed = _PrayerSnapshot(
            prayedByMe: true,
            prayerCount: confirmed.prayerCount,
            myPrayerCount: 1,
            recentPrayers: confirmed.recentPrayers,
          );
        }
      },
      (summaries) {
        pending.retries = 0;
        final summary =
            summaries.where((s) => s.messageId == messageId).firstOrNull;
        if (summary == null) {
          // No longer a live request; nothing more to send for it.
          pending.queued = 0;
          return;
        }
        pending.confirmed = _PrayerSnapshot(
          prayedByMe: summary.prayedByMe,
          // A broadcast may already have passed this reply; keep the newer.
          prayerCount: math.max(
            summary.prayerCount,
            pending.confirmed.prayerCount,
          ),
          myPrayerCount:
              summary.myPrayerCount ?? pending.confirmed.myPrayerCount + count,
          recentPrayers:
              summary.prayedByMe
                  ? _stackWithViewer(pending.confirmed.recentPrayers, _viewer)
                  : pending.confirmed.recentPrayers,
        );
      },
    );

    if (retry) {
      _scheduleFlush(_pacing.retryAfter);
      return;
    }
    _render(messageId, pending);
    if (pending.outstanding == 0) {
      _pending.remove(messageId);
    } else {
      _scheduleFlush(Duration.zero);
    }
  }

  /// What the server confirmed plus every tap still on its way.
  void _render(String messageId, _PendingPrayers pending) {
    final confirmed = pending.confirmed;
    final taps = pending.outstanding;
    final joins = taps > 0 && !confirmed.prayedByMe;
    _update(
      messageId,
      (request) => request.copyWith(
        prayedByMe: confirmed.prayedByMe || taps > 0,
        prayerCount: confirmed.prayerCount + (joins ? 1 : 0),
        myPrayerCount: confirmed.myPrayerCount + taps,
        recentPrayers:
            joins
                ? _stackWithViewer(confirmed.recentPrayers, _viewer)
                : confirmed.recentPrayers,
      ),
    );
  }

  static bool _isLive(ChatMessageDTO message) =>
      message.isPrayerRequest && message.deletedAt == null;

  static int _clampCount(int value) => value < 0 ? 0 : value;

  /// The server keeps `recent_prayers` to three; mirror that here.
  static const int _stackSize = 3;

  static List<ChatPrayerUserDTO> _stackWithViewer(
    List<ChatPrayerUserDTO> stack,
    ChatPrayerUserDTO? viewer,
  ) {
    if (viewer == null || viewer.userId.isEmpty) return stack;
    final others = stack.where((user) => user.userId != viewer.userId);
    return [viewer, ...others].take(_stackSize).toList();
  }

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

/// The intention picker's choices, in display order.
final prayerIntentionsProvider =
    FutureProvider.autoDispose<List<ChatPrayerIntentionDTO>>((ref) async {
      final result = await ref.read(groupChatRepositoryProvider).listIntentions();
      return result.fold((failure) => throw failure, (intentions) => intentions);
    });

class PrayerSupportersState extends Equatable {
  /// Newest first.
  final List<ChatPrayerUserDTO> supporters;
  final int total;

  /// Server offset of the next page. Kept apart from [supporters] length:
  /// a newcomer shifts the roster, so a page can repeat someone already
  /// shown, and paging by the deduplicated length would re-request it.
  final int skip;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasLoaded;
  final bool hasMore;
  final String? error;

  const PrayerSupportersState({
    this.supporters = const [],
    this.total = 0,
    this.skip = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasLoaded = false,
    this.hasMore = true,
    this.error,
  });

  PrayerSupportersState copyWith({
    List<ChatPrayerUserDTO>? supporters,
    int? total,
    int? skip,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasLoaded,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return PrayerSupportersState(
      supporters: supporters ?? this.supporters,
      total: total ?? this.total,
      skip: skip ?? this.skip,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    supporters,
    total,
    skip,
    isLoading,
    isLoadingMore,
    hasLoaded,
    hasMore,
    error,
  ];
}

/// Everyone praying for one request, paged from the who-prayed endpoint.
class PrayerSupportersNotifier extends StateNotifier<PrayerSupportersState> {
  PrayerSupportersNotifier({required this.ref, required this.messageId})
    : super(const PrayerSupportersState()) {
    load();
  }

  final Ref ref;
  final String messageId;
  static const int _limit = 20;

  GroupChatRepository get _repository => ref.read(groupChatRepositoryProvider);

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.listPrayers(
      messageId,
      skip: 0,
      limit: _limit,
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
      (page) => state = _merged(const [], 0, page, isLoading: false),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final skip = state.skip;
    final result = await _repository.listPrayers(
      messageId,
      skip: skip,
      limit: _limit,
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) =>
          state = _merged(
            state.supporters,
            skip,
            page,
            isLoadingMore: false,
          ),
    );
  }

  PrayerSupportersState _merged(
    List<ChatPrayerUserDTO> existing,
    int skip,
    ChatPrayersPage page, {
    bool? isLoading,
    bool? isLoadingMore,
  }) {
    final known = existing.map((user) => user.userId).toSet();
    final fresh = page.prayers.where((user) => !known.contains(user.userId));
    final supporters = [...existing, ...fresh];
    final nextSkip = skip + page.prayers.length;
    return state.copyWith(
      supporters: supporters,
      total: page.total,
      skip: nextSkip,
      isLoading: isLoading,
      isLoadingMore: isLoadingMore,
      hasLoaded: true,
      hasMore: page.prayers.isNotEmpty && nextSkip < page.total,
      clearError: true,
    );
  }
}

/// Live prayer-request count per event, kept by [PrayerRequestsNotifier] so
/// the chip on the event screen moves with the sheet instead of waiting for
/// the next event fetch. Null until the sheet has loaded once. Lives only
/// while a chip watches it, so a later visit starts from the server count.
final prayerRequestCountProvider = StateProvider.autoDispose
    .family<int?, String>((ref, eventId) => null);

final prayerSupportersProvider = StateNotifierProvider.autoDispose
    .family<PrayerSupportersNotifier, PrayerSupportersState, String>(
      (ref, messageId) =>
          PrayerSupportersNotifier(ref: ref, messageId: messageId),
    );
