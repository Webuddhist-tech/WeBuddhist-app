import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_room_cache.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/domain/usecases/resolve_group_chat_room.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _MemoryStorage implements StorageService {
  final Map<String, Object> values = {};

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

ChatRoomDTO _room(String id, {String? groupId}) {
  return ChatRoomDTO(
    id: id,
    createdBy: 'u1',
    groupId: groupId,
    kind: 'group',
    name: 'room $id',
    updatedAt: '2026-08-28T12:00:00Z',
  );
}

/// Serves `getRoom` from [rooms] and pages `listRooms` over [allRooms] like
/// the API does.
class _FakeGroupChatRepository implements GroupChatRepository {
  final Map<String, ChatRoomDTO> rooms = {};
  List<ChatRoomDTO> allRooms = [];
  Failure? getRoomFailure;
  Failure? listRoomsFailure;
  int listRoomsCallCount = 0;

  @override
  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId) async {
    final failure = getRoomFailure;
    if (failure != null) return Left(failure);
    final room = rooms[roomId];
    if (room == null) return const Left(NotFoundFailure('missing'));
    return Right(room);
  }

  @override
  Future<Either<Failure, ChatRoomsPage>> listRooms({
    int skip = 0,
    int limit = 20,
  }) async {
    listRoomsCallCount++;
    final failure = listRoomsFailure;
    if (failure != null) return Left(failure);
    final start = skip.clamp(0, allRooms.length);
    final end = (skip + limit).clamp(0, allRooms.length);
    return Right(
      ChatRoomsPage(
        rooms: allRooms.sublist(start, end),
        skip: skip,
        limit: limit,
        total: allRooms.length,
      ),
    );
  }

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
}

void main() {
  late _FakeGroupChatRepository repository;
  late _MemoryStorage storage;
  late GroupChatRoomCache cache;
  late ResolveGroupChatRoom resolve;

  setUp(() {
    repository = _FakeGroupChatRepository();
    storage = _MemoryStorage();
    cache = GroupChatRoomCache(storage: storage);
    resolve = ResolveGroupChatRoom(repository: repository, cache: cache);
  });

  group('ResolveGroupChatRoom', () {
    test('uses the cached room without listing rooms', () async {
      repository.rooms['r1'] = _room('r1', groupId: 'g1');
      await cache.write(userId: 'u1', groupId: 'g1', roomId: 'r1');

      final actual = await resolve(userId: 'u1', groupId: 'g1');

      expect(actual, isA<GroupChatRoomFound>());
      expect((actual as GroupChatRoomFound).roomId, 'r1');
      expect(repository.listRoomsCallCount, 0);
    });

    test('drops a cached room the server no longer has', () async {
      await cache.write(userId: 'u1', groupId: 'g1', roomId: 'stale');
      repository.allRooms = [_room('r2', groupId: 'g1')];

      final actual = await resolve(userId: 'u1', groupId: 'g1');

      expect((actual as GroupChatRoomFound).roomId, 'r2');
      expect(await cache.read(userId: 'u1', groupId: 'g1'), 'r2');
    });

    test('keeps the cached room when the lookup fails transiently', () async {
      await cache.write(userId: 'u1', groupId: 'g1', roomId: 'r1');
      repository.getRoomFailure = const NetworkFailure('offline');

      final actual = await resolve(userId: 'u1', groupId: 'g1');

      expect(actual, isA<GroupChatRoomUnavailable>());
      expect(await cache.read(userId: 'u1', groupId: 'g1'), 'r1');
      expect(repository.listRoomsCallCount, 0);
    });

    test('finds and caches the room on a cold cache', () async {
      repository.allRooms = [
        _room('other', groupId: 'g2'),
        _room('r1', groupId: 'g1'),
      ];

      final actual = await resolve(userId: 'u1', groupId: 'g1');

      expect((actual as GroupChatRoomFound).roomId, 'r1');
      expect(await cache.read(userId: 'u1', groupId: 'g1'), 'r1');
    });

    test('pages until the group room is found', () async {
      repository.allRooms = [
        for (var i = 0; i < 60; i++) _room('filler$i', groupId: 'other$i'),
        _room('target', groupId: 'g1'),
      ];

      final actual = await resolve(userId: 'u1', groupId: 'g1');

      expect((actual as GroupChatRoomFound).roomId, 'target');
      expect(repository.listRoomsCallCount, 2);
    });

    test('reports missing when the group has no room', () async {
      repository.allRooms = [_room('other', groupId: 'g2')];

      final actual = await resolve(userId: 'u1', groupId: 'g1');

      expect(actual, isA<GroupChatRoomMissing>());
      expect(await cache.read(userId: 'u1', groupId: 'g1'), isNull);
    });

    test('reports unavailable when listing rooms fails', () async {
      repository.listRoomsFailure = const NetworkFailure('offline');

      final actual = await resolve(userId: 'u1', groupId: 'g1');

      expect(actual, isA<GroupChatRoomUnavailable>());
    });
  });
}
