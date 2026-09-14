import 'dart:async';

import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_room_cache.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/chat_rooms_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

ChatRoomDTO _group(int i, {int unreadCount = 0}) {
  return ChatRoomDTO(
    id: 'group-room-$i',
    createdBy: 'u9',
    groupId: 'group-$i',
    kind: 'group',
    name: 'Group $i',
    memberCount: 3,
    updatedAt: '2026-09-01T10:00:00Z',
    unreadCount: unreadCount,
  );
}

ChatRoomDTO _direct(int i) {
  return ChatRoomDTO(
    id: 'direct-room-$i',
    createdBy: 'u9',
    kind: 'direct',
    name: 'Direct $i',
    memberCount: 2,
    updatedAt: '2026-09-01T10:00:00Z',
  );
}

/// Serves a fixed rooms list, sliced by skip/limit like the API.
class _FakeGroupChatRepository implements GroupChatRepository {
  _FakeGroupChatRepository({required this.rooms});

  List<ChatRoomDTO> rooms;
  Failure? listFailure;

  /// Fails only the call with this 1-based index, then clears itself.
  int? failCall;
  int listCallCount = 0;

  /// Holds the next list call until completed, so a later one can overtake it.
  Completer<void>? holdNextList;

  /// Holds only the call with this 1-based index, for reaching a call that
  /// goes out on the heels of another.
  int? holdCall;
  Completer<void>? holdCallCompleter;

  /// The skips asked for, in order.
  final List<int> skips = [];

  @override
  Future<Either<Failure, ChatRoomsPage>> listRooms({
    int skip = 0,
    int limit = 20,
  }) async {
    listCallCount++;
    skips.add(skip);
    final hold = holdNextList;
    holdNextList = null;
    if (hold != null) await hold.future;
    if (holdCall == listCallCount) await holdCallCompleter!.future;
    if (failCall == listCallCount) {
      failCall = null;
      return const Left(NetworkFailure('offline'));
    }
    final failure = listFailure;
    if (failure != null) return Left(failure);
    final end = (skip + limit).clamp(0, rooms.length);
    final start = skip.clamp(0, rooms.length);
    return Right(
      ChatRoomsPage(
        rooms: rooms.sublist(start, end),
        skip: skip,
        limit: limit,
        total: rooms.length,
      ),
    );
  }

  @override
  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId) async =>
      const Left(NotFoundFailure('not used'));

  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
  }) async =>
      const Right(ChatMessagesPage(messages: [], skip: 0, limit: 0, total: 0));

  @override
  Future<Either<Failure, ChatMessageDTO>> sendGroupMessage(
    String groupId, {
    required String body,
    String? parentMessageId,
  }) async => const Left(NotFoundFailure('not used'));

  @override
  Future<Either<Failure, ChatRoomMembersPage>> listRoomMembers(
    String roomId, {
    int skip = 0,
    int limit = 100,
  }) async => const Right(
    ChatRoomMembersPage(members: [], skip: 0, limit: 0, total: 0),
  );

  @override
  Future<Either<Failure, Unit>> markRoomRead(String roomId) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> reportMessage(
    String roomId, {
    required String messageId,
    required String reason,
    String? description,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> deleteMessage(
    String roomId, {
    required String messageId,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, List<ChatMessageReactionDTO>>> addReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async => const Right([]);

  @override
  Future<Either<Failure, List<ChatMessageReactionDTO>>> removeReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async => const Right([]);
}

/// Stands in for the preferences the room cache and the account id live in.
class _MemoryStorage implements StorageService {
  final Map<String, Object> values = {};

  Iterable<String> get roomCacheKeys =>
      values.keys.where((key) => key.startsWith('group_chat.room.'));

  @override
  Future<T?> get<T>(String key) async => values[key] as T?;

  @override
  Future<bool> set<T>(String key, T value) async {
    values[key] = value as Object;
    return true;
  }

  @override
  Future<bool> delete(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);
}

/// autoDispose tears the provider down the moment nothing listens, so tests
/// hold a subscription open for the life of the container.
ChatRoomsNotifier _keepAlive(ProviderContainer container) {
  container.listen(chatRoomsProvider, (_, _) {});
  return container.read(chatRoomsProvider.notifier);
}

/// Lets the constructor's `loadInitial` (and any pending fetch) settle.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<String> _ids(ChatRoomsNotifier notifier) =>
    notifier.state.rooms.map((room) => room.id).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeGroupChatRepository repository;
  late _MemoryStorage storage;
  late ProviderContainer container;

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        groupChatRepositoryProvider.overrideWithValue(repository),
        storageServiceProvider.overrideWithValue(storage),
      ],
    );
  }

  setUp(() => storage = _MemoryStorage());
  tearDown(() => container.dispose());

  group('loadInitial', () {
    test(
      'walks past a first page of direct messages to the group rooms',
      () async {
        repository = _FakeGroupChatRepository(
          rooms: [
            for (var i = 0; i < 20; i++) _direct(i),
            _group(1),
            _group(2),
          ],
        );
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();

        expect(_ids(notifier), ['group-room-1', 'group-room-2']);
        expect(notifier.state.hasLoaded, isTrue);
        expect(notifier.state.hasMore, isFalse);
        expect(notifier.state.skip, 22);
        expect(repository.listCallCount, 2);
      },
    );

    test('does not mark the list loaded until the walk is over', () async {
      repository = _FakeGroupChatRepository(
        rooms: [for (var i = 0; i < 20; i++) _direct(i), _group(1)],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);

      final seen = <ChatRoomsState>[];
      container.listen(chatRoomsProvider, (_, next) => seen.add(next));
      await _settle();

      // No intermediate state was both loaded and empty — that would have
      // flashed the empty state while the group rooms were still on the way.
      expect(
        seen.where((s) => s.hasLoaded && s.rooms.isEmpty && s.error == null),
        isEmpty,
      );
      expect(notifier.state.rooms, hasLength(1));
    });

    test('stops once a page of group rooms is held', () async {
      repository = _FakeGroupChatRepository(
        rooms: [for (var i = 0; i < 60; i++) _group(i)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.rooms, hasLength(20));
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.skip, 20);
      // One page for the list; the other two are the unread scan seeing the
      // rest out, without touching what the list holds.
      expect(repository.listCallCount, 3);
      expect(repository.skips, [0, 20, 40]);
    });

    test('caps the list walk once it has something to show, so a DM-heavy '
        'account is on screen after five pages', () async {
      repository = _FakeGroupChatRepository(
        rooms: [_group(1), for (var i = 0; i < 200; i++) _direct(i)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.rooms, hasLength(1));
      expect(notifier.state.hasLoaded, isTrue);
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.skip, 100);
      // The cap bounds the list, not the dot: the scan walks the remaining
      // 101 rooms behind it looking for something unread.
      expect(repository.listCallCount, 11);
      expect(notifier.state.hasUnread, isFalse);
    });

    test(
      'keeps walking past the cap while it has found nothing, so group rooms '
      'behind many pages of DMs are not hidden behind an empty screen',
      () async {
        repository = _FakeGroupChatRepository(
          rooms: [for (var i = 0; i < 130; i++) _direct(i), _group(1)],
        );
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();

        expect(repository.listCallCount, 7);
        expect(notifier.state.rooms.map((r) => r.id), ['group-room-1']);
        expect(notifier.state.hasLoaded, isTrue);
        expect(notifier.state.hasMore, isFalse);
        expect(notifier.state.skip, 131);
      },
    );

    test('an account with only direct messages ends with the server exhausted, '
        'never an empty list that still claims more', () async {
      repository = _FakeGroupChatRepository(
        rooms: [for (var i = 0; i < 200; i++) _direct(i)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(repository.listCallCount, 10);
      expect(notifier.state.rooms, isEmpty);
      expect(notifier.state.hasLoaded, isTrue);
      expect(notifier.state.hasMore, isFalse);
      expect(notifier.state.skip, 200);
    });

    test(
      'a page failing mid-walk keeps what landed and surfaces the error',
      () async {
        repository = _FakeGroupChatRepository(
          rooms: [
            _group(1),
            for (var i = 0; i < 19; i++) _direct(i),
            _group(2),
          ],
        )..failCall = 2;
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();

        expect(_ids(notifier), ['group-room-1']);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.hasLoaded, isTrue);
        // Paging resumes from the failed page rather than the top.
        expect(notifier.state.skip, 20);
        expect(notifier.state.hasMore, isTrue);

        await notifier.loadMore();
        expect(_ids(notifier), ['group-room-1', 'group-room-2']);
        expect(notifier.state.error, isNull);
      },
    );
    test(
      'a room going active mid-walk does not put the row it displaced in twice',
      () async {
        repository = _FakeGroupChatRepository(
          rooms: [
            for (var i = 0; i < 5; i++) _direct(i),
            for (var i = 0; i < 25; i++) _group(i),
          ],
        );
        // The first page holds 15 group rooms, short of a page, so the walk
        // asks for a second. Hold that one.
        repository.holdCall = 2;
        final hold = repository.holdCallCompleter = Completer<void>();
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();
        expect(repository.listCallCount, 2);

        // A message lands in a room the walk has not reached. The server moves
        // it to the top and every row behind it shifts down one, so the page
        // in flight now starts with the last row of the page before.
        repository.rooms.insert(0, _group(99));
        hold.complete();
        await _settle();

        final ids = _ids(notifier);
        expect(ids.toSet(), hasLength(ids.length));
        expect(ids.where((id) => id == 'group-room-14'), hasLength(1));
        expect(notifier.state.hasMore, isFalse);
      },
    );
  });

  group('loadMore', () {
    test('appends the next page of group rooms without duplicates', () async {
      repository = _FakeGroupChatRepository(
        rooms: [for (var i = 0; i < 30; i++) _group(i)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.loadMore();

      expect(notifier.state.rooms, hasLength(30));
      expect(_ids(notifier).toSet(), hasLength(30));
      expect(notifier.state.hasMore, isFalse);
      expect(notifier.state.skip, 30);
    });

    test(
      'walks past a page of direct messages to reach more group rooms',
      () async {
        repository = _FakeGroupChatRepository(
          rooms: [
            for (var i = 0; i < 20; i++) _group(i),
            for (var i = 0; i < 20; i++) _direct(i),
            _group(99),
          ],
        );
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();
        // The list took one page; the unread scan took the other two.
        expect(repository.listCallCount, 3);

        await notifier.loadMore();

        expect(notifier.state.rooms, hasLength(21));
        expect(_ids(notifier), contains('group-room-99'));
        expect(notifier.state.hasMore, isFalse);
        expect(repository.listCallCount, 5);
      },
    );
  });

  group('unread beyond the list', () {
    test('the dot sees an unread room the list stopped short of', () async {
      repository = _FakeGroupChatRepository(
        rooms: [
          for (var i = 0; i < 30; i++) _group(i, unreadCount: i == 27 ? 1 : 0),
        ],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.rooms, hasLength(20));
      expect(notifier.state.rooms.any((r) => r.unreadCount > 0), isFalse);
      expect(notifier.state.hasUnreadBeyondList, isTrue);
      expect(notifier.state.hasUnread, isTrue);
    });

    test('the dot sees an unread room behind a DM-heavy cap', () async {
      repository = _FakeGroupChatRepository(
        rooms: [
          _group(1),
          for (var i = 0; i < 150; i++) _direct(i),
          _group(2, unreadCount: 4),
        ],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(_ids(notifier), ['group-room-1']);
      expect(notifier.state.hasUnread, isTrue);
    });

    test('the scan stops at the first unread room it finds', () async {
      repository = _FakeGroupChatRepository(
        rooms: [
          for (var i = 0; i < 20; i++) _group(i),
          _group(20, unreadCount: 1),
          for (var i = 21; i < 100; i++) _group(i),
        ],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.hasUnread, isTrue);
      expect(repository.listCallCount, 2);
    });

    test('a list that already has something unread is not scanned', () async {
      repository = _FakeGroupChatRepository(
        rooms: [
          _group(0, unreadCount: 1),
          for (var i = 1; i < 60; i++) _group(i),
        ],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.hasUnread, isTrue);
      expect(notifier.state.hasUnreadBeyondList, isFalse);
      expect(repository.listCallCount, 1);
    });

    test(
      'paging the list past the room hands the answer back to the list',
      () async {
        repository = _FakeGroupChatRepository(
          rooms: [
            for (var i = 0; i < 30; i++)
              _group(i, unreadCount: i == 27 ? 1 : 0),
          ],
        );
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();
        expect(notifier.state.hasUnreadBeyondList, isTrue);

        await notifier.loadMore();

        expect(notifier.state.rooms, hasLength(30));
        expect(notifier.state.hasUnreadBeyondList, isFalse);
        // Still on, now because the room itself is in the list.
        expect(notifier.state.hasUnread, isTrue);
        // And nothing left to scan for: the list can answer.
        await _settle();
        expect(repository.listCallCount, 3);
      },
    );

    test(
      'paging past a room that was read in the meantime carries the scan on, '
      'so an unread room further back still reaches the dot',
      () async {
        List<ChatRoomDTO> rooms({required bool read27}) => [
          for (var i = 0; i < 60; i++)
            _group(i, unreadCount: (i == 27 && !read27) || i == 55 ? 1 : 0),
        ];
        repository = _FakeGroupChatRepository(rooms: rooms(read27: false));
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();
        // The list took page one; the scan stopped on page two at room 27.
        expect(repository.listCallCount, 2);
        expect(notifier.state.hasUnreadBeyondList, isTrue);

        // Room 27 is read before the list pages on to it.
        repository.rooms = rooms(read27: true);
        await notifier.loadMore();
        await _settle();

        expect(notifier.state.rooms, hasLength(40));
        expect(notifier.state.rooms.any((r) => r.unreadCount > 0), isFalse);
        // The scan picked up where the list stopped and found room 55.
        expect(repository.skips, [0, 20, 20, 40]);
        expect(notifier.state.hasUnreadBeyondList, isTrue);
        expect(notifier.state.hasUnread, isTrue);
      },
    );

    test('a refresh after the room is read turns the dot off', () async {
      repository = _FakeGroupChatRepository(
        rooms: [
          for (var i = 0; i < 30; i++) _group(i, unreadCount: i == 27 ? 1 : 0),
        ],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      expect(notifier.state.hasUnread, isTrue);

      repository.rooms = [for (var i = 0; i < 30; i++) _group(i)];
      await notifier.refresh();
      await _settle();

      expect(notifier.state.hasUnreadBeyondList, isFalse);
      expect(notifier.state.hasUnread, isFalse);
    });

    test('a scan that a refresh overtook does not turn the dot on', () async {
      repository = _FakeGroupChatRepository(
        rooms: [
          for (var i = 0; i < 30; i++) _group(i, unreadCount: i == 27 ? 1 : 0),
        ],
      );
      // Call 1 is the list's page; call 2 is the scan's, held here.
      final hold = Completer<void>();
      repository
        ..holdCall = 2
        ..holdCallCompleter = hold;
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      expect(repository.listCallCount, 2);
      expect(notifier.state.hasUnread, isFalse);

      // Everything is read by the time the refresh goes out.
      repository.rooms = [for (var i = 0; i < 30; i++) _group(i)];
      await notifier.refresh();
      await _settle();
      expect(notifier.state.hasUnread, isFalse);

      // The held scan lands with its stale page of unread rooms.
      hold.complete();
      await _settle();

      expect(notifier.state.hasUnreadBeyondList, isFalse);
      expect(notifier.state.hasUnread, isFalse);
    });

    test('a scan that a loadMore overtook defers to the list for the rooms '
        'the list now holds', () async {
      List<ChatRoomDTO> rooms({required bool read27}) => [
        for (var i = 0; i < 30; i++)
          _group(i, unreadCount: i == 27 && !read27 ? 1 : 0),
      ];
      repository = _FakeGroupChatRepository(rooms: rooms(read27: false));
      // Call 1 is the list's page; call 2 is the scan's, held here.
      final hold = Completer<void>();
      repository
        ..holdCall = 2
        ..holdCallCompleter = hold;
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      expect(repository.listCallCount, 2);
      expect(notifier.state.hasUnread, isFalse);

      // The list pages on past the scan's page and sees room 27 read.
      repository.rooms = rooms(read27: true);
      await notifier.loadMore();
      expect(notifier.state.rooms, hasLength(30));
      expect(notifier.state.hasMore, isFalse);
      expect(notifier.state.hasUnread, isFalse);

      // The held scan lands with an older copy of that page, room 27 still
      // unread on it. The list holds room 27 now, so the list decides.
      repository.rooms = rooms(read27: false);
      hold.complete();
      await _settle();

      expect(notifier.state.hasUnreadBeyondList, isFalse);
      expect(notifier.state.hasUnread, isFalse);
      expect(repository.skips, [0, 20, 20]);
    });

    test(
      'a scan that a loadMore overtook carries on from the list\'s new end',
      () async {
        List<ChatRoomDTO> rooms({required bool read27}) => [
          for (var i = 0; i < 60; i++)
            _group(i, unreadCount: (i == 27 && !read27) || i == 55 ? 1 : 0),
        ];
        repository = _FakeGroupChatRepository(rooms: rooms(read27: false));
        // Call 1 is the list's page; call 2 is the scan's, held here.
        final hold = Completer<void>();
        repository
          ..holdCall = 2
          ..holdCallCompleter = hold;
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();
        expect(repository.listCallCount, 2);

        // The list pages on past the scan's page and sees room 27 read.
        repository.rooms = rooms(read27: true);
        await notifier.loadMore();
        expect(notifier.state.rooms, hasLength(40));
        expect(notifier.state.skip, 40);
        expect(notifier.state.hasUnread, isFalse);

        // The held scan lands with an older copy of that page, room 27 still
        // unread on it. Rather than stop there — the list holds room 27 and
        // shows it read — it skips to 40, where it finds room 55.
        repository.rooms = rooms(read27: false);
        hold.complete();
        await _settle();

        expect(repository.skips, [0, 20, 20, 40]);
        expect(notifier.state.hasUnreadBeyondList, isTrue);
        expect(notifier.state.hasUnread, isTrue);

        // Paging on past room 55 hands it to the list, and the dot stays on
        // because the list now holds it unread.
        repository.rooms = rooms(read27: true);
        await notifier.loadMore();
        expect(notifier.state.rooms, hasLength(60));
        expect(notifier.state.hasUnread, isTrue);
      },
    );

    test('a page failing mid-scan leaves the dot off, not stuck', () async {
      repository = _FakeGroupChatRepository(
        rooms: [
          for (var i = 0; i < 30; i++) _group(i, unreadCount: i == 27 ? 1 : 0),
        ],
      )..failCall = 2;
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.rooms, hasLength(20));
      expect(notifier.state.error, isNull);
      expect(notifier.state.hasUnread, isFalse);

      await notifier.refresh();
      await _settle();
      expect(notifier.state.hasUnread, isTrue);
    });
  });

  group('refresh', () {
    test('a page that a refresh overtook is dropped, not merged', () async {
      repository = _FakeGroupChatRepository(
        rooms: [for (var i = 0; i < 40; i++) _group(i)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      expect(notifier.state.rooms, hasLength(20));

      // The second page is held while a refresh goes out and lands first.
      final hold = repository.holdNextList = Completer<void>();
      final loadingMore = notifier.loadMore();
      await _settle();
      expect(notifier.state.isLoadingMore, isTrue);

      await notifier.refresh();
      expect(notifier.state.rooms, hasLength(20));
      expect(notifier.state.skip, 20);

      hold.complete();
      await loadingMore;

      // The stale page belongs to the list the refresh replaced.
      expect(notifier.state.rooms, hasLength(20));
      expect(notifier.state.skip, 20);
      expect(notifier.state.isLoadingMore, isFalse);

      // Paging on from the fresh list still works.
      await notifier.loadMore();
      expect(notifier.state.rooms, hasLength(40));
      expect(_ids(notifier).toSet(), hasLength(40));
    });

    test(
      'an overtaken page landing late leaves a fresh page in flight alone',
      () async {
        repository = _FakeGroupChatRepository(
          rooms: [for (var i = 0; i < 40; i++) _group(i)],
        );
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();

        final holdStale = repository.holdNextList = Completer<void>();
        final stale = notifier.loadMore();
        await _settle();
        expect(notifier.state.isLoadingMore, isTrue);

        // The refresh orphans that page and clears its flag straight away,
        // rather than showing a "loading more" footer for a page it will drop.
        await notifier.refresh();
        await _settle();
        expect(notifier.state.isLoadingMore, isFalse);

        // A fresh page goes out against the new list.
        final holdFresh = repository.holdNextList = Completer<void>();
        final fresh = notifier.loadMore();
        await _settle();
        expect(notifier.state.isLoadingMore, isTrue);

        // The stale page lands under it and must not clear its flag, or a
        // third page could go out for the same offset.
        holdStale.complete();
        await stale;
        expect(notifier.state.isLoadingMore, isTrue);
        expect(notifier.state.rooms, hasLength(20));

        holdFresh.complete();
        await fresh;
        expect(notifier.state.isLoadingMore, isFalse);
        expect(notifier.state.rooms, hasLength(40));
        expect(_ids(notifier).toSet(), hasLength(40));
      },
    );

    test('a failed refresh keeps the list and its paging', () async {
      repository = _FakeGroupChatRepository(
        rooms: [for (var i = 0; i < 40; i++) _group(i)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      repository.listFailure = const NetworkFailure('offline');
      await notifier.refresh();

      expect(notifier.state.rooms, hasLength(20));
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.skip, 20);
      expect(notifier.state.hasMore, isTrue);

      repository.listFailure = null;
      await notifier.loadMore();
      expect(notifier.state.rooms, hasLength(40));
      expect(_ids(notifier).toSet(), hasLength(40));
      expect(notifier.state.error, isNull);
    });

    test('a refresh that shrinks the list replaces it', () async {
      repository = _FakeGroupChatRepository(rooms: [_group(1), _group(2)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      expect(notifier.state.rooms, hasLength(2));

      repository.rooms = [_group(2)];
      await notifier.refresh();

      expect(_ids(notifier), ['group-room-2']);
      expect(notifier.state.skip, 1);
      expect(notifier.state.total, 1);
    });
  });

  test('hasUnread follows the unread counts', () async {
    repository = _FakeGroupChatRepository(
      rooms: [_group(1), _group(2, unreadCount: 3)],
    );
    container = buildContainer();

    final notifier = _keepAlive(container);
    await _settle();
    expect(notifier.state.hasUnread, isTrue);

    repository.rooms = [_group(1), _group(2)];
    await notifier.refresh();
    expect(notifier.state.hasUnread, isFalse);
  });

  group('room cache seed', () {
    test(
      'keys the cache by the stored account id, as the chat screen reads it',
      () async {
        repository = _FakeGroupChatRepository(rooms: [_group(1), _direct(1)]);
        storage.values[StorageKeys.currentUserId] = 'auth0|abc';
        container = buildContainer();

        _keepAlive(container);
        await _settle();

        expect(
          storage.values[GroupChatRoomCache.key(
            userId: 'auth0|abc',
            groupId: 'group-1',
          )],
          'group-room-1',
        );
        // A direct room has no group to key by.
        expect(storage.roomCacheKeys, hasLength(1));
      },
    );

    test('writes nothing until the account id has been stored', () async {
      repository = _FakeGroupChatRepository(rooms: [_group(1)]);
      container = buildContainer();

      _keepAlive(container);
      await _settle();

      expect(storage.roomCacheKeys, isEmpty);
    });
  });
}
