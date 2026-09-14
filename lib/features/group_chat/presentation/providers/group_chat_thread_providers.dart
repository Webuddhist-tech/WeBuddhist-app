import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/chat_link_preview_service.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reactions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupChatThreadState extends Equatable {
  /// Newest-first, exactly as the API returns them. Rendered through
  /// `ListView(reverse: true)`, so nothing is reversed per rebuild.
  final List<ChatMessageDTO> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;
  final int total;

  /// Whether the first fetch has settled, so the empty state never flashes
  /// before the initial request lands.
  final bool hasLoaded;

  const GroupChatThreadState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.total = 0,
    this.hasLoaded = false,
  });

  GroupChatThreadState copyWith({
    List<ChatMessageDTO>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    int? total,
    bool? hasLoaded,
    bool clearError = false,
  }) {
    return GroupChatThreadState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      total: total ?? this.total,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    isLoading,
    isLoadingMore,
    error,
    hasMore,
    skip,
    total,
    hasLoaded,
  ];
}

/// What a `refreshLatest` found, for the caller deciding whether the socket
/// that should have delivered it can still be trusted.
enum ThreadRefreshResult {
  /// The request failed, so nothing can be said either way.
  failed,

  /// Every message the page carried was already held.
  nothingMissed,

  /// The page carried a message nothing else had delivered.
  missedMessages,
}

class GroupChatThreadNotifier extends StateNotifier<GroupChatThreadState> {
  GroupChatThreadNotifier({required this.ref, required this.roomId})
    : super(const GroupChatThreadState()) {
    loadInitial();
  }

  final Ref ref;
  final String roomId;
  static const int _limit = 30;

  /// Per message, the sequence number of the most recent toggle and the tail
  /// of its in-flight work. Overlapping taps on one message would otherwise
  /// each derive a baseline from the other's optimistic state, then roll back
  /// or apply a summary that no longer matches what the user last chose.
  final Map<String, int> _toggleSeq = {};
  final Map<String, Future<void>> _toggleChain = {};

  /// Per message, the emoji this member holds **on the server**.
  ///
  /// Advanced only by confirmed calls: a successful POST adds, a successful
  /// DELETE removes, a failure changes nothing. Any summary that can identify
  /// the viewer replaces it outright, which is what prunes it.
  ///
  /// It deliberately **outlives the burst**. Rebuilding it from displayed state
  /// each time only works while the display knows which reactions are the
  /// viewer's, and a summary carrying no `users` or `user_ids` cannot say —
  /// so a duplicate left by a failed cleanup would stop being recognised as
  /// owned and could never be retried. Later taps must also never read their
  /// cleanup target from optimistic state: if an earlier queued POST failed,
  /// that state names an emoji the server never received.
  final Map<String, Set<String>> _serverOwn = {};

  /// Messages mid-swap. Between the POST of the new emoji and the DELETE of
  /// the old one the server legitimately holds **both**, and so does any
  /// `reactions_updated` broadcast in that window. Adopting either would show
  /// two emoji for the ~600ms the round trip takes, so summaries for these
  /// messages are ignored until the swap settles.
  final Set<String> _swapping = {};

  /// Every summary that arrived for a message while it was mid-swap, in
  /// arrival order.
  ///
  /// Dropping these outright loses a reaction another member added during the
  /// swap. Replaying one blindly is just as wrong: the broadcast fans out to
  /// the actor too, so some of them are this client's own intermediate state,
  /// carrying both the old emoji and the new one. Nothing on the wire orders
  /// the two — there is no version or sequence on a reaction payload — so the
  /// tie is broken on content once the swap settles: a summary is adopted only
  /// if it agrees with what this member is known to hold on the server, which
  /// an intermediate echo never does.
  ///
  /// All of them, not the last: the same missing order means a member's
  /// summary that does agree can be followed by an echo that does not, and a
  /// single slot let the echo overwrite the one worth keeping. Among those
  /// that agree, one that would change nothing is passed over for the same
  /// reason — see [_replayDeferredReaction].
  final Map<String, List<List<ChatMessageReactionDTO>>> _deferredReactions = {};

  /// Bumped whenever a message's reactions change locally. A refetch compares
  /// the value it saw before its request with the value on arrival: checking
  /// `_swapping` alone only asks whether a swap is running *now*, so a page
  /// requested before a swap and delivered after it would overwrite the
  /// freshly confirmed reaction with its own stale snapshot.
  final Map<String, int> _reactionRevision = {};

  /// Summaries that arrived for a message not yet in the loaded window while
  /// a page request was in flight. That page carries a snapshot older than the
  /// broadcast, so the broadcast is held and applied to the row the page
  /// inserts rather than being overwritten by it.
  ///
  /// Only kept while a fetch is running. Outside one the original reasoning
  /// holds: a message outside the window is refetched with current counts
  /// anyway, so dropping the update is correct.
  final Map<String, List<ChatMessageReactionDTO>> _pendingReactions = {};

  /// Deletions that arrived while a page request was in flight, whether or
  /// not the message was loaded yet: a page built before the deletion commits
  /// the row as live either way. Held until no fetch is running, then swept
  /// over whatever was committed — see [_applyPendingDeletions].
  final Map<String, String> _pendingDeletions = {};

  /// How many page requests are in flight. A broadcast is only worth holding
  /// while one of them might be carrying the message it names.
  int _fetchesInFlight = 0;

  /// Runs a page request with [_fetchesInFlight] raised for its duration.
  Future<T> _guardFetch<T>(Future<T> Function() fetch) async {
    _fetchesInFlight++;
    try {
      return await fetch();
    } finally {
      _fetchesInFlight--;
    }
  }

  /// Applies anything held while this page was in flight. It is newer than
  /// the page's own snapshot of the same message.
  ChatMessageDTO _withPendingUpdates(ChatMessageDTO message) {
    final reactions = _pendingReactions.remove(message.id);
    if (reactions == null) return message;
    return message.copyWith(reactions: reactions);
  }

  /// Applies deletions held while a page was in flight, across the whole list.
  ///
  /// A sweep rather than a per-row hook, because `refreshLatest` commits its
  /// rows through several branches — restart, merge, first load — and a row it
  /// drops as a duplicate on the way in would take the marker with it, since
  /// the map has already forgotten it. Running last, over whatever was
  /// actually committed, treats an inserted row and an already-held one alike.
  void _applyPendingDeletions() {
    if (_pendingDeletions.isEmpty) return;

    var changed = false;
    final messages = [
      for (final message in state.messages)
        if (message.deletedAt != null)
          message
        else
          () {
            // Read, not consumed: a second page still in flight can commit
            // the same stale copy, and `_dropStalePending` clears the map
            // once none is running.
            final deletedAt = _pendingDeletions[message.id];
            if (deletedAt == null) return message;
            changed = true;
            return message.copyWith(deletedAt: deletedAt);
          }(),
    ];

    if (changed) state = state.copyWith(messages: messages);
  }

  /// Anything still held once no fetch is running names a message no page is
  /// going to insert, so it is dropped rather than kept for good.
  void _dropStalePending() {
    if (_fetchesInFlight > 0) return;
    _pendingReactions.clear();
    _pendingDeletions.clear();
  }

  void _bumpRevision(String messageId) {
    _reactionRevision[messageId] = (_reactionRevision[messageId] ?? 0) + 1;
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _guardFetch(
      () => ref
          .read(groupChatRepositoryProvider)
          .listMessages(roomId, skip: 0, limit: _limit),
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
        state = state.copyWith(
          messages: page.messages.map(_withPendingUpdates).toList(),
          isLoading: false,
          hasLoaded: true,
          hasMore: page.messages.length < page.total,
          skip: page.messages.length,
          total: page.total,
          clearError: true,
        );
      },
    );
    _applyPendingDeletions();
    _dropStalePending();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await _guardFetch(
      () => ref
          .read(groupChatRepositoryProvider)
          .listMessages(roomId, skip: state.skip, limit: _limit),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        // Older messages are a tail append in newest-first order. Ids already
        // held are dropped so a live insert shifting the window cannot
        // duplicate a row.
        final known = state.messages.map((message) => message.id).toSet();
        final fresh =
            page.messages
                .where((message) => !known.contains(message.id))
                .map(_withPendingUpdates)
                .toList();
        final messages = [...state.messages, ...fresh];
        state = state.copyWith(
          messages: messages,
          isLoadingMore: false,
          hasMore: page.messages.isNotEmpty && messages.length < page.total,
          skip: state.skip + page.messages.length,
          total: page.total,
          clearError: true,
        );
      },
    );
    _applyPendingDeletions();
    _dropStalePending();
  }

  /// Inserts a message that arrived over the socket or came back from a REST
  /// send. Deduped by id, so a send that also echoes as `message_created`
  /// produces exactly one row.
  void appendLive(ChatMessageDTO message) {
    if (message.id.isEmpty) return;
    if (state.messages.any((existing) => existing.id == message.id)) return;
    state = state.copyWith(
      messages: [message, ...state.messages],
      skip: state.skip + 1,
      total: state.total + 1,
      hasLoaded: true,
    );
  }

  /// A `message_created` frame. Same insert as [appendLive], but it also
  /// vouches for the socket: a `refreshLatest` waiting on this id learns the
  /// socket did deliver it, just after the page had already landed.
  ///
  /// Only the socket path calls this. The POST response for an own message
  /// and the refresh's own inserts go through [appendLive], because neither
  /// says anything about whether the socket is working.
  void appendFromSocket(ChatMessageDTO message) {
    if (_awaitingSocket.containsKey(message.id)) {
      _vouchedBySocket.add(message.id);
    }
    appendLive(message);
  }

  /// Ids a `refreshLatest` inserted itself and is now giving the socket a
  /// grace window to deliver, with how many refreshes are waiting on each.
  final Map<String, int> _awaitingSocket = {};

  /// Ids in [_awaitingSocket] the socket has since delivered.
  final Set<String> _vouchedBySocket = {};

  /// Decides between `missedMessages` and `nothingMissed` for rows this
  /// refresh inserted itself.
  ///
  /// The page landing before the socket frame is not proof the socket is
  /// dead: the push, the frame and the refetch all race, and a frame held up
  /// by a few hundred milliseconds of jitter arrives right after the page
  /// did. Judging at the instant the page lands would call that a miss and
  /// have the caller replace a healthy socket. So the socket is given
  /// [grace] to deliver what the page carried, and only what it still has not
  /// delivered by then counts.
  Future<ThreadRefreshResult> _judgeMissed(
    Set<String> missedIds,
    Duration grace,
  ) async {
    if (missedIds.isEmpty) return ThreadRefreshResult.nothingMissed;
    if (grace <= Duration.zero) return ThreadRefreshResult.missedMessages;

    for (final id in missedIds) {
      _awaitingSocket[id] = (_awaitingSocket[id] ?? 0) + 1;
    }
    await Future<void>.delayed(grace);

    // Read before the release below: the last waiter clears the record.
    final stillMissing = missedIds.any(
      (id) => !_vouchedBySocket.contains(id),
    );
    for (final id in missedIds) {
      final waiters = (_awaitingSocket[id] ?? 1) - 1;
      if (waiters > 0) {
        _awaitingSocket[id] = waiters;
      } else {
        _awaitingSocket.remove(id);
        _vouchedBySocket.remove(id);
      }
    }
    if (!mounted) return ThreadRefreshResult.failed;
    return stillMissing
        ? ThreadRefreshResult.missedMessages
        : ThreadRefreshResult.nothingMissed;
  }

  /// Re-reads the newest page after a reconnect and merges by id, so anything
  /// missed while the socket was down lands without duplicating what is held.
  ///
  /// Reports whether the page carried a message nothing else had delivered by
  /// the time it was merged. A message the socket delivered while the request
  /// was in flight is already held when the page lands, so it does not count:
  /// the socket did its job, just not before the refetch went out.
  ///
  /// [socketGrace] extends that allowance past the merge: rows this refresh
  /// had to insert itself are reported as missed only if the socket has still
  /// not delivered them (via [appendFromSocket]) once the window closes. The
  /// merge itself is committed before the wait, so the rows are on screen
  /// either way; only the verdict is delayed. Zero judges at the merge.
  Future<ThreadRefreshResult> refreshLatest({
    String? currentUserId,
    String? currentUserEmail,
    Duration socketGrace = Duration.zero,
  }) async {
    // Taken before the request goes out, so anything that changes while it is
    // in flight is visible on arrival.
    final revisionsBefore = {
      for (final message in state.messages)
        message.id: _reactionRevision[message.id] ?? 0,
    };
    // Identity is snapshot for the same reason. Only the history held when the
    // request went out can say whether the page that comes back is contiguous
    // with it; a message appended over the socket meanwhile has no standing in
    // that question, and reading it back out of post-await state would let one
    // such insert suppress a restart the gap actually needs.
    final knownBefore = state.messages.map((message) => message.id).toSet();

    final result = await _guardFetch(
      () => ref
          .read(groupChatRepositoryProvider)
          .listMessages(roomId, skip: 0, limit: _limit),
    );

    if (!mounted) return ThreadRefreshResult.failed;

    // The ids of every row this refresh inserted itself, or null on failure.
    // Judged after the merge is committed, not inside the fold, so the wait
    // does not hold back rows the caller should already see.
    final missedIds = result.fold<Set<String>?>((_) => null, (page) {
      List<ChatMessageReactionDTO> resolve(
        List<ChatMessageReactionDTO> reactions,
      ) {
        if (reactions.isEmpty) return reactions;
        return chatReactionsForViewer(
          reactions,
          currentUserId: currentUserId,
          currentUserEmail: currentUserEmail,
        );
      }

      /// Adopts the summary held for this row while the page was in flight.
      ///
      /// Taken at the point the row is committed rather than when the page is
      /// parsed. The merge below can keep the copy already held instead of the
      /// fetched one, and a summary lifted out of the map into a copy that is
      /// then dropped is lost for good — the map has already forgotten it.
      ChatMessageDTO withPending(ChatMessageDTO message) {
        final pending = _pendingReactions.remove(message.id);
        if (pending == null) return message;
        return message.copyWith(reactions: resolve(pending));
      }

      final fetched = [
        for (final message in page.messages)
          if (message.reactions.isEmpty)
            message
          else
            message.copyWith(reactions: resolve(message.reactions)),
      ];
      final fetchedIds = {for (final message in fetched) message.id};

      /// Rows `appendLive` prepended since [knownBefore] was taken, minus any
      /// this page already carries.
      ///
      /// "Not held before and not in this page" is not enough on its own:
      /// nothing stops `loadMore` finishing inside the same window — it gates
      /// on `isLoadingMore` and `isLoading`, and a refresh sets neither — and
      /// the older page it appends fits that description too, while already
      /// being inside the server's count. Position separates them. The rows
      /// held when the request went out form one contiguous block, because
      /// the two writers add at opposite ends of it: `appendLive` prepends an
      /// arrival above the block, `loadMore` appends history below it. So
      /// everything above the first held row came over the socket and is
      /// newer than this page; everything below the last came from `loadMore`
      /// and the server has already counted it. Cutting at the first held row
      /// rather than at a page row is what lets this hold for a page that
      /// shares nothing with what is held. Rows the page carries are excluded
      /// by id: the socket does not promise creation order, so an arrival the
      /// page includes can land on top of one it does not.
      List<ChatMessageDTO> arrivedSince(Set<String> pageIds) {
        final firstKnown = state.messages.indexWhere(
          (message) => knownBefore.contains(message.id),
        );
        // Every held row was in `knownBefore` and nothing removes rows, so
        // this is unreachable today. Should it ever be reached the two cannot
        // be told apart, and misordering older history is the lesser harm
        // next to dropping what the socket delivered.
        if (firstKnown < 0) {
          return state.messages
              .where(
                (message) =>
                    !knownBefore.contains(message.id) &&
                    !pageIds.contains(message.id),
              )
              .toList();
        }
        return state.messages
            .take(firstKnown)
            .where((message) => !pageIds.contains(message.id))
            .toList();
      }

      if (state.messages.isEmpty) {
        // Only a thread that had loaded can have missed anything: an empty
        // list before the first page lands says nothing about the socket.
        final missed = state.hasLoaded ? fetchedIds : <String>{};
        final messages = fetched.map(withPending).toList();
        state = state.copyWith(
          messages: messages,
          hasLoaded: true,
          hasMore: messages.length < page.total,
          skip: messages.length,
          total: page.total,
          clearError: true,
        );
        return missed;
      }

      // A full page with nothing in common with what is held means more
      // arrived while the socket was down than one page can carry. The middle
      // is missing, so the retained tail is not contiguous with it — keeping
      // both would leave `skip` pointing past the gap and those messages
      // would never load. Start again from the newest page and let `loadMore`
      // walk back through the gap.
      final overlaps = fetched.any(
        (message) => knownBefore.contains(message.id),
      );
      if (!overlaps && fetched.length >= _limit) {
        // Restarting must not throw away what the restored socket delivered
        // while this page was in flight: those rows are newer than the page,
        // so they sit above it, and the count that came with it predates
        // them. Older history `loadMore` appended meanwhile is neither — it
        // is what the restart will walk back through, and `arrivedSince`
        // keeps it out of both the list and the count.
        final arrivedDuring = arrivedSince(fetchedIds);

        final messages = [...arrivedDuring, ...fetched.map(withPending)];
        final total = page.total + arrivedDuring.length;
        state = state.copyWith(
          messages: messages,
          hasLoaded: true,
          hasMore: messages.length < total,
          skip: messages.length,
          total: total,
          clearError: true,
        );
        // A whole page of rows nothing here had seen.
        return fetchedIds;
      }

      // Refresh what is already held rather than skipping it. A reaction that
      // changed while the socket was down arrives on a message whose id we
      // already have, and `appendLive` alone would drop that update on the
      // floor. A message mid-swap is left alone — its optimistic state is
      // newer than this page.
      final fetchedById = {for (final message in fetched) message.id: message};

      // What the socket delivered while the request was in flight, which the
      // count that came back with it cannot include. Counted before the
      // page's own rows are inserted further down.
      final arrivedDuring = arrivedSince(fetchedIds).length;

      // Judged against what is held now, not when the request went out, so a
      // row the socket delivered meanwhile counts as delivered.
      final heldNow = {for (final message in state.messages) message.id};
      final missed = fetchedIds.difference(heldNow);

      state = state.copyWith(
        messages:
            state.messages.map((existing) {
              // A summary held while this page was in flight is newer than the
              // page and newer than what is held, so it settles the row before
              // either branch below gets to.
              final pending = _pendingReactions.remove(existing.id);
              if (pending != null) {
                return existing.copyWith(reactions: resolve(pending));
              }

              final fresh = fetchedById[existing.id];
              if (fresh == null) return existing;

              // Anything touched since this request was sent is newer than the
              // page it brought back, whether or not that work has finished by
              // the time the page arrives.
              final changed =
                  (_reactionRevision[existing.id] ?? 0) !=
                  (revisionsBefore[existing.id] ?? 0);
              if (changed || _swapping.contains(existing.id)) return existing;

              return fresh;
            }).toList(),
      );

      // Oldest first, so each insert lands above the previous one and the
      // newest-first order is preserved.
      for (final message in fetched.reversed) {
        appendLive(withPending(message));
      }

      // The server's count plus what the socket delivered after the server
      // counted. Taking the page's figure alone walks `total` backwards past
      // those arrivals, and in a room small enough for the difference to
      // matter that leaves `hasMore` false — after which `loadMore` returns
      // immediately and the thread will not page back any further.
      final total = page.total + arrivedDuring;
      state = state.copyWith(
        total: total,
        hasMore: state.messages.length < total,
      );
      return missed;
    });
    _applyPendingDeletions();
    _dropStalePending();
    if (missedIds == null) return ThreadRefreshResult.failed;
    return _judgeMissed(missedIds, socketGrace);
  }

  /// Rewrites one message's reactions from an authoritative summary — the
  /// REST response to our own call, or a `reactions_updated` broadcast.
  ///
  /// A message that has scrolled out of the loaded window is simply absent;
  /// dropping the update is correct, since `loadMore` refetches with current
  /// counts.
  void replaceReactions(
    String messageId,
    List<ChatMessageReactionDTO> reactions, {
    String? currentUserId,
    String? currentUserEmail,
  }) {
    if (_swapping.contains(messageId)) {
      // Held, not dropped: each is judged against the swap's own result once
      // that lands.
      (_deferredReactions[messageId] ??= []).add(reactions);
      return;
    }
    _applyReactions(
      messageId,
      reactions,
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );
  }

  /// Adopts a summary held during a swap, when it proves to be newer than the
  /// swap's own result.
  void _replayDeferredReaction(
    String messageId, {
    String? currentUserId,
    String? currentUserEmail,
  }) {
    final deferred = _deferredReactions.remove(messageId);
    if (deferred == null) return;

    final index = state.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index < 0) return;
    final current = state.messages[index].reactions;
    final settled = _serverOwn[messageId] ?? const <String>{};
    // Newest first, so the latest summary that qualifies is the one adopted.
    for (final summary in deferred.reversed) {
      final own = _ownFromSummary(
        summary,
        currentUserId: currentUserId,
        currentUserEmail: currentUserEmail,
      );
      // Unidentifiable is not the same as newer: with no way to tell whose
      // reactions these are, a later broadcast cannot be told from our own
      // echo, and what the swap applied came from a confirmed call.
      if (own == null) continue;

      // An echo from inside the swap still shows the emoji being replaced, so
      // it disagrees with the settled set and is passed over. Anything that
      // agrees was computed after the swap and may carry another member's
      // reaction the swap's own response was too early to include.
      if (own.length != settled.length || !own.every(settled.contains)) {
        continue;
      }

      // A summary that would change nothing cannot be newer than what is
      // shown, and must not shadow an earlier one that would. The swap's own
      // echo carries exactly the state its response already applied, and
      // with nothing on the wire to order them it can land after a member's
      // fuller update rather than before it — adopting it as "latest" would
      // drop that member's reaction.
      final resolved = chatReactionsForViewer(
        summary,
        currentUserId: currentUserId,
        currentUserEmail: currentUserEmail,
      );
      if (listEquals(resolved, current)) continue;

      _applyReactions(
        messageId,
        summary,
        currentUserId: currentUserId,
        currentUserEmail: currentUserEmail,
      );
      return;
    }
  }

  void _applyReactions(
    String messageId,
    List<ChatMessageReactionDTO> reactions, {
    String? currentUserId,
    String? currentUserEmail,
  }) {
    if (messageId.isEmpty) return;
    if (!state.messages.any((message) => message.id == messageId)) {
      // Not in the loaded window. While a page is in flight that page may be
      // carrying this very message, with a snapshot taken before this update —
      // so the summary is held for the row it inserts. The revision moves with
      // it, so an even older page still in flight cannot overwrite the result.
      if (_fetchesInFlight > 0) {
        _pendingReactions[messageId] = reactions;
        _bumpRevision(messageId);
      }
      return;
    }

    _bumpRevision(messageId);

    // Whenever a summary can say who holds what, it is more authoritative than
    // anything tracked — this is what keeps `_serverOwn` from going stale.
    final own = _ownFromSummary(
      reactions,
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );
    if (own != null) _serverOwn[messageId] = own;

    final resolved = chatReactionsForViewer(
      reactions,
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );

    state = state.copyWith(
      messages:
          state.messages
              .map(
                (message) =>
                    message.id == messageId
                        ? message.copyWith(reactions: resolved)
                        : message,
              )
              .toList(),
    );
  }

  /// Applies a reaction with WhatsApp semantics: a member holds **one**
  /// reaction per message, so tapping a different emoji swaps it.
  ///
  /// The API does not enforce that — add and remove are per-emoji and
  /// idempotent — so the swap is the client's job. The POST goes first so the
  /// message never flickers through a zero-reaction state, and only the
  /// **final** summary is adopted: the one in between has both emoji on it.
  /// Rolls back to the pre-toggle reactions if the first call fails.
  Future<Failure?> toggleReaction(
    String messageId,
    String emoji, {
    required String roomIdForCall,
    String? currentUserId,
    String? currentUserEmail,
  }) async {
    final index = state.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index < 0) return null;

    final seq = (_toggleSeq[messageId] ?? 0) + 1;
    _toggleSeq[messageId] = seq;

    final baseline = state.messages[index].reactions;
    final previousEmoji = currentChatReactionEmoji(baseline);
    final isRemoval = previousEmoji == emoji;
    final isSwap = !isRemoval && previousEmoji != null;
    if (isSwap) _swapping.add(messageId);

    // First tap of a burst: this baseline is still confirmed state, so it is
    // the only trustworthy seed. Later taps inherit it rather than reseeding
    // from their own optimistic baseline.
    if (!_toggleChain.containsKey(messageId)) {
      // Union, not replacement: what the display knows the viewer holds, plus
      // anything still recorded from an earlier burst whose cleanup failed.
      // Every reaction, not just the first — one failed cleanup leaves two.
      _serverOwn[messageId] = {
        ...?_serverOwn[messageId],
        ...ownChatReactionEmoji(baseline),
      };
    }

    // Optimistic, and synchronously so: the tap has to read as instant, and a
    // broadcast arriving in the same frame must not overwrite it.
    _setReactions(
      messageId,
      toggleChatReaction(
        baseline,
        emoji,
        previousEmoji: previousEmoji,
        viewerId: currentUserId,
        viewerEmail: currentUserEmail,
      ),
    );

    // Only the requests are chained, per message, so the server sees the taps
    // in the order they were made and a rollback can never undo a later
    // choice.
    final queued = _toggleChain[messageId] ?? Future<void>.value();
    Failure? failure;
    final run = queued.then((_) async {
      failure = await _runToggle(
        messageId,
        emoji,
        seq: seq,
        baseline: baseline,
        previousEmoji: previousEmoji,
        isRemoval: isRemoval,
        isSwap: isSwap,
        roomIdForCall: roomIdForCall,
        currentUserId: currentUserId,
        currentUserEmail: currentUserEmail,
      );
    });
    _toggleChain[messageId] = run.catchError((Object _) {});

    await _toggleChain[messageId];
    if (_toggleSeq[messageId] == seq) {
      _toggleSeq.remove(messageId);
      _toggleChain.remove(messageId);
      // `_serverOwn` is not cleared here: an unresolved duplicate has to
      // survive into the next burst to be retried. An identifying summary
      // prunes it instead.
      // The last operation for this message owns the cleanup, whichever one
      // opened the swap guard.
      _swapping.remove(messageId);
      if (mounted) {
        _replayDeferredReaction(
          messageId,
          currentUserId: currentUserId,
          currentUserEmail: currentUserEmail,
        );
      }
    }
    return failure;
  }

  /// Whether this operation is still the newest one for its message. A
  /// superseded toggle neither applies its summary nor rolls back — the newer
  /// one owns the state.
  bool _isCurrent(String messageId, int seq) => _toggleSeq[messageId] == seq;

  Future<Failure?> _runToggle(
    String messageId,
    String emoji, {
    required int seq,
    required List<ChatMessageReactionDTO> baseline,
    required String? previousEmoji,
    required bool isRemoval,
    required bool isSwap,
    required String roomIdForCall,
    String? currentUserId,
    String? currentUserEmail,
  }) async {
    if (!mounted) return null;
    final previousReactions = baseline;

    final repository = ref.read(groupChatRepositoryProvider);
    final result =
        isRemoval
            ? await repository.removeReaction(
              roomIdForCall,
              messageId: messageId,
              emoji: emoji,
            )
            : await repository.addReaction(
              roomIdForCall,
              messageId: messageId,
              emoji: emoji,
            );

    if (!mounted) return null;

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure != null) {
      // Rolling back to this operation's baseline would wipe a newer tap.
      if (_isCurrent(messageId, seq)) {
        _setReactions(messageId, previousReactions);
      }
      return failure;
    }

    var summary = result.getOrElse((_) => const []);

    // This call is confirmed, so the server's state for this member is known
    // exactly: it now holds `emoji` (or no longer does). Prefer a summary that
    // can identify the viewer; otherwise advance what is tracked. Either way
    // the optimistic baseline never decides what gets deleted.
    final own =
        _ownFromSummary(
          summary,
          currentUserId: currentUserId,
          currentUserEmail: currentUserEmail,
        ) ??
        {...?_serverOwn[messageId]};
    if (isRemoval) {
      own.remove(emoji);
    } else {
      own.add(emoji);
    }
    _serverOwn[messageId] = own;

    // One reaction per member: everything else this member holds is stale.
    final stale = own.where((held) => held != emoji || isRemoval).toList();

    if (stale.isEmpty) {
      if (_isCurrent(messageId, seq)) {
        _applyReactions(
          messageId,
          summary,
          currentUserId: currentUserId,
          currentUserEmail: currentUserEmail,
        );
      }
      return null;
    }

    // One reaction per member: drop everything else this member holds. The
    // in-between summaries carry more than one emoji, so none of them is
    // applied — only the last.
    Failure? cleanupFailure;
    for (final extra in stale) {
      final dropped = await repository.removeReaction(
        roomIdForCall,
        messageId: messageId,
        emoji: extra,
      );
      if (!mounted) return null;
      dropped.fold(
        (failure) {
          // The member is left holding two on the server. `_serverOwn` keeps
          // `extra`, so a later burst still knows to drop it, and the summary
          // applied below shows both rather than hiding the duplicate — but
          // the caller has to hear about it instead of being told this
          // succeeded.
          cleanupFailure ??= failure;
        },
        (reactions) {
          summary = reactions;
          _serverOwn[messageId]?.remove(extra);
        },
      );
    }

    if (!_isCurrent(messageId, seq)) return cleanupFailure;
    _applyReactions(
      messageId,
      summary,
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );
    return cleanupFailure;
  }

  /// The emoji [summary] says this member holds, or null when it cannot say.
  ///
  /// `reacted_by_me` on the wire is not viewer-specific, so the answer comes
  /// from `users` / `user_ids`. Null — rather than an empty set — when the
  /// viewer is unidentifiable, so the caller falls back to what it has tracked
  /// instead of concluding the member holds nothing.
  Set<String>? _ownFromSummary(
    List<ChatMessageReactionDTO> summary, {
    String? currentUserId,
    String? currentUserEmail,
  }) {
    final hasId = (currentUserId ?? '').trim().isNotEmpty;
    final hasEmail = (currentUserEmail ?? '').trim().isNotEmpty;
    if (!hasId && !hasEmail) return null;

    // An empty summary is a definite answer: nobody holds anything.
    if (summary.isEmpty) return <String>{};

    final identifiable = summary.every(
      (reaction) => reaction.users.isNotEmpty || reaction.userIds.isNotEmpty,
    );
    if (!identifiable) return null;

    return chatReactionsForViewer(
          summary,
          currentUserId: currentUserId,
          currentUserEmail: currentUserEmail,
        )
        .where((reaction) => reaction.reactedByMe && reaction.count > 0)
        .map((reaction) => reaction.emoji)
        .toSet();
  }

  void _setReactions(String messageId, List<ChatMessageReactionDTO> reactions) {
    _bumpRevision(messageId);
    state = state.copyWith(
      messages:
          state.messages
              .map(
                (message) =>
                    message.id == messageId
                        ? message.copyWith(reactions: reactions)
                        : message,
              )
              .toList(),
    );
  }

  /// Marks a message deleted — from a `message_deleted` broadcast, or from
  /// our own confirmed call.
  ///
  /// Idempotent: the first timestamp stands, so the broadcast that follows our
  /// own delete does not churn the value already stamped.
  void applyDeletion(String messageId, {required String deletedAt}) {
    if (messageId.isEmpty) return;

    // A page already in flight was built before this deletion and would
    // commit the row as live — inserting it if it is not held yet, or
    // replacing the held copy if it is. Either way the marker has to outlive
    // that commit, so it is held until no fetch is running. With nothing in
    // flight it is safe to drop: any later fetch carries `deleted_at` itself.
    if (_fetchesInFlight > 0) _pendingDeletions[messageId] = deletedAt;

    final index = state.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index < 0) return;
    if (state.messages[index].deletedAt != null) return;

    state = state.copyWith(
      messages: [
        for (final message in state.messages)
          message.id == messageId
              ? message.copyWith(deletedAt: deletedAt)
              : message,
      ],
    );
  }

  /// Deletes one of this member's own messages, for everyone.
  ///
  /// The row is left alone until the server confirms. A destructive action
  /// already behind a confirm dialog should not need a rollback that brings
  /// back a message the user watched disappear.
  ///
  /// Returns the failure when the call fails, so the caller can say so.
  Future<Failure?> deleteMessage(String messageId) async {
    if (messageId.isEmpty) return null;

    final index = state.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index >= 0 && state.messages[index].deletedAt != null) return null;

    final result = await ref
        .read(groupChatRepositoryProvider)
        .deleteMessage(roomId, messageId: messageId);

    if (!mounted) return null;

    return result.fold((failure) => failure, (_) {
      // 204 with no body, so there is nothing to adopt: the row is stamped now
      // and the next fetch replaces this with the server's own value.
      applyDeletion(
        messageId,
        deletedAt: DateTime.now().toUtc().toIso8601String(),
      );
      return null;
    });
  }

  void retry() {
    if (state.messages.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }
}

final groupChatThreadProvider = StateNotifierProvider.autoDispose
    .family<GroupChatThreadNotifier, GroupChatThreadState, String>((
      ref,
      roomId,
    ) {
      return GroupChatThreadNotifier(ref: ref, roomId: roomId);
    });

/// Session-lived LRU of fetched previews. A stored null means "tried and
/// failed", so a dead link is not refetched.
class ChatLinkPreviewCache {
  ChatLinkPreviewCache({this.capacity = 100});

  final int capacity;
  final Map<String, ChatLinkPreview?> _entries = {};

  bool contains(String url) => _entries.containsKey(url);

  ChatLinkPreview? read(String url) {
    if (!_entries.containsKey(url)) return null;
    // Re-insert to mark most-recently-used.
    final value = _entries.remove(url);
    _entries[url] = value;
    return value;
  }

  void write(String url, ChatLinkPreview? preview) {
    _entries.remove(url);
    _entries[url] = preview;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }
}

final chatLinkPreviewServiceProvider = Provider<ChatLinkPreviewService>((ref) {
  return ChatLinkPreviewService();
});

final chatLinkPreviewCacheProvider = Provider<ChatLinkPreviewCache>((ref) {
  return ChatLinkPreviewCache();
});

/// Resolves the unfurl card for one URL. The bubble paints its text
/// immediately and the card fades in behind this.
final chatLinkPreviewProvider = FutureProvider.autoDispose
    .family<ChatLinkPreview?, String>((ref, url) async {
      final cache = ref.watch(chatLinkPreviewCacheProvider);
      if (cache.contains(url)) return cache.read(url);

      final preview = await ref
          .watch(chatLinkPreviewServiceProvider)
          .fetch(url);
      cache.write(url, preview);
      return preview;
    });
