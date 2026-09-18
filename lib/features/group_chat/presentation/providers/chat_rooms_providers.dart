import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_rooms_list.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/providers/push_notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' show Left, Right;

class ChatRoomsState extends Equatable {
  /// Group rooms only, most recently active first.
  final List<ChatRoomDTO> rooms;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;
  final int total;

  /// Whether the first fetch has settled, so the empty state never flashes
  /// before the initial request lands.
  final bool hasLoaded;

  /// Whether an unread group room sits past the end of [rooms].
  ///
  /// The list stops walking the server once it has a page to show, but the
  /// dot has to answer for every room. Set by a scan that carries on from
  /// where the list stopped, purely to look for unread counts.
  final bool hasUnreadBeyondList;

  const ChatRoomsState({
    this.rooms = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.total = 0,
    this.hasLoaded = false,
    this.hasUnreadBeyondList = false,
  });

  /// Drives the dot on the Connect app bar.
  bool get hasUnread => rooms.any(chatRoomIsUnread) || hasUnreadBeyondList;

  ChatRoomsState copyWith({
    List<ChatRoomDTO>? rooms,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    int? total,
    bool? hasLoaded,
    bool? hasUnreadBeyondList,
    bool clearError = false,
  }) {
    return ChatRoomsState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      total: total ?? this.total,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      hasUnreadBeyondList: hasUnreadBeyondList ?? this.hasUnreadBeyondList,
    );
  }

  @override
  List<Object?> get props => [
    rooms,
    isLoading,
    isLoadingMore,
    error,
    hasMore,
    skip,
    total,
    hasLoaded,
    hasUnreadBeyondList,
  ];
}

/// What one walk down `/chat/rooms` brought back.
class _RoomsWalk {
  const _RoomsWalk({
    required this.rooms,
    required this.skip,
    required this.total,
    required this.hasMore,
    this.failure,
  });

  /// Every room fetched, direct messages included, in server order.
  final List<ChatRoomDTO> rooms;

  /// Where the next walk should start.
  final int skip;
  final int total;
  final bool hasMore;

  /// Set when a page failed. Earlier pages of the same walk are still in
  /// [rooms]; a walk whose first page failed has none.
  final Failure? failure;
}

/// The viewer's group chats.
///
/// Read by both the Connect app-bar dot and the Chats screen, so the dot's
/// fetch doubles as the screen's prefetch — there is no unread endpoint, and
/// loading this twice for one answer would be the only alternative.
class ChatRoomsNotifier extends StateNotifier<ChatRoomsState>
    with WidgetsBindingObserver {
  ChatRoomsNotifier({required this.ref}) : super(const ChatRoomsState()) {
    WidgetsBinding.instance.addObserver(this);
    loadInitial();
  }

  final Ref ref;
  static const int _limit = 20;

  /// How many server pages one load will walk once it has a group room to
  /// show.
  ///
  /// `/chat/rooms` has no kind filter and mixes direct messages in, so a page
  /// can be all DMs and contribute nothing to this list. The cap keeps a
  /// DM-heavy account from turning every load into a crawl of the whole
  /// endpoint — but it only applies once the walk has found something. A walk
  /// that has found nothing keeps going until the server runs out: with no
  /// list on screen there is nothing to scroll, so a load that stopped short
  /// and empty would never be followed by another, and the viewer's group
  /// chats would sit hidden behind the offset for good.
  ///
  /// The cap bounds what the list waits for, not what the dot sees: once the
  /// list is published, [_scanForUnread] carries on past it in the background.
  static const int _maxPagesPerLoad = 5;

  /// Server offset of the page where the unread scan found its room, so
  /// `loadMore` can tell when the list has caught up with it.
  int? _unreadBeyondOffset;

  /// Bumped by every load from the top.
  ///
  /// A `loadMore` that went out before the bump was paging a list that no
  /// longer exists. Merging its page into the fresh list would put its rooms
  /// in twice over and leave `skip` counting rows the new list never held, so
  /// its result is dropped instead.
  int _generation = 0;

  /// Unread counts and last messages both change on the server without the app
  /// hearing about it — the live socket is per-room, and there is no rooms
  /// stream. So this list is refetched on every occasion it could be stale
  /// rather than loaded once: coming back to the foreground, a chat push
  /// landing while the app is open, and whenever the Chats screen is shown.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    _generation++;
    // `hasLoaded` waits for the whole walk, not the first page: with a first
    // page of DMs the list is still empty when it lands, and marking it loaded
    // there would flash the empty state before the group rooms arrive.
    //
    // `isLoadingMore` is cleared here rather than when the orphaned page
    // lands: the bump above has already made that page a no-op, and `isLoading`
    // holds off any new `loadMore` until this walk is published. Leaving the
    // flag to the orphan would let it land after a fresh page had gone out and
    // clear that page's flag from under it.
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );

    final walk = await _walk(skip: 0);
    if (!mounted) return;

    final failure = walk.failure;
    if (failure != null && walk.rooms.isEmpty) {
      // Nothing new landed; whatever was on screen stays, and so does the
      // paging that goes with it.
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        error: failure.message,
      );
      return;
    }

    // A fresh list starts with no verdict about what lies beyond it; the scan
    // below earns that again from scratch, since the room it found last time
    // may have been read since.
    _unreadBeyondOffset = null;
    state = state.copyWith(
      rooms: groupChatRooms(walk.rooms),
      isLoading: false,
      hasLoaded: true,
      hasMore: walk.hasMore,
      skip: walk.skip,
      total: walk.total,
      hasUnreadBeyondList: false,
      error: failure?.message,
      clearError: failure == null,
    );
    unawaited(_seedRoomCache(walk.rooms));

    // Only when the list cannot already answer: a dot that is on stays on.
    // Not after a failed page either — the scan would start on the page that
    // just failed, and the retry belongs to the viewer.
    if (failure == null && walk.hasMore && !state.hasUnread) {
      unawaited(_scanForUnread(skip: walk.skip, generation: _generation));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;
    final generation = _generation;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final walk = await _walk(skip: state.skip);
    if (!mounted) return;
    if (generation != _generation) {
      // A load from the top overtook this page. The list it was extending is
      // gone, so there is nothing to append it to — and nothing to reset
      // either: `loadInitial` already cleared `isLoadingMore`, and a page of
      // the new list may be in flight under that flag by now.
      return;
    }

    final failure = walk.failure;
    if (failure != null && walk.rooms.isEmpty) {
      state = state.copyWith(isLoadingMore: false, error: failure.message);
      return;
    }

    // Re-sorted across the whole list rather than appended: a later page can
    // hold a room more recent than one already shown, since the server's own
    // ordering is undocumented.
    final known = state.rooms.map((room) => room.id).toSet();
    final merged = [
      ...state.rooms,
      ...walk.rooms.where((room) => !known.contains(room.id)),
    ];

    // Once the list has paged past the room the scan found, the list speaks
    // for it: the room is either in `rooms` still unread, or was read in the
    // meantime — and a flag that outlived that would keep the dot on.
    final beyond = _unreadBeyondOffset;
    final caughtUp = beyond != null && walk.skip > beyond;
    if (caughtUp) _unreadBeyondOffset = null;

    state = state.copyWith(
      rooms: groupChatRooms(merged),
      isLoadingMore: false,
      hasMore: walk.hasMore,
      skip: walk.skip,
      total: walk.total,
      hasUnreadBeyondList: caughtUp ? false : null,
      error: failure?.message,
      clearError: failure == null,
    );
    unawaited(_seedRoomCache(walk.rooms));

    // The scan stopped at the room it found, so nothing past it has been
    // looked at. If the list now covers that room and still has nothing unread
    // — the room was read in the meantime — the rest of the server is once
    // more the only place an unread room could be. Same terms as the first
    // scan: not after a failed page, and not while the list can answer.
    if (caughtUp && failure == null && walk.hasMore && !state.hasUnread) {
      unawaited(_scanForUnread(skip: walk.skip, generation: _generation));
    }
  }

  /// Reloads from the top, keeping what is on screen until the walk lands so
  /// the list does not blink back to a spinner on every refresh. Paging is
  /// only replaced once the new list is, so a refresh that fails leaves the
  /// old list able to page on from where it was.
  Future<void> refresh() => loadInitial();

  void retry() {
    if (state.rooms.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }

  /// Pages forward from [skip] until a page's worth of group rooms has been
  /// collected, the server runs out, a page fails, or [_maxPagesPerLoad] is
  /// reached with at least one group room in hand — whichever comes first.
  ///
  /// Never returns empty-handed while the server still has rooms: an empty
  /// result with `hasMore` set is a dead end for the caller, since nothing on
  /// screen would ever ask for the next page.
  Future<_RoomsWalk> _walk({required int skip}) async {
    final repository = ref.read(groupChatRepositoryProvider);
    final rooms = <ChatRoomDTO>[];
    final seen = <String>{};
    var total = 0;
    var hasMore = true;

    for (var page = 0; hasMore; page++) {
      final found = groupChatRooms(rooms).length;
      if (found >= _limit) break;
      if (page >= _maxPagesPerLoad && found > 0) break;

      final result = await repository.listRooms(skip: skip, limit: _limit);
      if (!mounted) break;

      final ChatRoomsPage loaded;
      switch (result) {
        case Left(value: final failure):
          return _RoomsWalk(
            rooms: rooms,
            skip: skip,
            total: total,
            hasMore: hasMore,
            failure: failure,
          );
        case Right(value: final page):
          loaded = page;
      }

      // Pages are offsets into a list the server re-orders on every message,
      // so a room going active mid-walk shifts every row down one and the
      // next page repeats the last room of the page before. Kept once, or the
      // list would show the same room twice. (The room that moved to the top
      // is missed by this walk instead; the next refresh picks it up.)
      rooms.addAll(
        loaded.rooms.where((room) => room.id.isEmpty || seen.add(room.id)),
      );
      // Against the raw page, not the kept rows: the offset is the server's.
      skip += loaded.rooms.length;
      total = loaded.total;
      // Against the raw page, not the filtered list: direct rooms count
      // towards the server's total, so a page that is all DMs still means
      // there is more to walk.
      hasMore = loaded.rooms.isNotEmpty && skip < total;
    }

    return _RoomsWalk(rooms: rooms, skip: skip, total: total, hasMore: hasMore);
  }

  /// Pages on from [skip] — where the list's walk stopped — looking only for
  /// an unread group room, and stops at the first one.
  ///
  /// There is no unread endpoint and `/chat/rooms` has no sort or filter, so
  /// the only way to be sure nothing is unread is to see every room. That is
  /// the cost of an honest dot, paid in the background after the list is
  /// already on screen, and only when the list itself holds nothing unread.
  /// Nothing here touches `rooms` or `skip`: those belong to the list's own
  /// paging, and a page fetched for the dot is fetched again when the viewer
  /// scrolls to it.
  ///
  /// A failed page ends the scan quietly; the next refresh starts it over. A
  /// load from the top that overtakes it ends it too — its verdict would be
  /// about a list that no longer exists.
  ///
  /// A `loadMore` that overtakes it is different: the list is the same one,
  /// just longer. The scan then skips ahead to where the list now ends. The
  /// rooms it was about to judge are on screen, so the list speaks for them;
  /// a verdict from a page the list has since re-fetched could turn the dot
  /// on for a room the list shows as read, and `loadMore` only clears that
  /// flag on the *next* page — which a list at its end never asks for.
  Future<void> _scanForUnread({
    required int skip,
    required int generation,
  }) async {
    final repository = ref.read(groupChatRepositoryProvider);
    var hasMore = true;

    while (hasMore) {
      final result = await repository.listRooms(skip: skip, limit: _limit);
      if (!mounted || generation != _generation) return;

      final ChatRoomsPage page;
      switch (result) {
        case Left():
          return;
        case Right(value: final loaded):
          page = loaded;
      }

      unawaited(_seedRoomCache(page.rooms));
      if (state.skip > skip) {
        // The list paged past this page while it was in flight. If the list
        // can answer now the scan has nothing to add; otherwise carry on from
        // the list's new end, which nothing has looked past yet.
        if (state.hasUnread) return;
        skip = state.skip;
        hasMore = state.hasMore;
        continue;
      }
      if (hasUnreadChatRooms(page.rooms)) {
        _unreadBeyondOffset = skip;
        state = state.copyWith(hasUnreadBeyondList: true);
        return;
      }

      skip += page.rooms.length;
      hasMore = page.rooms.isNotEmpty && skip < page.total;
    }
  }

  /// Records room ids against their groups.
  ///
  /// The chat route is keyed by group, so opening a chat runs
  /// `ResolveGroupChatRoom`, which pages this same endpoint looking for the id
  /// this list already has. Writing it here turns that lookup into a cache hit
  /// and the thread opens without a request.
  ///
  /// Best effort throughout: a failed write only costs the lookup it would
  /// have saved, so nothing here is awaited by the list or allowed to throw.
  Future<void> _seedRoomCache(List<ChatRoomDTO> rooms) async {
    final groupRooms =
        rooms
            .where(
              (room) => (room.groupId ?? '').isNotEmpty && room.id.isNotEmpty,
            )
            .toList();
    if (groupRooms.isEmpty) return;

    final userId = await _loadAccountId();
    if (!mounted || userId.isEmpty) return;

    final cache = ref.read(groupChatRoomCacheProvider);
    for (final room in groupRooms) {
      try {
        await cache.write(
          userId: userId,
          groupId: room.groupId!,
          roomId: room.id,
        );
      } catch (_) {
        // Storage is best-effort; the next lookup falls back to the server.
      }
    }
  }

  /// The id the room cache is keyed by, read once.
  ///
  /// This is the account id the chat screen resolves with — the token's `sub`
  /// — and not the profile id on `userProvider`. That one is the backend's own
  /// uuid, a different id space: a key written under it is never read back.
  ///
  /// An empty read is not kept, so a list loaded before sign-in has finished
  /// storing the id tries again on the next page.
  String? _accountId;

  Future<String> _loadAccountId() async {
    final known = _accountId;
    if (known != null) return known;
    try {
      final stored = await ref
          .read(storageServiceProvider)
          .get<String>(StorageKeys.currentUserId);
      final id = stored?.trim() ?? '';
      if (id.isNotEmpty) _accountId = id;
      return id;
    } catch (_) {
      return '';
    }
  }
}

final chatRoomsProvider =
    StateNotifierProvider.autoDispose<ChatRoomsNotifier, ChatRoomsState>((ref) {
      return ChatRoomsNotifier(ref: ref);
    });

/// Refreshes the rooms list when a chat push arrives while the app is open.
///
/// Watched by whatever shows the unread dot, so the dot answers a notification
/// the user is looking at rather than waiting for the next fetch. Deliberately
/// not filtered to any one room: a push for a chat the user is currently
/// reading still changes another room's counts.
final chatRoomsPushRefreshProvider = Provider.autoDispose<void>((ref) {
  final subscription = ref
      .watch(pushMessagingRepositoryProvider)
      .onForegroundMessage
      .listen((message) {
        if (!isChatPushPayload(message.data)) return;
        ref.read(chatRoomsProvider.notifier).refresh();
      });

  ref.onDispose(subscription.cancel);
});
