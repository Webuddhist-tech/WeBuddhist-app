import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/cache/screen_cache/cached_first_page.dart';
import 'package:flutter_pecha/core/realtime/signal_listener.dart';
import 'package:flutter_pecha/core/realtime/signal_paths.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_first_pages.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_requests_filter.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_room_scope.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_translation_language.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/pending_prayer_sends.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';

/// Where the room stands: 404 on resolve means chat is switched off.
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

/// `translation_language` for the list: the app language where the server
/// can translate into it, English otherwise.
final prayerTranslationLanguageProvider = Provider<String>(
  (ref) => prayerTranslationLanguage(ref.watch(contentLanguageProvider)),
);

/// `language` on the room resolve: which language the room's mantra comes in.
/// Lowercased: the server spells its codes `zh-hans`, not `zh-Hans`.
final prayerMantraLanguageProvider = Provider<String>(
  (ref) => ref.watch(contentLanguageProvider).toLowerCase(),
);

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

/// What changed on screen while a first page was being fetched. That page
/// was read before these changes, so they are laid back over it.
class _ChangesDuringFetch {
  /// Rows that came in by send or socket, with the viewer they came for.
  final Map<String, (ChatMessageDTO, String?)> added = {};

  /// Rows deleted from the room.
  final Set<String> deleted = {};

  /// Ids whose body, intention or completion was changed here.
  final Set<String> edited = {};
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

  /// The room's own mantra to float on a prayer; null uses the built-in one.
  final String? mantra;

  /// Prayer requests only, in the order of [filter].
  final List<ChatMessageDTO> requests;
  final PrayerRequestsFilter filter;

  /// How many requests match [filter] on the server.
  final int total;

  /// The request picked for the viewer to pray for, shown outside the list.
  /// Kept here so a prayer on it renders like one on a listed row.
  final ChatMessageDTO? spotlight;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasLoaded;
  final bool hasMore;
  final int skip;
  final String? error;

  const PrayerRequestsState({
    this.roomStatus = PrayerRoomStatus.resolving,
    this.roomId,
    this.mantra,
    this.requests = const [],
    this.filter = PrayerRequestsFilter.initial,
    this.total = 0,
    this.spotlight,
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
    String? mantra,
    bool clearMantra = false,
    List<ChatMessageDTO>? requests,
    PrayerRequestsFilter? filter,
    int? total,
    ChatMessageDTO? spotlight,
    bool clearSpotlight = false,
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
      mantra: clearMantra ? null : mantra ?? this.mantra,
      requests: requests ?? this.requests,
      filter: filter ?? this.filter,
      total: total ?? this.total,
      spotlight: clearSpotlight ? null : spotlight ?? this.spotlight,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      error: clearError ? null : error ?? this.error,
    );
  }

  /// Whether anyone else has an active request; null when this list can't tell.
  bool? othersHaveActiveRequest({String? viewerId, String? viewerEmail}) {
    if (!hasLoaded || isLoading || hasMore || error != null) return null;
    if (filter.mine || filter.byIntention) return null;
    return requests.any(
      (request) =>
          !request.isCompleted &&
          !isSelfChatMessage(
            senderId: request.senderId,
            senderEmail: request.senderEmail,
            currentUserId: viewerId,
            currentUserEmail: viewerEmail,
          ),
    );
  }

  @override
  List<Object?> get props => [
    roomStatus,
    roomId,
    mantra,
    requests,
    filter,
    total,
    spotlight,
    isLoading,
    isLoadingMore,
    hasLoaded,
    hasMore,
    skip,
    error,
  ];
}

/// The prayer requests of one event or space room.
class PrayerRequestsNotifier extends StateNotifier<PrayerRequestsState> {
  PrayerRequestsNotifier({required this.ref, required this.scope})
    : _repository = ref.read(groupChatRepositoryProvider),
      _pacing = ref.read(prayerPacingProvider),
      _sends = ref.read(pendingPrayerSendsProvider),
      super(_seed(ref, scope)) {
    // A seeded list keeps quiet about a failed re-read, like a stored one.
    _seededFromStore = state.requests.isNotEmpty;
    load();
    _creating = false;
  }

  // The stored room and page are the first state, so the sheet opens filled.
  static PrayerRequestsState _seed(Ref ref, PrayerRoomScope scope) {
    final stored =
        ref
            .read(groupChatFirstPagesProvider)
            .prayerRoom(
              scope,
              filter: PrayerRequestsFilter.initial,
              translationLanguage: ref.read(prayerTranslationLanguageProvider),
              limit: _limit,
            )
            .read();
    if (stored == null || stored.roomId.isEmpty) {
      return const PrayerRequestsState();
    }
    final page = stored.page;
    return PrayerRequestsState(
      roomStatus: PrayerRoomStatus.ready,
      roomId: stored.roomId,
      requests: page.messages,
      total: page.total,
      hasLoaded: true,
      hasMore: page.messages.length < page.total,
      skip: page.messages.length,
    );
  }

  final Ref ref;
  final PrayerRoomScope scope;
  static const int _limit = 30;

  /// The API's largest page, for re-reading loaded rows in few calls.
  static const int _windowLimit = 100;

  /// True until the constructor returns: Riverpod forbids changing another
  /// provider while this one is being created.
  bool _creating = true;

  String get _translationLanguage =>
      ref.read(prayerTranslationLanguageProvider);

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

  // Blocks paging while page one is being read again; stale pages are dropped.
  bool _firstPageInFlight = false;
  int _pageEpoch = 0;

  /// The list on screen came from the device, so a failed re-read stays quiet.
  bool _seededFromStore = false;

  /// Set while a first page is out; see [_ChangesDuringFetch].
  _ChangesDuringFetch? _changes;

  /// Live requests counted but not in the list: outside the intention in
  /// view (null) or held for the end of a sort still paging (the row, in
  /// [PrayerRequestsState.total]). Dedupes the REST reply against the echo.
  final Map<String, ChatMessageDTO?> _unlisted = {};

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

  /// Shows the stored room and page at once, then resolves the room and
  /// fetches its first page of prayer requests.
  Future<void> load() async {
    if (state.isLoading) return;
    _firstPageInFlight = true;
    try {
      await _load();
    } finally {
      _firstPageInFlight = false;
    }
  }

  Future<void> _load() async {
    // A seeded room keeps its rows and status while the server is asked again.
    final seeded = state.requests.isNotEmpty && state.roomId != null;
    state = state.copyWith(
      roomStatus: seeded ? null : PrayerRoomStatus.resolving,
      isLoading: !seeded,
      clearError: true,
    );
    if (seeded && !state.filter.byIntention && !state.filter.mine) {
      _publishCount(state.total);
    }
    final stored = state.requests.isEmpty ? _readSnapshot() : null;
    if (stored != null && stored.roomId.isNotEmpty) {
      _seededFromStore = true;
      state = state.copyWith(
        roomId: stored.roomId,
        roomStatus: PrayerRoomStatus.ready,
        clearError: true,
      );
      _applyFirstPage(stored.page);
    }

    final language = ref.read(prayerMantraLanguageProvider);
    final roomResult =
        scope.isEvent
            ? await _repository.getEventRoom(scope.id, language: language)
            : await _repository.getGroupRoom(scope.id, language: language);
    if (!mounted) return;

    final room = roomResult.fold((failure) {
      final closed = failure is NotFoundFailure;
      state = state.copyWith(
        roomStatus: closed ? PrayerRoomStatus.closed : PrayerRoomStatus.failed,
        isLoading: false,
        hasLoaded: true,
        error: closed ? null : failure.message,
      );
      return null;
    }, (room) => room);
    if (room == null) return;

    final roomId = room.id;
    final pronunciation = room.mantra?.pronunciation.trim() ?? '';
    // A retry after the room lost its mantra must drop the old text too.
    state = state.copyWith(
      roomId: roomId,
      roomStatus: PrayerRoomStatus.ready,
      mantra: pronunciation.isEmpty ? null : pronunciation,
      clearMantra: pronunciation.isEmpty,
    );
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
    final wasInFlight = _firstPageInFlight;
    _firstPageInFlight = true;
    try {
      await _readFirstPage(roomId);
    } finally {
      _firstPageInFlight = wasInFlight;
    }
  }

  Future<void> _readFirstPage(String roomId) async {
    final generation = ++_listGeneration;
    _pageShifted = false;
    _unlisted.clear();
    final source = _snapshotSource();
    // A filter change starts empty; its stored page shows while it re-reads.
    if (state.requests.isEmpty) {
      final stored = source.read();
      if (stored != null && stored.roomId == roomId) {
        _seededFromStore = true;
        state = state.copyWith(isLoading: false);
        _applyFirstPage(stored.page);
      }
    }
    final changes = _changes = _ChangesDuringFetch();
    final result = await _fetchPage(roomId, skip: 0);
    if (identical(_changes, changes)) _changes = null;
    if (!mounted || generation != _listGeneration) return;

    final seeded = _seededFromStore;
    _seededFromStore = false;
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          hasLoaded: true,
          error: seeded ? null : failure.message,
          clearError: seeded,
        );
      },
      (fetched) {
        final page = _withLocalChanges(fetched, changes);
        _applyFirstPage(page);
        _reapplyLocal(page, changes);
        unawaited(
          ref
              .read(screenCacheStoreProvider)
              .save(
                source.key,
                jsonEncode(
                  PrayerRoomSnapshot(roomId: roomId, page: page).toJson(),
                ),
              )
              .catchError((Object _) => false),
        );
      },
    );
  }

  /// Publishes a first page under the filter in view.
  void _applyFirstPage(ChatMessagesPage page) {
    _pageEpoch++;
    final filter = state.filter;
    _unlisted.removeWhere((id, _) => page.messages.any((m) => m.id == id));
    final hasMore = page.messages.length < page.total;
    final held = hasMore ? const <ChatMessageDTO>[] : _takeHeld();
    final requests = [...page.messages.where(_isLive), ...held];
    state = state.copyWith(
      requests: requests,
      total: page.total + held.length,
      isLoading: false,
      hasLoaded: true,
      hasMore: hasMore,
      skip: page.messages.length + held.length,
      clearError: true,
    );
    // Only an unfiltered total is the room's count.
    if (!filter.byIntention && !filter.mine) {
      _publishCount(page.total + held.length);
    }
  }

  /// [page] without rows deleted while it was out, and with edits made
  /// meanwhile kept over the server's older copy.
  ChatMessagesPage _withLocalChanges(
    ChatMessagesPage page,
    _ChangesDuringFetch changes,
  ) {
    if (changes.deleted.isEmpty && changes.edited.isEmpty) return page;
    final messages = <ChatMessageDTO>[];
    var removed = 0;
    for (final row in page.messages) {
      if (changes.deleted.contains(row.id)) {
        removed++;
        continue;
      }
      final local = changes.edited.contains(row.id) ? _find(row.id) : null;
      messages.add(
        local == null
            ? row
            : _edited(row, local, body: local.body, intention: local.intention),
      );
    }
    return ChatMessagesPage(
      messages: messages,
      skip: page.skip,
      limit: page.limit,
      total: _clampCount(page.total - removed),
    );
  }

  /// After a fresh first page: rows sent or pushed while it was out go back
  /// in, and taps not yet confirmed are shown over the fresh counts.
  void _reapplyLocal(ChatMessagesPage page, _ChangesDuringFetch changes) {
    for (final (message, viewerId) in changes.added.values) {
      appendLive(message, viewerId: viewerId);
    }
    for (final entry in _pending.entries) {
      ChatMessageDTO? row;
      for (final message in page.messages) {
        if (message.id == entry.key) row = message;
      }
      if (row == null) continue;
      final confirmed = entry.value.confirmed;
      entry.value.confirmed = _PrayerSnapshot(
        prayedByMe: confirmed.prayedByMe || row.prayedByMe,
        prayerCount: math.max(confirmed.prayerCount, row.prayerCount),
        myPrayerCount: math.max(confirmed.myPrayerCount, row.myPrayerCount),
        recentPrayers: row.recentPrayers,
      );
      _render(entry.key, entry.value);
    }
  }

  ScreenCacheSource<PrayerRoomSnapshot> _snapshotSource() {
    return ref
        .read(groupChatFirstPagesProvider)
        .prayerRoom(
          scope,
          filter: state.filter,
          translationLanguage: _translationLanguage,
          limit: _limit,
        );
  }

  PrayerRoomSnapshot? _readSnapshot() => _snapshotSource().read();

  /// One page under the filter in view: the room's requests, or under
  /// [PrayerRequestsFilter.mine] the viewer's own from the my-requests
  /// endpoint, narrowed to this event or space.
  Future<Either<Failure, ChatMessagesPage>> _fetchPage(
    String roomId, {
    required int skip,
    int limit = _limit,
  }) {
    final filter = state.filter;
    if (filter.mine) {
      return _repository.listMyPrayerRequests(
        skip: skip,
        limit: limit,
        eventId: scope.eventId,
        groupId: scope.groupId,
      );
    }
    return _repository.listMessages(
      roomId,
      skip: skip,
      limit: limit,
      messageType: ChatMessageDTO.typePrayer,
      sort: filter.sortParam,
      intention: filter.intentionParam,
      translationLanguage: _translationLanguage,
    );
  }

  void _publishCount(int count) {
    if (_creating) {
      Future.microtask(() {
        if (mounted) _publishCount(count);
      });
      return;
    }
    ref.read(prayerRequestCountProvider(scope).notifier).state = count;
  }

  /// Moves the room's count on the event screen; [inList] moves the
  /// filtered total shown above the list too.
  void _shiftCount(int delta, {bool inList = true}) {
    if (inList) state = state.copyWith(total: _clampCount(state.total + delta));
    final current = ref.read(prayerRequestCountProvider(scope));
    if (current == null) return;
    _publishCount(_clampCount(current + delta));
  }

  Future<void> loadMore() async {
    final roomId = state.roomId;
    if (roomId == null ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        _firstPageInFlight) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final generation = _listGeneration;
    final epoch = _pageEpoch;
    final result = await _fetchPage(roomId, skip: state.skip);
    if (!mounted || generation != _listGeneration) return;
    // Page one was replaced meanwhile; this page belongs to the old list.
    if (epoch != _pageEpoch) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

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
        _unlisted.removeWhere((id, _) => page.messages.any((m) => m.id == id));
        final hasMore =
            page.messages.isNotEmpty &&
            state.skip + page.messages.length < page.total;
        final held = hasMore ? const <ChatMessageDTO>[] : _takeHeld();
        final requests = [...state.requests, ...fresh, ...held];
        state = state.copyWith(
          requests: requests,
          total: page.total + held.length,
          isLoadingMore: false,
          hasMore: hasMore,
          skip: state.skip + page.messages.length + held.length,
          clearError: true,
        );
      },
    );
  }

  /// Re-reads every loaded row after the room's signal moved, in the order
  /// of the filter, so a change below the first page shows and paging sees
  /// a request added past the end. The signal also fires for the viewer's
  /// own prayers, so a row with taps still on their way keeps its optimistic
  /// count, and nobody can un-pray, so the larger count wins. True when a
  /// request arrived.
  Future<bool> refreshLatest() async {
    final roomId = state.roomId;
    if (roomId == null) return false;
    final generation = _listGeneration;
    final window = math.max(_limit, state.skip);
    final rows = <ChatMessageDTO>[];
    final seen = <String>{};
    var total = 0;
    for (var skip = 0; skip < window; skip += _windowLimit) {
      final result = await _fetchPage(
        roomId,
        skip: skip,
        limit: math.min(_windowLimit, window - skip),
      );
      if (!mounted || generation != _listGeneration) return false;
      final page = result.getRight().toNullable();
      if (page == null) return false;
      total = page.total;
      rows.addAll(page.messages.where((row) => seen.add(row.id)));
      if (page.messages.length < _windowLimit) break;
    }

    final known = {
      for (final request in state.requests) request.id,
      ..._unlisted.keys,
    };
    final arrived =
        total > state.total ||
        rows.any((row) => _isLive(row) && !known.contains(row.id));
    final heldById = {for (final request in state.requests) request.id: request};
    _applyFirstPage(
      ChatMessagesPage(
        messages: [for (final row in rows) _newerOf(heldById[row.id], row)],
        skip: 0,
        limit: window,
        total: total,
      ),
    );
    for (final row in rows) {
      final pending = _pending[row.id];
      if (pending == null) continue;
      _mergePage(row, pending);
      _render(row.id, pending);
    }
    return arrived;
  }

  /// Catches up once the room's listener is live. A first page in flight
  /// already will.
  Future<bool> catchUp() async {
    if (_firstPageInFlight || !state.hasLoaded) return false;
    return refreshLatest();
  }

  /// The page's row, never losing a prayer the held copy already showed.
  static ChatMessageDTO _newerOf(ChatMessageDTO? held, ChatMessageDTO page) {
    if (held == null) return page;
    final prayedByMe = held.prayedByMe || page.prayedByMe;
    return page.copyWith(
      prayedByMe: prayedByMe,
      prayerCount: math.max(page.prayerCount, held.prayerCount),
      myPrayerCount: math.max(page.myPrayerCount, held.myPrayerCount),
      recentPrayers:
          prayedByMe && !page.prayedByMe ? held.recentPrayers : page.recentPrayers,
    );
  }

  /// Posts a prayer request. The created row is inserted directly; the
  /// signal-driven refetch dedupes against it by id.
  Future<Either<Failure, ChatMessageDTO>> send(
    String body, {
    required String intention,
  }) async {
    final result =
        scope.isEvent
            ? await _repository.sendEventMessage(
              scope.id,
              body: body,
              messageType: ChatMessageDTO.typePrayer,
              intention: intention,
            )
            : await _repository.sendGroupMessage(
              scope.id,
              body: body,
              messageType: ChatMessageDTO.typePrayer,
              intention: intention,
            );
    if (!mounted) return result;
    result.fold(
      (_) {},
      (message) => appendLive(message, viewerId: message.senderId),
    );
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
      var message = _edited(
        current,
        updated,
        body: newBody,
        intention: newIntention,
      );
      if (mounted) {
        _update(messageId, (request) {
          message = _edited(
            request,
            updated,
            body: newBody,
            intention: newIntention,
          );
          return message;
        });
        _changes?.edited.add(messageId);
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
      (request) => _edited(
        request,
        message,
        body: message.body,
        intention: message.intention,
      ),
    );
    _changes?.edited.add(message.id);
  }

  /// An edit onto the row as it is now. A new body makes the old translation
  /// stale, so only what [server] sent with it, if anything, is kept. The
  /// same PATCH marks a request accomplished, so [server] also says whether
  /// it is.
  static ChatMessageDTO _edited(
    ChatMessageDTO request,
    ChatMessageDTO? server, {
    required String body,
    required ChatPrayerIntentionDTO? intention,
  }) {
    final completed = server?.isCompleted ?? request.isCompleted;
    final current = request.copyWith(
      isCompleted: completed,
      completedAt: completed ? server?.completedAt : null,
      clearCompletedAt: !completed,
    );
    if (body == current.body) {
      return current.copyWith(body: body, intention: intention);
    }
    return current.copyWith(
      body: body,
      intention: intention,
      clearTranslation: true,
      sourceLanguage: server?.sourceLanguage,
      translation: server?.translation,
      canTranslate: server?.canTranslate ?? false,
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

  /// Picks one request for the viewer to pray for and puts it in the
  /// spotlight. The listed row is preferred when there is one: it carries
  /// taps the server has not confirmed yet. [excludeIds] are the cards
  /// already shown, oldest first.
  Future<Either<Failure, ChatMessageDTO>> pickRandom({
    List<String> excludeIds = const [],
  }) async {
    final roomId = state.roomId;
    if (roomId == null) {
      return const Left(NotFoundFailure('Prayer room not ready'));
    }
    final result = await _repository.pickRandomPrayerRequest(
      roomId,
      excludeIds: excludeIds,
      translationLanguage: _translationLanguage,
    );
    if (!mounted) return result;
    return result.map((picked) {
      final shown = _find(picked.id) ?? picked;
      state = state.copyWith(spotlight: shown);
      return shown;
    });
  }

  void clearSpotlight() {
    if (state.spotlight != null) state = state.copyWith(clearSpotlight: true);
  }

  /// Marks one of the viewer's own requests accomplished, or active again,
  /// in place. The server's copy wins where it sends one.
  Future<Either<Failure, Unit>> setCompleted(
    String messageId, {
    required bool isCompleted,
  }) async {
    final roomId = state.roomId;
    if (roomId == null || _find(messageId) == null) {
      return const Left(NotFoundFailure('Prayer request not found'));
    }
    final result = await _repository.setMessageCompleted(
      roomId,
      messageId: messageId,
      isCompleted: isCompleted,
    );
    return result.map((updated) {
      if (!mounted) return unit;
      final completed = updated?.isCompleted ?? isCompleted;
      _update(
        messageId,
        (request) => request.copyWith(
          isCompleted: completed,
          completedAt: completed ? updated?.completedAt : null,
          clearCompletedAt: !completed,
        ),
      );
      _changes?.edited.add(messageId);
      return unit;
    });
  }

  /// Inserts a prayer request that arrived over the socket or came back from
  /// a send. Anything else in the room is ignored here. One outside the
  /// intention in view, or not the viewer's under [PrayerRequestsFilter.mine],
  /// still counts for the room, but is not shown. [viewerId] tells whose it
  /// is; without one nothing is the viewer's.
  void appendLive(ChatMessageDTO message, {String? viewerId}) {
    if (message.id.isEmpty || !_isLive(message)) return;
    if (state.roomId != null && message.roomId != state.roomId) return;
    if (state.requests.any((existing) => existing.id == message.id)) return;
    if (_unlisted.containsKey(message.id)) return;
    _changes?.added[message.id] = (message, viewerId);
    final viewer = viewerId?.trim() ?? '';
    final listed =
        state.filter.mine
            ? viewer.isNotEmpty && message.senderId.trim() == viewer
            : state.filter.matches(message.intention);
    if (!listed) {
      _unlisted[message.id] = null;
      _shiftCount(1, inList: false);
      return;
    }
    if (_sortsNewLast && state.hasMore) {
      // Belongs after rows not loaded yet; a later page brings it, or the
      // last page's reply lets it in.
      _unlisted[message.id] = message;
      _shiftCount(1);
      return;
    }
    state = state.copyWith(
      requests:
          _sortsNewLast
              ? [...state.requests, message]
              : [message, ...state.requests],
      skip: state.skip + 1,
      hasLoaded: true,
    );
    _shiftCount(1);
  }

  /// A request with no prayers yet lands at the end under these; under the
  /// others it comes first, with newest or fewest prayers.
  bool get _sortsNewLast {
    final filter = state.filter;
    if (filter.byIntention) return false;
    return filter.sort == PrayerSort.oldest ||
        filter.sort == PrayerSort.mostPrayed;
  }

  void applyDeletion(String messageId) => _dropRow(messageId, inRoom: true);

  /// Takes a request out of the list, or out of the ones counted but not
  /// listed. [inRoom] says it is gone from the room, not only from the
  /// filter in view, so it leaves the spotlight too, which may be the only
  /// place a picked request is shown.
  void _dropRow(String messageId, {required bool inRoom}) {
    if (inRoom) {
      _changes?.deleted.add(messageId);
      _changes?.added.remove(messageId);
    }
    if (inRoom && state.spotlight?.id == messageId) clearSpotlight();
    final unlisted = _unlisted.containsKey(messageId);
    final held = _unlisted.remove(messageId);
    final listed = state.requests.any((request) => request.id == messageId);
    if (!unlisted && !listed) return;
    if (listed) {
      if (state.isLoadingMore) _pageShifted = true;
      state = state.copyWith(
        requests:
            state.requests
                .where((request) => request.id != messageId)
                .toList(),
        skip: state.skip > 0 ? state.skip - 1 : 0,
        total: _clampCount(state.total - 1),
      );
    } else if (held != null) {
      state = state.copyWith(total: _clampCount(state.total - 1));
    }
    if (inRoom) _shiftCount(-1, inList: false);
  }

  /// Rows held for the end once paging is over. None of the pages brought
  /// them, so they were created after the server read the last page and
  /// its total leaves them out.
  List<ChatMessageDTO> _takeHeld() {
    final held = [
      for (final row in _unlisted.values)
        if (row != null) row,
    ];
    _unlisted.removeWhere((_, row) => row != null);
    return held;
  }

  /// Folds a refetched row into what the server confirmed so far for a row
  /// with taps outstanding.
  void _mergePage(ChatMessageDTO row, _PendingPrayers pending) {
    final confirmed = pending.confirmed;
    final joined = confirmed.prayedByMe || row.prayedByMe;
    pending.confirmed = _PrayerSnapshot(
      prayedByMe: joined,
      prayerCount: math.max(row.prayerCount, confirmed.prayerCount),
      myPrayerCount: math.max(row.myPrayerCount, confirmed.myPrayerCount),
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
    final spotlight = state.spotlight;
    return spotlight != null && spotlight.id == messageId ? spotlight : null;
  }

  /// Rewrites one request wherever it is shown: in the list, held for the
  /// end, and in the spotlight.
  void _update(
    String messageId,
    ChatMessageDTO Function(ChatMessageDTO request) transform,
  ) {
    final spotlight = state.spotlight;
    final lit =
        spotlight != null && spotlight.id == messageId
            ? transform(spotlight)
            : null;
    final held = _unlisted[messageId];
    if (held != null) {
      _unlisted[messageId] = transform(held);
      if (lit != null) state = state.copyWith(spotlight: lit);
      return;
    }
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
    if (changed || lit != null) {
      state = state.copyWith(
        requests: changed ? requests : null,
        spotlight: lit,
      );
    }
  }
}

final prayerRequestsProvider = StateNotifierProvider.autoDispose
    .family<PrayerRequestsNotifier, PrayerRequestsState, PrayerRoomScope>(
      (ref, scope) => PrayerRequestsNotifier(ref: ref, scope: scope),
    );

/// The intention picker's choices, in display order; stored list first.
final prayerIntentionsProvider = AsyncNotifierProvider.autoDispose<
  AutoDisposeScreenCacheNotifier<
    List<ChatPrayerIntentionDTO>,
    List<ChatPrayerIntentionDTO>
  >,
  List<ChatPrayerIntentionDTO>
>(() {
  return AutoDisposeScreenCacheNotifier((ref, bind) {
    return bind.source(
      ref.watch(groupChatFirstPagesProvider).intentions(),
      select:
          (result) =>
              result.fold((failure) => throw failure, (intentions) => intentions),
    );
  });
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
  PrayerSupportersNotifier({
    required this.ref,
    required this.messageId,
    required ScreenCacheSource<ChatPrayersPage> source,
  }) : _source = source,
       super(_seed(source)) {
    load();
  }

  // The stored page is the first state, so the first frame never spins.
  static PrayerSupportersState _seed(ScreenCacheSource<ChatPrayersPage> source) {
    final page = source.read();
    if (page == null) return const PrayerSupportersState();
    return PrayerSupportersState(
      supporters: page.prayers,
      total: page.total,
      skip: page.prayers.length,
      hasLoaded: true,
      hasMore: page.prayers.isNotEmpty && page.prayers.length < page.total,
    );
  }

  final Ref ref;
  final String messageId;
  final ScreenCacheSource<ChatPrayersPage> _source;
  static const int _limit = 20;

  // Blocks paging while page one is being read again; stale pages are dropped.
  bool _firstPageInFlight = false;
  int _pageEpoch = 0;

  GroupChatRepository get _repository => ref.read(groupChatRepositoryProvider);

  /// Stored first page shows at once; the server's replaces it if changed.
  Future<void> load() async {
    if (state.isLoading) return;
    // Only an empty roster shows the loader; a seeded one refreshes silently.
    state = state.copyWith(isLoading: state.supporters.isEmpty, clearError: true);
    _firstPageInFlight = true;
    try {
      await loadCachedFirstPage(
        _source,
        isCurrent: () => mounted,
        seed: state.supporters.isEmpty,
        fetch: () => _repository.listPrayers(messageId, skip: 0, limit: _limit),
        encode: (page) => page.toJson(),
        apply: (page) {
          _pageEpoch++;
          state = _merged(const [], 0, page, isLoading: false);
        },
        fail:
            (failure) =>
                state = state.copyWith(
                  isLoading: false,
                  hasLoaded: true,
                  error: failure.message,
                ),
      );
    } finally {
      _firstPageInFlight = false;
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        _firstPageInFlight) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final skip = state.skip;
    final epoch = _pageEpoch;
    final result = await _repository.listPrayers(
      messageId,
      skip: skip,
      limit: _limit,
    );
    if (!mounted) return;
    // Page one was replaced meanwhile; this page belongs to the old list.
    if (epoch != _pageEpoch) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }
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

/// Live prayer-request count per room, kept by [PrayerRequestsNotifier] so
/// the chip on the event screen moves with the sheet instead of waiting for
/// the next event fetch. Null until the sheet has loaded once. Lives only
/// while a chip watches it, so a later visit starts from the server count.
final prayerRequestCountProvider = StateProvider.autoDispose
    .family<int?, PrayerRoomScope>((ref, scope) => null);

final prayerSupportersProvider = StateNotifierProvider.autoDispose
    .family<PrayerSupportersNotifier, PrayerSupportersState, String>((
      ref,
      messageId,
    ) {
      return PrayerSupportersNotifier(
        ref: ref,
        messageId: messageId,
        source: ref
            .watch(groupChatFirstPagesProvider)
            .prayers(messageId, limit: PrayerSupportersNotifier._limit),
      );
    });

/// Keeps the room's prayer list current from its Firestore signal, and
/// marks it closed when the room goes. Watched by the sheet while it has a
/// room; the reader document is written after the join, so the first listen
/// is retried.
final prayerRoomLiveProvider = Provider.autoDispose
    .family<void, ({PrayerRoomScope scope, String roomId})>((ref, key) {
      final repository = ref.read(groupChatRepositoryProvider);
      PrayerRequestsNotifier notifier() =>
          ref.read(prayerRequestsProvider(key.scope).notifier);

      // The sheet is open, so new requests are seen. Events only: a space's
      // room also holds its chat.
      Future<void> markReadIfArrived(Future<bool> refresh) async {
        final arrived = await refresh;
        if (!arrived || !key.scope.isEvent) return;
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
          return;
        }
        await repository.markRoomRead(key.roomId);
      }

      listenSignal(
        ref,
        path: SignalPaths.chatRoom(key.roomId),
        fields: const {SignalFields.prayersChangedAt, SignalFields.closedAt},
        permissionRetries: 5,
        onReady: (snapshot) {
          if (snapshot[SignalFields.closedAt] != null) {
            notifier().markClosed();
            return;
          }
          unawaited(markReadIfArrived(notifier().catchUp()));
        },
        onChange: (change) {
          if (change.field == SignalFields.closedAt) {
            if (change.current != null) notifier().markClosed();
            return;
          }
          unawaited(markReadIfArrived(notifier().refreshLatest()));
        },
      );
    });
