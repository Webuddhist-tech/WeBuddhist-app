import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/direct_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

ChatMessageDTO _message(String id, String createdAt, {String body = 'hi'}) {
  return ChatMessageDTO(
    id: id,
    roomId: 'dm-1',
    senderId: 'team',
    senderEmail: 'team@example.com',
    body: body,
    createdAt: createdAt,
  );
}

const _room = ChatRoomDTO(
  id: 'dm-1',
  createdBy: 'team',
  kind: 'PRIVATE',
  name: 'WeBuddhist Team',
  updatedAt: '2026-10-16T10:00:00Z',
  otherUserId: 'team',
  isOfficial: true,
);

/// A thread of [total] messages, newest first, one minute apart.
List<ChatMessageDTO> _thread(int total) => [
  for (var i = total; i > 0; i--)
    _message('m$i', DateTime.utc(2026, 10, 16, 10, i).toIso8601String()),
];

class _FakeRepository implements GroupChatRepository {
  _FakeRepository({this.room = _room, List<ChatMessageDTO>? messages})
    : messages = messages ?? _thread(3);

  ChatRoomDTO room;
  List<ChatMessageDTO> messages;
  final sentTo = <String>[];
  final pages = <int>[];
  var readCount = 0;

  @override
  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId) async =>
      Right(room);

  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
    String? messageType,
    String? sort,
    String? intention,
    String? translationLanguage,
  }) async {
    pages.add(skip);
    return Right(
      ChatMessagesPage(
        messages: messages.skip(skip).take(limit).toList(),
        skip: skip,
        limit: limit,
        total: messages.length,
      ),
    );
  }

  @override
  Future<Either<Failure, ChatMessageDTO>> sendDirectMessage(
    String userId, {
    required String body,
  }) async {
    sentTo.add(userId);
    final sent = _message('sent', '2026-10-16T11:00:00Z', body: body);
    messages = [sent, ...messages];
    return Right(sent);
  }

  @override
  Future<Either<Failure, Unit>> markRoomRead(String roomId) async {
    readCount++;
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Holds the autoDispose provider open, then waits for its first load.
Future<DirectChatNotifier> _notifier(
  ProviderContainer container, {
  String roomId = 'dm-1',
}) async {
  container.listen(directChatProvider(roomId), (_, _) {});
  final notifier = container.read(directChatProvider(roomId).notifier);
  await pumpEventQueue();
  return notifier;
}

ProviderContainer _container(_FakeRepository repository) {
  final container = ProviderContainer(
    overrides: [groupChatRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('mergeDirectMessages', () {
    test('one row per message, newest first', () {
      final merged = mergeDirectMessages(
        [_message('a', '2026-10-16T10:00:00Z')],
        [
          _message('c', '2026-10-16T12:00:00Z'),
          _message('a', '2026-10-16T10:00:00Z'),
          _message('b', '2026-10-16T11:00:00Z'),
        ],
      );

      expect(merged.map((m) => m.id), ['c', 'b', 'a']);
    });

    test('the incoming copy wins, so edits and deletes show', () {
      final merged = mergeDirectMessages(
        [_message('a', '2026-10-16T10:00:00Z', body: 'old')],
        [_message('a', '2026-10-16T10:00:00Z', body: 'edited')],
      );

      expect(merged.single.body, 'edited');
    });

    test('same-instant messages keep a stable order', () {
      final first = mergeDirectMessages(
        [_message('a', '2026-10-16T10:00:00Z')],
        [_message('b', '2026-10-16T10:00:00Z')],
      );
      final second = mergeDirectMessages(
        [_message('b', '2026-10-16T10:00:00Z')],
        [_message('a', '2026-10-16T10:00:00Z')],
      );

      expect(first.map((m) => m.id), second.map((m) => m.id));
    });
  });

  group('DirectChatNotifier', () {
    test('loads the room and the newest page, then marks it read', () async {
      final repository = _FakeRepository();
      final container = _container(repository);
      await _notifier(container);

      final state = container.read(directChatProvider('dm-1'));
      expect(state.room, _room);
      expect(state.messages.map((m) => m.id), ['m3', 'm2', 'm1']);
      expect(state.hasLoaded, isTrue);
      expect(state.hasMore, isFalse);
      expect(repository.readCount, 1);
    });

    test('pages on from what it holds', () async {
      final repository = _FakeRepository(messages: _thread(45));
      final container = _container(repository);
      final notifier = await _notifier(container);

      expect(container.read(directChatProvider('dm-1')).messages, hasLength(30));
      await notifier.loadMore();

      final state = container.read(directChatProvider('dm-1'));
      expect(repository.pages, [0, 30]);
      expect(state.messages, hasLength(45));
      expect(state.hasMore, isFalse);
    });

    test('a reply goes to the other person and shows at once', () async {
      final repository = _FakeRepository();
      final container = _container(repository);
      final notifier = await _notifier(container);

      final result = await notifier.send('Thank you!');

      expect(result.isRight(), isTrue);
      expect(repository.sentTo, ['team']);
      final state = container.read(directChatProvider('dm-1'));
      expect(state.messages.first.body, 'Thank you!');
      expect(state.skip, 4);
    });

    test('nothing is sent while the room does not say who it is with', () async {
      final repository = _FakeRepository(
        room: const ChatRoomDTO(
          id: 'dm-1',
          createdBy: 'x',
          kind: 'PRIVATE',
          name: '',
          updatedAt: '',
        ),
      );
      final container = _container(repository);
      final notifier = await _notifier(container);

      final result = await notifier.send('Hello?');

      expect(result.isLeft(), isTrue);
      expect(repository.sentTo, isEmpty);
    });

    test('a seeded room shows until the fetched one replaces it', () async {
      final repository = _FakeRepository();
      final container = _container(repository);
      container.listen(directChatProvider('dm-1'), (_, _) {});
      final notifier = container.read(directChatProvider('dm-1').notifier);

      const seeded = ChatRoomDTO(
        id: 'dm-1',
        createdBy: 'team',
        kind: 'PRIVATE',
        name: 'From the list',
        updatedAt: '',
        otherUserId: 'team',
      );
      notifier.seedRoom(seeded);
      expect(container.read(directChatProvider('dm-1')).room, seeded);

      await pumpEventQueue();
      expect(container.read(directChatProvider('dm-1')).room, _room);
    });
  });
}
